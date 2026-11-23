-- ============================================================
-- FILE: 04_ValidationProcedures.sql
-- PURPOSE: Create the BorrowBook and ReturnBook procedures.
-- RUN ORDER: Step 4 of 4 — run after 03_InsertSampleData.sql.
-- DATABASE ENGINE: Azure SQL Database / SQL Server
-- ============================================================
-- Connect directly to LibraryManagementDB before running.
-- Column names below match 02_CreateTables.sql, including BorrowDate.
-- This file only creates/updates procedure definitions. It does not execute
-- them, insert test loans, or change AvailableCopies.
-- ============================================================

SET NOCOUNT ON;
GO

CREATE OR ALTER PROCEDURE dbo.BorrowBook
    @BookID INT,
    @MemberID INT,
    @LibrarianID INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @LoanID INT;
    DECLARE @Today DATE = CONVERT(DATE, GETUTCDATE());

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Decrement only if a copy is available; the update lock avoids
        -- two concurrent requests borrowing the same final copy.
        UPDATE dbo.Books WITH (UPDLOCK, ROWLOCK)
        SET AvailableCopies = AvailableCopies - 1
        WHERE BookID = @BookID
          AND AvailableCopies > 0;

        IF @@ROWCOUNT = 0
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM dbo.Books WHERE BookID = @BookID)
                THROW 50001, 'Book does not exist.', 1;

            THROW 50002, 'No copies of this book are available.', 1;
        END;

        INSERT INTO dbo.Loans
            (BookID, MemberID, LibrarianID, BorrowDate, DueDate, ReturnDate)
        VALUES
            (@BookID, @MemberID, @LibrarianID, @Today, DATEADD(DAY, 14, @Today), NULL);

        SET @LoanID = CONVERT(INT, SCOPE_IDENTITY());

        COMMIT TRANSACTION;
        SELECT @LoanID AS LoanID;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.ReturnBook
    @LoanID INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @BookID INT;
    DECLARE @Today DATE = CONVERT(DATE, GETUTCDATE());

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Only an active loan can be returned, preventing a double return.
        SELECT @BookID = BookID
        FROM dbo.Loans WITH (UPDLOCK, ROWLOCK)
        WHERE LoanID = @LoanID
          AND ReturnDate IS NULL;

        IF @BookID IS NULL
            THROW 50002, 'Loan does not exist or has already been returned.', 1;

        UPDATE dbo.Loans
        SET ReturnDate = @Today
        WHERE LoanID = @LoanID
          AND ReturnDate IS NULL;

        IF @@ROWCOUNT = 0
            THROW 50002, 'Loan does not exist or has already been returned.', 1;

        UPDATE dbo.Books
        SET AvailableCopies = AvailableCopies + 1
        WHERE BookID = @BookID
          AND AvailableCopies < Quantity;

        IF @@ROWCOUNT = 0
            THROW 50003, 'Book stock is inconsistent; the return was not applied.', 1;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
