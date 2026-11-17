-- ============================================================
-- FILE: 02_CreateTables.sql
-- PURPOSE: Create all six tables for LibraryManagementDB
-- RUN ORDER: Step 2 of 4 — Run AFTER 01_CreateDatabase.sql
-- NOTE: This script is intended to be run ONCE on a fresh
--       database. Run 01_CreateDatabase.sql first.
-- ============================================================

USE LibraryManagementDB;
GO

-- ============================================================
-- TABLE 1: Authors
-- ============================================================
-- Stores information about book authors.
-- One author can write many books (1-to-Many with Books).

IF NOT EXISTS (
    SELECT * FROM sys.tables WHERE name = 'Authors'
)
BEGIN
    CREATE TABLE Authors (
        -- IDENTITY(1,1) means SQL Server auto-generates the ID
        -- starting at 1 and incrementing by 1 for each new row.
        AuthorID    INT             IDENTITY(1,1)   NOT NULL,
        AuthorName  NVARCHAR(100)                   NOT NULL,
        Biography   NVARCHAR(500)                   NULL,       -- Optional; can be left empty

        -- Define AuthorID as the Primary Key.
        -- A primary key uniquely identifies each row in the table.
        CONSTRAINT PK_Authors PRIMARY KEY (AuthorID)
    );
    PRINT 'Table "Authors" created.';
END
ELSE
    PRINT 'Table "Authors" already exists. Skipping.';
GO
-- ============================================================
-- TABLE 2: Categories
-- ============================================================
-- Stores book genre/category names (e.g., Fiction, Science).
-- One category can apply to many books (1-to-Many with Books).

IF NOT EXISTS (
    SELECT * FROM sys.tables WHERE name = 'Categories'
)
BEGIN
    CREATE TABLE Categories (
        CategoryID      INT             IDENTITY(1,1)   NOT NULL,
        CategoryName    NVARCHAR(100)                   NOT NULL,

        CONSTRAINT PK_Categories PRIMARY KEY (CategoryID),

        -- UNIQUE ensures no two categories share the same name.
        CONSTRAINT UQ_Categories_CategoryName UNIQUE (CategoryName)
    );
    PRINT 'Table "Categories" created.';
END
ELSE
    PRINT 'Table "Categories" already exists. Skipping.';
GO

-- ============================================================
-- TABLE 3: Books
-- ============================================================
-- Stores the library book catalog.
-- References Authors and Categories via foreign keys.
-- Tracks total quantity and currently available copies.

IF NOT EXISTS (
    SELECT * FROM sys.tables WHERE name = 'Books'
)
BEGIN
    CREATE TABLE Books (
        BookID          INT             IDENTITY(1,1)   NOT NULL,
        Title           NVARCHAR(200)                   NOT NULL,
        ISBN            NVARCHAR(20)                    NOT NULL,
        AuthorID        INT                             NOT NULL,   -- Links to Authors table
        CategoryID      INT                             NOT NULL,   -- Links to Categories table
        Quantity        INT                             NOT NULL,   -- Total copies owned by library
        AvailableCopies INT                             NOT NULL,   -- Copies currently on the shelf
        PublishYear     INT                             NULL,       -- Optional publication year

        -- Primary Key
        CONSTRAINT PK_Books PRIMARY KEY (BookID),

        -- Each book must have a unique ISBN.
        CONSTRAINT UQ_Books_ISBN UNIQUE (ISBN),

        -- Foreign Key: AuthorID must exist in the Authors table.
        -- ON DELETE NO ACTION means you cannot delete an author
        -- who still has books assigned to them.
        CONSTRAINT FK_Books_Authors
            FOREIGN KEY (AuthorID)
            REFERENCES Authors (AuthorID)
            ON DELETE NO ACTION
            ON UPDATE NO ACTION,

        -- Foreign Key: CategoryID must exist in the Categories table.
        CONSTRAINT FK_Books_Categories
            FOREIGN KEY (CategoryID)
            REFERENCES Categories (CategoryID)
            ON DELETE NO ACTION
            ON UPDATE NO ACTION,

        -- CHECK: Quantity cannot be a negative number.
        CONSTRAINT CK_Books_Quantity
            CHECK (Quantity >= 0),

        -- CHECK: AvailableCopies must be between 0 and Quantity.
        -- You cannot have more available copies than total copies.
        CONSTRAINT CK_Books_AvailableCopies
            CHECK (AvailableCopies >= 0 AND AvailableCopies <= Quantity),

        -- CHECK: Publication year must be a realistic value.
        -- 1450 is roughly when the printing press was invented.
        CONSTRAINT CK_Books_PublishYear
            CHECK (PublishYear IS NULL OR PublishYear >= 1450)
    );
    PRINT 'Table "Books" created.';
END
ELSE
    PRINT 'Table "Books" already exists. Skipping.';
GO

-- ============================================================
-- TABLE 4: Members
-- ============================================================
-- Stores library member (student/staff) information.
-- One member can have many loan records (1-to-Many with Loans).

IF NOT EXISTS (
    SELECT * FROM sys.tables WHERE name = 'Members'
)
BEGIN
    CREATE TABLE Members (
        MemberID            INT             IDENTITY(1,1)   NOT NULL,
        FullName            NVARCHAR(150)                   NOT NULL,
        Email               NVARCHAR(254)                   NOT NULL,
        Phone               NVARCHAR(30)                    NULL,       -- Optional phone number
        -- DEFAULT GETDATE() automatically sets today's date when
        -- a new member is registered without specifying a date.
        RegistrationDate    DATE            DEFAULT GETDATE() NOT NULL,

        CONSTRAINT PK_Members PRIMARY KEY (MemberID),

        -- Each member must have a unique email address.
        CONSTRAINT UQ_Members_Email UNIQUE (Email)
    );
    PRINT 'Table "Members" created.';
END
ELSE
    PRINT 'Table "Members" already exists. Skipping.';
GO

-- ============================================================
-- TABLE 5: Librarians
-- ============================================================
-- Stores librarian staff accounts (no passwords in Milestone 1).
-- One librarian can process many loans (1-to-Many with Loans).

IF NOT EXISTS (
    SELECT * FROM sys.tables WHERE name = 'Librarians'
)
BEGIN
    CREATE TABLE Librarians (
        LibrarianID INT             IDENTITY(1,1)   NOT NULL,
        FullName    NVARCHAR(150)                   NOT NULL,
        Email       NVARCHAR(254)                   NOT NULL,
        Username    NVARCHAR(50)                    NOT NULL,

        CONSTRAINT PK_Librarians PRIMARY KEY (LibrarianID),

        -- Each librarian must have a unique email and username.
        CONSTRAINT UQ_Librarians_Email    UNIQUE (Email),
        CONSTRAINT UQ_Librarians_Username UNIQUE (Username)
    );
    PRINT 'Table "Librarians" created.';
END
ELSE
    PRINT 'Table "Librarians" already exists. Skipping.';
GO

-- ============================================================
-- TABLE 6: Loans
-- ============================================================
-- Records every borrowing transaction.
-- Links Books, Members, and Librarians.
-- NULL ReturnDate = book has not been returned yet (active loan).

IF NOT EXISTS (
    SELECT * FROM sys.tables WHERE name = 'Loans'
)
BEGIN
    CREATE TABLE Loans (
        LoanID          INT     IDENTITY(1,1)   NOT NULL,
        BookID          INT                     NOT NULL,   -- Which book was borrowed
        MemberID        INT                     NOT NULL,   -- Who borrowed it
        LibrarianID     INT                     NOT NULL,   -- Who processed the loan
        BorrowDate      DATE    DEFAULT GETDATE() NOT NULL, -- Date the book was taken out
        DueDate         DATE                    NOT NULL,   -- Date the book must be returned
        ReturnDate      DATE                    NULL,       -- NULL = not yet returned

        CONSTRAINT PK_Loans PRIMARY KEY (LoanID),

        -- Foreign Key: BookID must exist in Books table.
        CONSTRAINT FK_Loans_Books
            FOREIGN KEY (BookID)
            REFERENCES Books (BookID)
            ON DELETE NO ACTION
            ON UPDATE NO ACTION,

        -- Foreign Key: MemberID must exist in Members table.
        CONSTRAINT FK_Loans_Members
            FOREIGN KEY (MemberID)
            REFERENCES Members (MemberID)
            ON DELETE NO ACTION
            ON UPDATE NO ACTION,

        -- Foreign Key: LibrarianID must exist in Librarians table.
        CONSTRAINT FK_Loans_Librarians
            FOREIGN KEY (LibrarianID)
            REFERENCES Librarians (LibrarianID)
            ON DELETE NO ACTION
            ON UPDATE NO ACTION,

        -- CHECK: DueDate must be on or after BorrowDate.
        -- A book cannot be due before it was borrowed.
        CONSTRAINT CK_Loans_DueDate
            CHECK (DueDate >= BorrowDate),

        -- CHECK: ReturnDate must be NULL (not returned) or
        -- on/after BorrowDate (returned on or after borrowing day).
        CONSTRAINT CK_Loans_ReturnDate
            CHECK (ReturnDate IS NULL OR ReturnDate >= BorrowDate)
    );
    PRINT 'Table "Loans" created.';
END
ELSE
    PRINT 'Table "Loans" already exists. Skipping.';
GO

-- ============================================================
-- SUMMARY
-- ============================================================
-- Confirm all six tables exist in the database.
SELECT
    t.name          AS TableName,
    s.name          AS SchemaName
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
ORDER BY t.name;
GO

PRINT '--- All tables verified. Run 03_InsertSampleData.sql next. ---';
GO

