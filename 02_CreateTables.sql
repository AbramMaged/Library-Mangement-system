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
