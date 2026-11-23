-- ============================================================
-- FILE: 03_InsertSampleData.sql
-- PURPOSE: Insert the clean base sample data for the library.
-- RUN ORDER: Step 3 of 4 — run after 02_CreateTables.sql.
-- DATABASE ENGINE: Azure SQL Database / SQL Server
-- ============================================================
-- Connect directly to LibraryManagementDB before running.
-- This script matches the column names in 02_CreateTables.sql.
-- It is intended for a newly created, empty database and should not be
-- rerun after the rows have been inserted.
--
-- Deliberately excluded: Loans rows created during BorrowBook/ReturnBook
-- experiments. This leaves the loan history clean for whoever starts next.
-- ============================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRY
    BEGIN TRANSACTION;

    SET IDENTITY_INSERT dbo.Authors ON;
    INSERT INTO dbo.Authors (AuthorID, AuthorName, Biography)
    VALUES
        (1, N'Naguib Mahfouz', N'Egyptian novelist and Nobel Prize laureate.'),
        (2, N'Taha Hussein', N'Egyptian writer and one of the leading figures of the Arab literary movement.'),
        (3, N'Agatha Christie', N'British author known for detective novels.'),
        (4, N'George Orwell', N'English novelist and essayist.'),
        (5, N'Jane Austen', N'English novelist known for social commentary.'),
        (6, N'William Shakespeare', N'English playwright and poet.'),
        (7, N'J. K. Rowling', N'British author of the Harry Potter series.'),
        (8, N'Ahmed Khaled Tawfik', N'Egyptian author known for Arabic science fiction and horror.');
    SET IDENTITY_INSERT dbo.Authors OFF;

    SET IDENTITY_INSERT dbo.Categories ON;
    INSERT INTO dbo.Categories (CategoryID, CategoryName)
    VALUES
        (1, N'Arabic Literature'),
        (2, N'History'),
        (3, N'Mystery'),
        (4, N'Science Fiction'),
        (5, N'Classic Literature'),
        (6, N'Drama'),
        (7, N'Fantasy'),
        (8, N'Science');
    SET IDENTITY_INSERT dbo.Categories OFF;

    SET IDENTITY_INSERT dbo.Books ON;
    INSERT INTO dbo.Books
        (BookID, Title, ISBN, AuthorID, CategoryID, Quantity, AvailableCopies, PublishYear)
    VALUES
        (1, N'Palace Walk', N'9789770000001', 1, 1, 5, 5, 1956),
        (2, N'The Days', N'9789770000002', 2, 1, 4, 4, 1929),
        (3, N'Murder on the Orient Express', N'9780000000003', 3, 3, 3, 3, 1934),
        (4, N'Nineteen Eighty-Four', N'9780000000004', 4, 4, 6, 6, 1949),
        (5, N'Pride and Prejudice', N'9780000000005', 5, 5, 7, 7, 1813);
    SET IDENTITY_INSERT dbo.Books OFF;

    SET IDENTITY_INSERT dbo.Members ON;
    INSERT INTO dbo.Members (MemberID, FullName, Email, Phone, RegistrationDate)
    VALUES
        (1, N'Ahmed Ali', N'ahmed.ali@example.com', N'01000000001', '2026-01-10'),
        (2, N'Mona Hassan', N'mona.hassan@example.com', N'01000000002', '2026-01-12'),
        (3, N'Omar Youssef', N'omar.youssef@example.com', N'01000000003', '2026-01-15'),
        (4, N'Sara Mahmoud', N'sara.mahmoud@example.com', N'01000000004', '2026-01-20'),
        (5, N'Youssef Khaled', N'youssef.khaled@example.com', N'01000000005', '2026-01-25');
    SET IDENTITY_INSERT dbo.Members OFF;

    SET IDENTITY_INSERT dbo.Librarians ON;
    INSERT INTO dbo.Librarians (LibrarianID, FullName, Email, Username)
    VALUES
        (1, N'Nour Samir', N'nour.samir@example.com', N'nour.samir'),
        (2, N'Karim Fathy', N'karim.fathy@example.com', N'karim.fathy'),
        (3, N'Dina Adel', N'dina.adel@example.com', N'dina.adel');
    SET IDENTITY_INSERT dbo.Librarians OFF;

    COMMIT TRANSACTION;
    PRINT 'Base sample data inserted successfully. Loans remains empty.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
