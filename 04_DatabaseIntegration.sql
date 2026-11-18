-- ============================================================
-- FILE: 04_DatabaseIntegration.sql
-- PURPOSE: Integrate the library tables for day-to-day database use
-- RUN ORDER: Step 4 of 4 — Run AFTER 03_InsertSampleData.sql
-- DATABASE: LibraryManagementDB (Microsoft SQL Server)
-- Requires SQL Server 2016 SP1+ for CREATE OR ALTER.
-- ============================================================

USE LibraryManagementDB;
GO

SET NOCOUNT ON;
GO

-- ============================================================
-- SECTION 1: VIEWS
-- ============================================================
-- Views are saved SELECT queries. Instead of writing the same
-- complex JOIN every time, you query the view like a table.
-- CREATE OR ALTER means: create it if new, update it if it
-- already exists — no need to drop it first.
-- ============================================================

-- 1) Unified book catalogue: Books + Authors + Categories
--    Returns one row per book with all human-readable details.
--    CopiesOnLoan is calculated on the fly (Quantity - AvailableCopies).

CREATE OR ALTER VIEW dbo.vw_BookCatalog
AS
SELECT
    b.BookID,
    b.Title,
    b.ISBN,
    a.AuthorID,
    a.AuthorName,
    c.CategoryID,
    c.CategoryName,
    b.PublishYear,
    b.Quantity,
    b.AvailableCopies,
    b.Quantity - b.AvailableCopies AS CopiesOnLoan
FROM dbo.Books       AS b
INNER JOIN dbo.Authors     AS a ON a.AuthorID    = b.AuthorID
INNER JOIN dbo.Categories  AS c ON c.CategoryID  = b.CategoryID;
GO

-- 2) Loan details: Loans + Books + Members + Librarians
--    Adds a computed LoanStatus column so the Python app does
--    not need to calculate it — just read the value from the view.
--    DaysOverdue is 0 for active/returned loans; positive for overdue.

CREATE OR ALTER VIEW dbo.vw_LoanDetails
AS
SELECT
    l.LoanID,
    l.BookID,
    b.Title,
    l.MemberID,
    m.FullName      AS MemberName,
    m.Email         AS MemberEmail,
    l.LibrarianID,
    lib.FullName    AS LibrarianName,
    l.BorrowDate,
    l.DueDate,
    l.ReturnDate,
    -- LoanStatus: Returned / Overdue / Active
    CASE
        WHEN l.ReturnDate IS NOT NULL                           THEN N'Returned'
        WHEN l.DueDate < CONVERT(date, GETDATE())              THEN N'Overdue'
        ELSE N'Active'
    END AS LoanStatus,
    -- DaysOverdue is only meaningful when the loan is overdue
    CASE
        WHEN l.ReturnDate IS NULL AND l.DueDate < CONVERT(date, GETDATE())
            THEN DATEDIFF(day, l.DueDate, CONVERT(date, GETDATE()))
        ELSE 0
    END AS DaysOverdue
FROM dbo.Loans       AS l
INNER JOIN dbo.Books       AS b   ON b.BookID      = l.BookID
INNER JOIN dbo.Members     AS m   ON m.MemberID    = l.MemberID
INNER JOIN dbo.Librarians  AS lib ON lib.LibrarianID = l.LibrarianID;
GO

-- 3) Summary view for a quick dashboard snapshot.
--    Returns a single row with counts of all loan states.
--    COUNT_BIG is used instead of COUNT for large table safety.

CREATE OR ALTER VIEW dbo.vw_LoanSummary
AS
SELECT
    COUNT_BIG(*)                                                                                AS TotalLoans,
    SUM(CASE WHEN ReturnDate IS NOT NULL                                       THEN 1 ELSE 0 END) AS ReturnedLoans,
    SUM(CASE WHEN ReturnDate IS NULL AND DueDate >= CONVERT(date, GETDATE())   THEN 1 ELSE 0 END) AS ActiveLoans,
    SUM(CASE WHEN ReturnDate IS NULL AND DueDate <  CONVERT(date, GETDATE())   THEN 1 ELSE 0 END) AS OverdueLoans
FROM dbo.Loans;
GO

-- ============================================================
-- SECTION 2: STORED PROCEDURES
-- ============================================================
-- Stored procedures are named blocks of SQL that can be called
-- with parameters. Using them for borrow/return keeps the
-- transaction logic in the database — the Python app just calls
-- EXEC usp_BorrowBook ... and the database handles the rest.
-- ============================================================

-- 4) Borrow a book safely.
--    The available-copy decrement and loan INSERT happen in one
--    transaction, preventing two users from taking the last copy
--    at the same time (UPDLOCK, ROWLOCK).

CREATE OR ALTER PROCEDURE dbo.usp_BorrowBook
    @BookID      INT,
    @MemberID    INT,
    @LibrarianID INT,
    @DueDate     DATE,
    @BorrowDate  DATE = NULL    -- defaults to today if not supplied
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;   -- auto-rollback on any error

    -- Default BorrowDate to today
    SET @BorrowDate = COALESCE(@BorrowDate, CONVERT(date, GETDATE()));

    -- Validate: due date cannot be before borrow date
    IF @DueDate < @BorrowDate
        THROW 50010, 'DueDate cannot be earlier than BorrowDate.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Decrement AvailableCopies only if at least one copy is free.
        -- UPDLOCK + ROWLOCK prevent a race condition where two transactions
        -- both see AvailableCopies = 1 and both succeed.
        UPDATE dbo.Books WITH (UPDLOCK, ROWLOCK)
        SET    AvailableCopies = AvailableCopies - 1
        WHERE  BookID = @BookID
          AND  AvailableCopies > 0;

        -- @@ROWCOUNT = 0 means either the book does not exist or it is
        -- fully on loan — either way, refuse the borrow.
        IF @@ROWCOUNT = 0
            THROW 50011, 'Book does not exist or no copies are currently available.', 1;

        -- Insert the loan record
        INSERT INTO dbo.Loans (BookID, MemberID, LibrarianID, BorrowDate, DueDate, ReturnDate)
        VALUES (@BookID, @MemberID, @LibrarianID, @BorrowDate, @DueDate, NULL);

        -- Capture the auto-generated LoanID before committing
        DECLARE @NewLoanID INT = CONVERT(INT, SCOPE_IDENTITY());

        COMMIT TRANSACTION;

        -- Return the new loan row so the Python app can confirm it
        SELECT LoanID, BookID, MemberID, LibrarianID, BorrowDate, DueDate, ReturnDate
        FROM   dbo.Loans
        WHERE  LoanID = @NewLoanID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;   -- re-raise the original error to the caller
    END CATCH;
END;
GO

-- 5) Return a book safely.
--    A loan can only be returned once (checked before the update).
--    AvailableCopies is incremented in the same transaction.

CREATE OR ALTER PROCEDURE dbo.usp_ReturnBook
    @LoanID     INT,
    @ReturnDate DATE = NULL    -- defaults to today if not supplied
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @ReturnDate = COALESCE(@ReturnDate, CONVERT(date, GETDATE()));

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Read the loan row and lock it immediately (UPDLOCK)
        -- to prevent another session from modifying it at the same time.
        DECLARE @BookID             INT;
        DECLARE @BorrowDate         DATE;
        DECLARE @ExistingReturnDate DATE;

        SELECT
            @BookID             = BookID,
            @BorrowDate         = BorrowDate,
            @ExistingReturnDate = ReturnDate
        FROM dbo.Loans WITH (UPDLOCK, ROWLOCK)
        WHERE LoanID = @LoanID;

        -- Validate: loan must exist
        IF @BookID IS NULL
            THROW 50012, 'Loan record was not found.', 1;

        -- Validate: cannot return a loan that is already returned
        IF @ExistingReturnDate IS NOT NULL
            THROW 50013, 'This loan has already been returned.', 1;

        -- Validate: return date cannot be before borrow date
        IF @ReturnDate < @BorrowDate
            THROW 50014, 'ReturnDate cannot be earlier than BorrowDate.', 1;

        -- Mark the loan as returned
        UPDATE dbo.Loans
        SET    ReturnDate = @ReturnDate
        WHERE  LoanID = @LoanID;

        -- Put the copy back — but never exceed the total Quantity
        UPDATE dbo.Books
        SET    AvailableCopies = AvailableCopies + 1
        WHERE  BookID = @BookID
          AND  AvailableCopies < Quantity;

        IF @@ROWCOUNT = 0
            THROW 50015, 'Could not update book inventory; check the available-copy count.', 1;

        COMMIT TRANSACTION;

        -- Return the updated loan row for confirmation
        SELECT LoanID, BookID, ReturnDate
        FROM   dbo.Loans
        WHERE  LoanID = @LoanID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- ============================================================
-- SECTION 3: INDEXES
-- ============================================================
-- Indexes speed up queries that filter or join on these columns.
-- Without them, SQL Server scans every row in the table.
-- Each IF NOT EXISTS check prevents an error if already created.
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Books_AuthorID'           AND object_id = OBJECT_ID('dbo.Books'))
    CREATE INDEX IX_Books_AuthorID           ON dbo.Books(AuthorID);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Books_CategoryID'         AND object_id = OBJECT_ID('dbo.Books'))
    CREATE INDEX IX_Books_CategoryID         ON dbo.Books(CategoryID);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Loans_BookID'             AND object_id = OBJECT_ID('dbo.Loans'))
    CREATE INDEX IX_Loans_BookID             ON dbo.Loans(BookID);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Loans_MemberID'           AND object_id = OBJECT_ID('dbo.Loans'))
    CREATE INDEX IX_Loans_MemberID           ON dbo.Loans(MemberID);

-- Composite index: speeds up queries that filter on both DueDate and ReturnDate
-- (e.g., finding active/overdue loans)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Loans_DueDate_ReturnDate' AND object_id = OBJECT_ID('dbo.Loans'))
    CREATE INDEX IX_Loans_DueDate_ReturnDate ON dbo.Loans(DueDate, ReturnDate);
GO

-- ============================================================
-- SECTION 4: INTEGRATION CHECKS
-- ============================================================
-- These queries should each return 0 in the ProblemCount column.
-- A non-zero value means foreign key data is inconsistent.
-- ============================================================

SELECT N'Books with missing authors/categories' AS CheckName, COUNT(*) AS ProblemCount
FROM   dbo.Books       AS b
LEFT   JOIN dbo.Authors     AS a ON a.AuthorID   = b.AuthorID
LEFT   JOIN dbo.Categories  AS c ON c.CategoryID = b.CategoryID
WHERE  a.AuthorID IS NULL OR c.CategoryID IS NULL

UNION ALL

SELECT N'Loans with missing related records', COUNT(*)
FROM   dbo.Loans       AS l
LEFT   JOIN dbo.Books       AS b   ON b.BookID      = l.BookID
LEFT   JOIN dbo.Members     AS m   ON m.MemberID    = l.MemberID
LEFT   JOIN dbo.Librarians  AS lib ON lib.LibrarianID = l.LibrarianID
WHERE  b.BookID IS NULL OR m.MemberID IS NULL OR lib.LibrarianID IS NULL;
GO

-- ============================================================
-- SECTION 5: SAMPLE INTEGRATED REPORTS
-- ============================================================

-- Full book catalogue (title, author, category, availability)
SELECT * FROM dbo.vw_BookCatalog    ORDER BY Title;

-- Single-row dashboard summary (total / returned / active / overdue)
SELECT * FROM dbo.vw_LoanSummary;

-- Full loan history with computed status
SELECT * FROM dbo.vw_LoanDetails    ORDER BY BorrowDate DESC, LoanID DESC;
GO

PRINT 'Database integration complete: views, stored procedures, indexes, and integrity checks are ready.';
GO
