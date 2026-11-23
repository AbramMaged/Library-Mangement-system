-- ============================================================
-- FILE: 02_CreateTables.sql
-- PURPOSE: Create all six tables for the Library Management DB
-- RUN ORDER: Step 2 of 4 — Run AFTER creating the database
-- DATABASE ENGINE: Azure SQL Database
-- ============================================================
--
-- Connect directly to LibraryManagementDB before running.
-- Azure SQL Database does not require or support USE <db>;
-- at the top of scripts when you connect directly to the DB.
--
-- This script uses IF NOT EXISTS guards so it is safe to run
-- more than once — existing tables will be skipped.
-- ============================================================

SET NOCOUNT ON;
GO

-- ============================================================
-- TABLE 1: Authors
-- ============================================================
-- Stores information about book authors.
-- One author can write many books (1-to-Many with Books).

IF NOT EXISTS (
    SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.Authors') AND type = 'U'
)
BEGIN
    CREATE TABLE dbo.Authors (
        -- IDENTITY(1,1): SQL generates the ID automatically,
        -- starting at 1 and increasing by 1 for every new row.
        AuthorID    INT             NOT NULL IDENTITY(1,1),
        AuthorName  NVARCHAR(100)   NOT NULL,
        Biography   NVARCHAR(500)       NULL,

        CONSTRAINT PK_Authors PRIMARY KEY (AuthorID)
    );
    PRINT 'Table dbo.Authors created.';
END
ELSE
    PRINT 'Table dbo.Authors already exists — skipped.';
GO

-- ============================================================
-- TABLE 2: Categories
-- ============================================================
-- Stores book genre names (e.g., Fiction, Science).
-- One category applies to many books (1-to-Many with Books).

IF NOT EXISTS (
    SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.Categories') AND type = 'U'
)
BEGIN
    CREATE TABLE dbo.Categories (
        CategoryID      INT             NOT NULL IDENTITY(1,1),
        CategoryName    NVARCHAR(100)   NOT NULL,

        CONSTRAINT PK_Categories             PRIMARY KEY (CategoryID),
        -- UNIQUE: no two categories may share the same name.
        CONSTRAINT UQ_Categories_CategoryName UNIQUE      (CategoryName)
    );
    PRINT 'Table dbo.Categories created.';
END
ELSE
    PRINT 'Table dbo.Categories already exists — skipped.';
GO

-- ============================================================
-- TABLE 3: Books
-- ============================================================
-- The central catalog of all library books.
-- References Authors and Categories via foreign keys.
-- Tracks total stock (Quantity) and shelf stock (AvailableCopies).

IF NOT EXISTS (
    SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.Books') AND type = 'U'
)
BEGIN
    CREATE TABLE dbo.Books (
        BookID          INT             NOT NULL IDENTITY(1,1),
        Title           NVARCHAR(200)   NOT NULL,
        ISBN            NVARCHAR(20)    NOT NULL,
        AuthorID        INT             NOT NULL,
        CategoryID      INT             NOT NULL,
        Quantity        INT             NOT NULL,
        AvailableCopies INT             NOT NULL,
        PublishYear     INT                 NULL,

        CONSTRAINT PK_Books             PRIMARY KEY (BookID),
        CONSTRAINT UQ_Books_ISBN        UNIQUE      (ISBN),

        -- Foreign keys — ON DELETE NO ACTION means you cannot delete
        -- an Author or Category that still has books assigned to it.
        CONSTRAINT FK_Books_Authors
            FOREIGN KEY (AuthorID)   REFERENCES dbo.Authors    (AuthorID)
            ON DELETE NO ACTION ON UPDATE NO ACTION,

        CONSTRAINT FK_Books_Categories
            FOREIGN KEY (CategoryID) REFERENCES dbo.Categories (CategoryID)
            ON DELETE NO ACTION ON UPDATE NO ACTION,

        -- CHECK constraints — SQL Server / Azure SQL enforce these on every INSERT and UPDATE.
        CONSTRAINT CK_Books_Quantity
            CHECK (Quantity >= 0),

        -- AvailableCopies must stay between 0 and Quantity.
        CONSTRAINT CK_Books_AvailableCopies
            CHECK (AvailableCopies >= 0 AND AvailableCopies <= Quantity),

        -- 1450 is roughly when the printing press was invented.
        CONSTRAINT CK_Books_PublishYear
            CHECK (PublishYear IS NULL OR PublishYear >= 1450)
    );
    PRINT 'Table dbo.Books created.';
END
ELSE
    PRINT 'Table dbo.Books already exists — skipped.';
GO

-- ============================================================
-- TABLE 4: Members
-- ============================================================
-- Stores library member (student / staff) profiles.
-- One member can have many loans (1-to-Many with Loans).

IF NOT EXISTS (
    SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.Members') AND type = 'U'
)
BEGIN
    CREATE TABLE dbo.Members (
        MemberID            INT             NOT NULL IDENTITY(1,1),
        FullName            NVARCHAR(150)   NOT NULL,
        Email               NVARCHAR(254)   NOT NULL,
        Phone               NVARCHAR(30)        NULL,
        -- GETUTCDATE() is preferred on Azure SQL because the service
        -- runs in UTC. GETDATE() also works but reflects the server
        -- time zone, which may vary across Azure regions.
        RegistrationDate    DATE            NOT NULL DEFAULT CONVERT(date, GETUTCDATE()),

        CONSTRAINT PK_Members       PRIMARY KEY (MemberID),
        CONSTRAINT UQ_Members_Email UNIQUE      (Email)
    );
    PRINT 'Table dbo.Members created.';
END
ELSE
    PRINT 'Table dbo.Members already exists — skipped.';
GO

-- ============================================================
-- TABLE 5: Librarians
-- ============================================================
-- Stores staff accounts. No passwords are stored in Milestone 1.
-- One librarian can process many loans (1-to-Many with Loans).

IF NOT EXISTS (
    SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.Librarians') AND type = 'U'
)
BEGIN
    CREATE TABLE dbo.Librarians (
        LibrarianID INT             NOT NULL IDENTITY(1,1),
        FullName    NVARCHAR(150)   NOT NULL,
        Email       NVARCHAR(254)   NOT NULL,
        Username    NVARCHAR(50)    NOT NULL,

        CONSTRAINT PK_Librarians            PRIMARY KEY (LibrarianID),
        CONSTRAINT UQ_Librarians_Email      UNIQUE      (Email),
        CONSTRAINT UQ_Librarians_Username   UNIQUE      (Username)
    );
    PRINT 'Table dbo.Librarians created.';
END
ELSE
    PRINT 'Table dbo.Librarians already exists — skipped.';
GO

-- ============================================================
-- TABLE 6: Loans
-- ============================================================
-- Records every borrowing transaction.
-- NULL ReturnDate = book is still out (active loan).
-- Links Books, Members, and Librarians.

IF NOT EXISTS (
    SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.Loans') AND type = 'U'
)
BEGIN
    CREATE TABLE dbo.Loans (
        LoanID          INT     NOT NULL IDENTITY(1,1),
        BookID          INT     NOT NULL,
        MemberID        INT     NOT NULL,
        LibrarianID     INT     NOT NULL,
        BorrowDate      DATE    NOT NULL DEFAULT CONVERT(date, GETUTCDATE()),
        DueDate         DATE    NOT NULL,
        ReturnDate      DATE        NULL,

        CONSTRAINT PK_Loans PRIMARY KEY (LoanID),

        CONSTRAINT FK_Loans_Books
            FOREIGN KEY (BookID)      REFERENCES dbo.Books      (BookID)
            ON DELETE NO ACTION ON UPDATE NO ACTION,

        CONSTRAINT FK_Loans_Members
            FOREIGN KEY (MemberID)    REFERENCES dbo.Members    (MemberID)
            ON DELETE NO ACTION ON UPDATE NO ACTION,

        CONSTRAINT FK_Loans_Librarians
            FOREIGN KEY (LibrarianID) REFERENCES dbo.Librarians (LibrarianID)
            ON DELETE NO ACTION ON UPDATE NO ACTION,

        -- DueDate must be on or after the day the book was taken out.
        CONSTRAINT CK_Loans_DueDate
            CHECK (DueDate >= BorrowDate),

        -- ReturnDate must be NULL (not returned) or on/after BorrowDate.
        CONSTRAINT CK_Loans_ReturnDate
            CHECK (ReturnDate IS NULL OR ReturnDate >= BorrowDate)
    );
    PRINT 'Table dbo.Loans created.';
END
ELSE
    PRINT 'Table dbo.Loans already exists — skipped.';
GO

-- ============================================================
-- VERIFICATION — confirm all six tables exist
-- ============================================================
SELECT
    t.name          AS TableName,
    s.name          AS SchemaName,
    t.create_date   AS CreatedAt
FROM sys.tables  AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
WHERE s.name = 'dbo'
ORDER BY t.name;
GO

PRINT 'All tables verified. Run 03_InsertSampleData.sql next.';
GO
