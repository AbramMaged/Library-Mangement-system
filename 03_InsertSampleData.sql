-- ============================================================
-- FILE: 03_InsertSampleData.sql
-- PURPOSE: Insert realistic sample data into all six tables
-- RUN ORDER: Step 3 of 4 — Run AFTER 02_CreateTables.sql
-- NOTE: This script is intended to be run ONCE on a fresh
--       database. It will REFUSE to run if any table already
--       contains rows, protecting existing data from duplicates.
--       To reset: clear all tables in reverse FK order first
--       (Loans → Books → Members → Librarians → Authors → Categories)
--       then re-run this script.
-- ============================================================

USE LibraryManagementDB;
GO

SET NOCOUNT ON;      -- Suppresses "N rows affected" noise in the Messages tab
SET XACT_ABORT ON;   -- Automatically rolls back the transaction on any error
GO

-- ============================================================
-- SAFETY CHECK
-- ============================================================
-- Refuse to insert if any table already has data.
-- This prevents accidental duplicate rows.

IF EXISTS (SELECT 1 FROM Authors)
   OR EXISTS (SELECT 1 FROM Categories)
   OR EXISTS (SELECT 1 FROM Books)
   OR EXISTS (SELECT 1 FROM Members)
   OR EXISTS (SELECT 1 FROM Librarians)
   OR EXISTS (SELECT 1 FROM Loans)
BEGIN
    THROW 50001,
        'Sample data was not inserted: one or more tables are not empty. '
      + 'Use an empty database or clear the existing test data first.',
        1;
END;
GO

-- ============================================================
-- ALL INSERTS WRAPPED IN A SINGLE TRANSACTION
-- ============================================================
-- BEGIN TRANSACTION / COMMIT means: if anything goes wrong
-- (a constraint violation, a type mismatch, etc.) the entire
-- batch is rolled back and nothing is saved.  The CATCH block
-- handles the rollback and re-throws the original error so you
-- can see exactly what failed.

BEGIN TRY
    BEGIN TRANSACTION;

    -- --------------------------------------------------------
    -- 1. AUTHORS (12)
    -- --------------------------------------------------------
    INSERT INTO Authors (AuthorName, Biography)
    VALUES
        (N'George Orwell',      N'English novelist known for political fiction.'),
        (N'Jane Austen',        N'English novelist known for social commentary and romance.'),
        (N'Chinua Achebe',      N'Nigerian novelist and essayist.'),
        (N'Naguib Mahfouz',     N'Egyptian novelist and Nobel Prize laureate.'),
        (N'Agatha Christie',    N'English writer known for detective fiction.'),
        (N'J.K. Rowling',       N'British author of the Harry Potter series.'),
        (N'Yuval Noah Harari',  N'Israeli historian and popular science author.'),
        (N'Stephen Hawking',    N'Theoretical physicist and science writer.'),
        (N'Tayeb Salih',        N'Sudanese writer known for modern Arabic literature.'),
        (N'Mary Shelley',       N'English novelist and author of Frankenstein.'),
        (N'Paulo Coelho',       N'Brazilian novelist.'),
        (N'Malcolm Gladwell',   N'Canadian journalist and author.');

    -- --------------------------------------------------------
    -- 2. CATEGORIES (10)
    -- --------------------------------------------------------
    INSERT INTO Categories (CategoryName)
    VALUES
        (N'Fiction'),
        (N'Science'),
        (N'History'),
        (N'Technology'),
        (N'Mystery'),
        (N'Fantasy'),
        (N'Biography'),
        (N'Philosophy'),
        (N'Literature'),
        (N'Self-Development');

    -- --------------------------------------------------------
    -- 3. BOOKS (48)
    -- --------------------------------------------------------
    -- AuthorID and CategoryID refer to the identity values
    -- assigned by SQL Server in the INSERT statements above.
    -- AuthorID 1 = George Orwell, 2 = Jane Austen, etc.
    -- CategoryID 1 = Fiction, 2 = Science, 3 = History, etc.

    INSERT INTO Books (Title, ISBN, AuthorID, CategoryID, Quantity, AvailableCopies, PublishYear)
    VALUES
        (N'1984',                                        N'9780451524935', 1,  1,  6, 5, 1949),
        (N'Animal Farm',                                 N'9780451526342', 1,  1,  5, 4, 1945),
        (N'Pride and Prejudice',                         N'9780141439518', 2,  1,  4, 3, 1813),
        (N'Sense and Sensibility',                       N'9780141439662', 2,  9,  3, 2, 1811),
        (N'Things Fall Apart',                           N'9780385474542', 3,  9,  4, 3, 1958),
        (N'No Longer at Ease',                           N'9780385474559', 3,  9,  3, 2, 1960),
        (N'Palace Walk',                                 N'9780307426425', 4,  9,  4, 3, 1956),
        (N'The Thief and the Dogs',                      N'9780385264761', 4,  1,  3, 2, 1961),
        (N'Murder on the Orient Express',                N'9780062693662', 5,  5,  5, 4, 1934),
        (N'And Then There Were None',                    N'9780062073488', 5,  5,  6, 5, 1939),
        (N'Harry Potter and the Philosopher''s Stone',   N'9780747532699', 6,  6,  7, 6, 1997),
        (N'Harry Potter and the Chamber of Secrets',     N'9780747538493', 6,  6,  5, 4, 1998),
        (N'Sapiens',                                     N'9780062316097', 7,  3,  6, 5, 2011),
        (N'Homo Deus',                                   N'9780062464316', 7,  8,  4, 3, 2015),
        (N'A Brief History of Time',                     N'9780553380163', 8,  2,  5, 4, 1988),
        (N'The Universe in a Nutshell',                  N'9780553802023', 8,  2,  3, 2, 2001),
        (N'Season of Migration to the North',            N'9781590173022', 9,  9,  4, 3, 1966),
        (N'The Wedding of Zein',                         N'9780435909701', 9,  9,  2, 1, 1969),
        (N'Frankenstein',                                N'9780486282114', 10, 1,  5, 4, 1818),
        (N'The Last Man',                                N'9780140433624', 10, 1,  2, 1, 1826),
        (N'The Alchemist',                               N'9780061122415', 11, 10, 8, 8, 1988),
        (N'Brida',                                       N'9780061578294', 11, 1,  3, 3, 1990),
        (N'Outliers',                                    N'9780316017930', 12, 10, 4, 4, 2008),
        (N'Blink',                                       N'9780316010665', 12, 10, 3, 3, 2005),
        (N'The Road to Wigan Pier',                      N'9781000000001', 1,  9,  2, 2, 1937),
        (N'Coming Up for Air',                           N'9781000000002', 1,  1,  2, 2, 1939),
        (N'Emma',                                        N'9781000000003', 2,  1,  4, 4, 1815),
        (N'Mansfield Park',                              N'9781000000004', 2,  9,  3, 3, 1814),
        (N'Arrow of God',                                N'9781000000005', 3,  9,  3, 3, 1964),
        (N'A Man of the People',                         N'9781000000006', 3,  1,  3, 3, 1966),
        (N'Children of Gebelawi',                        N'9781000000007', 4,  9,  2, 2, 1959),
        (N'Miramar',                                     N'9781000000008', 4,  9,  6, 6, 1967),
        (N'The ABC Murders',                             N'9781000000009', 5,  5,  2, 2, 1936),
        (N'Death on the Nile',                           N'9781000000010', 5,  5,  6, 6, 1937),
        (N'Harry Potter and the Prisoner of Azkaban',    N'9781000000011', 6,  6,  5, 5, 1999),
        (N'Fantastic Beasts',                            N'9781000000012', 6,  6,  2, 2, 2001),
        (N'21 Lessons for the 21st Century',             N'9781000000013', 7,  8,  2, 2, 2018),
        (N'Money: Master the Game',                      N'9781000000014', 7,  10, 2, 2, 2014),
        (N'Black Holes and Baby Universes',              N'9781000000015', 8,  2,  3, 3, 1993),
        (N'The Grand Design',                            N'9781000000016', 8,  2,  3, 3, 2010),
        (N'The Doum Tree of Wad Hamid',                  N'9781000000017', 9,  9,  6, 6, 1960),
        (N'Bandarshah',                                  N'9781000000018', 9,  9,  6, 6, 1971),
        (N'Mathilda',                                    N'9781000000019', 10, 1,  2, 2, 1819),
        (N'Valperga',                                    N'9781000000020', 10, 1,  6, 6, 1823),
        (N'The Pilgrimage',                              N'9781000000021', 11, 10, 3, 3, 1987),
        (N'The Devil and Miss Prym',                     N'9781000000022', 11, 1,  6, 6, 2000),
        (N'The Tipping Point',                           N'9781000000023', 12, 10, 5, 5, 2000),
        (N'David and Goliath',                           N'9781000000024', 12, 10, 3, 3, 2013);

    -- --------------------------------------------------------
    -- 4. MEMBERS (30)
    -- --------------------------------------------------------
    INSERT INTO Members (FullName, Email, Phone, RegistrationDate)
    VALUES
        (N'Liam Carter',        N'liam.carter@example.com',        N'+1-202-555-0101', '2025-01-12'),
        (N'Olivia Bennett',     N'olivia.bennett@example.com',     N'+1-202-555-0102', '2025-02-03'),
        (N'Noah Wilson',        N'noah.wilson@example.com',        N'+1-202-555-0103', '2025-02-18'),
        (N'Emma Thompson',      N'emma.thompson@example.com',      N'+1-202-555-0104', '2025-03-01'),
        (N'Oliver Davis',       N'oliver.davis@example.com',       N'+1-202-555-0105', '2025-03-14'),
        (N'Amelia Martin',      N'amelia.martin@example.com',      N'+1-202-555-0106', '2025-04-09'),
        (N'Elijah Garcia',      N'elijah.garcia@example.com',      N'+1-202-555-0107', '2025-04-21'),
        (N'Sophia Rodriguez',   N'sophia.rodriguez@example.com',   N'+1-202-555-0108', '2025-05-05'),
        (N'James Lewis',        N'james.lewis@example.com',        N'+1-202-555-0109', '2025-05-19'),
        (N'Isabella Walker',    N'isabella.walker@example.com',    N'+1-202-555-0110', '2025-06-02'),
        (N'Benjamin Hall',      N'benjamin.hall@example.com',      N'+1-202-555-0111', '2025-06-17'),
        (N'Mia Allen',          N'mia.allen@example.com',          N'+1-202-555-0112', '2025-07-08'),
        (N'Lucas Young',        N'lucas.young@example.com',        N'+1-202-555-0113', '2025-07-22'),
        (N'Charlotte King',     N'charlotte.king@example.com',     N'+1-202-555-0114', '2025-08-11'),
        (N'Henry Wright',       N'henry.wright@example.com',       N'+1-202-555-0115', '2025-08-26'),
        (N'Evelyn Scott',       N'evelyn.scott@example.com',       N'+1-202-555-0116', '2025-09-10'),
        (N'Alexander Green',    N'alexander.green@example.com',    N'+1-202-555-0117', '2025-09-24'),
        (N'Harper Baker',       N'harper.baker@example.com',       N'+1-202-555-0118', '2025-10-06'),
        (N'Daniel Adams',       N'daniel.adams@example.com',       N'+1-202-555-0119', '2025-10-20'),
        (N'Abigail Nelson',     N'abigail.nelson@example.com',     N'+1-202-555-0120', '2025-11-03'),
        (N'Matthew Hill',       N'matthew.hill@example.com',       N'+1-202-555-0121', '2025-11-18'),
        (N'Ella Campbell',      N'ella.campbell@example.com',      N'+1-202-555-0122', '2025-12-02'),
        (N'Jackson Mitchell',   N'jackson.mitchell@example.com',   N'+1-202-555-0123', '2026-01-14'),
        (N'Avery Roberts',      N'avery.roberts@example.com',      N'+1-202-555-0124', '2026-02-09'),
        (N'Sebastian Turner',   N'sebastian.turner@example.com',   N'+1-202-555-0125', '2026-03-16'),
        (N'Scarlett Phillips',  N'scarlett.phillips@example.com',  N'+1-202-555-0126', '2026-04-04'),
        (N'Jack Parker',        N'jack.parker@example.com',        N'+1-202-555-0127', '2026-05-13'),
        (N'Grace Evans',        N'grace.evans@example.com',        N'+1-202-555-0128', '2026-06-21'),
        (N'Owen Edwards',       N'owen.edwards@example.com',       N'+1-202-555-0129', '2026-08-07'),
        (N'Chloe Collins',      N'chloe.collins@example.com',      N'+1-202-555-0130', '2026-10-02');

    -- --------------------------------------------------------
    -- 5. LIBRARIANS (4)
    -- --------------------------------------------------------
    INSERT INTO Librarians (FullName, Email, Username)
    VALUES
        (N'Daniel Morgan', N'daniel.morgan@library.example.com', N'dmorgan'),
        (N'Sarah Cooper',  N'sarah.cooper@library.example.com',  N'scooper'),
        (N'Michael Reed',  N'michael.reed@library.example.com',  N'mreed'),
        (N'Nora Foster',   N'nora.foster@library.example.com',   N'nfoster');

    -- --------------------------------------------------------
    -- 6. LOANS (70)
    -- --------------------------------------------------------
    -- 50 returned loans  → ReturnDate has a value
    -- 10 active loans    → ReturnDate IS NULL, DueDate in the future
    -- 10 overdue loans   → ReturnDate IS NULL, DueDate already past
    --
    -- NULL in T-SQL is written as NULL (not Python's None).

    INSERT INTO Loans (BookID, MemberID, LibrarianID, BorrowDate, DueDate, ReturnDate)
    VALUES
        -- Returned loans (50 rows)
        ( 1,  1, 1, '20260303', '20260317', '20260323'),
        ( 2,  2, 2, '20260529', '20260612', '20260531'),
        ( 3,  3, 3, '20250925', '20251009', '20251002'),
        ( 4,  4, 4, '20251026', '20251109', '20251110'),
        ( 5,  5, 1, '20260427', '20260511', '20260507'),
        ( 6,  6, 2, '20260731', '20260814', '20260808'),
        ( 7,  7, 3, '20250923', '20251007', '20251005'),
        ( 8,  8, 4, '20260827', '20260910', '20260831'),
        ( 9,  9, 1, '20260407', '20260421', '20260412'),
        (10, 10, 2, '20260418', '20260502', '20260501'),
        (11, 11, 3, '20251213', '20251227', '20251223'),
        (12, 12, 4, '20250831', '20250914', '20250903'),
        (13, 13, 1, '20251010', '20251024', '20251026'),
        (14, 14, 2, '20260117', '20260131', '20260122'),
        (15, 15, 3, '20260408', '20260422', '20260412'),
        (16, 16, 4, '20260109', '20260123', '20260120'),
        (17, 17, 1, '20250820', '20250903', '20250902'),
        (18, 18, 2, '20251227', '20260110', '20260104'),
        (19, 19, 3, '20251023', '20251106', '20251027'),
        (20, 20, 4, '20260925', '20261009', '20261004'),
        (21, 21, 1, '20250918', '20251002', '20250929'),
        (22, 22, 2, '20260908', '20260922', '20260917'),
        (23, 23, 3, '20250801', '20250815', '20250806'),
        (24, 24, 4, '20260407', '20260421', '20260417'),
        (25, 25, 1, '20260228', '20260314', '20260313'),
        (26, 26, 2, '20260727', '20260810', '20260809'),
        (27, 27, 3, '20260420', '20260504', '20260428'),
        (28, 28, 4, '20251109', '20251123', '20251119'),
        (29, 29, 1, '20251024', '20251107', '20251028'),
        (30, 30, 2, '20251211', '20251225', '20251218'),
        (31,  1, 3, '20260118', '20260201', '20260127'),
        (32,  2, 4, '20260727', '20260810', '20260812'),
        (33,  3, 1, '20260407', '20260421', '20260417'),
        (34,  4, 2, '20251125', '20251209', '20251214'),
        (35,  5, 3, '20260628', '20260712', '20260710'),
        (36,  6, 4, '20250813', '20250827', '20250816'),
        (37,  7, 1, '20260623', '20260707', '20260626'),
        (38,  8, 2, '20250901', '20250915', '20250913'),
        (39,  9, 3, '20260327', '20260410', '20260406'),
        (40, 10, 4, '20260915', '20260929', '20260923'),
        (41, 11, 1, '20250708', '20250722', '20250728'),
        (42, 12, 2, '20250727', '20250810', '20250808'),
        (43, 13, 3, '20260702', '20260716', '20260719'),
        (44, 14, 4, '20260330', '20260413', '20260415'),
        (45, 15, 1, '20260806', '20260820', '20260816'),
        (46, 16, 2, '20260808', '20260822', '20260817'),
        (47, 17, 3, '20251002', '20251016', '20251021'),
        (48, 18, 4, '20260116', '20260130', '20260126'),
        ( 1, 19, 1, '20251001', '20251015', '20251021'),
        ( 2, 20, 2, '20260313', '20260327', '20260402'),

        -- Active loans — DueDate is in the future (10 rows)
        ( 1,  6, 1, '20261110', '20261123', NULL),
        ( 2,  7, 2, '20261113', '20261120', NULL),
        ( 3,  8, 3, '20261108', '20261125', NULL),
        ( 4,  9, 4, '20261115', '20261130', NULL),
        ( 5, 10, 1, '20261116', '20261201', NULL),
        ( 6, 11, 2, '20261115', '20261120', NULL),
        ( 7, 12, 3, '20261114', '20261130', NULL),
        ( 8, 13, 4, '20261110', '20261127', NULL),
        ( 9, 14, 1, '20261115', '20261124', NULL),
        (10, 15, 2, '20261110', '20261127', NULL),

        -- Overdue loans — DueDate has already passed (10 rows)
        (11, 16, 2, '20261014', '20261028', NULL),
        (12, 17, 3, '20261012', '20261026', NULL),
        (13, 18, 4, '20261020', '20261103', NULL),
        (14, 19, 1, '20261011', '20261025', NULL),
        (15, 20, 2, '20261001', '20261015', NULL),
        (16, 21, 3, '20260928', '20261012', NULL),
        (17, 22, 4, '20261028', '20261111', NULL),
        (18, 23, 1, '20261007', '20261021', NULL),
        (19, 24, 2, '20261005', '20261019', NULL),
        (20, 25, 3, '20261025', '20261108', NULL);

    COMMIT TRANSACTION;
    PRINT 'Sample data inserted successfully inside a transaction.';
END TRY
BEGIN CATCH
    -- Roll back everything if any single statement failed
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    -- Re-throw the original error so you can see what went wrong
    THROW;
END CATCH;
GO

-- ============================================================
-- VERIFICATION: Expected row counts
-- ============================================================
SELECT 'Authors'    AS TableName, COUNT(*) AS TotalRecords FROM Authors    UNION ALL
SELECT 'Categories' AS TableName, COUNT(*) AS TotalRecords FROM Categories  UNION ALL
SELECT 'Books'      AS TableName, COUNT(*) AS TotalRecords FROM Books       UNION ALL
SELECT 'Members'    AS TableName, COUNT(*) AS TotalRecords FROM Members     UNION ALL
SELECT 'Librarians' AS TableName, COUNT(*) AS TotalRecords FROM Librarians  UNION ALL
SELECT 'Loans'      AS TableName, COUNT(*) AS TotalRecords FROM Loans;
GO

-- ============================================================
-- LOAN STATUS OVERVIEW
-- ============================================================
-- Shows how many loans are Returned / Active / Overdue.
-- Based on today's date at the moment this query is run.

SELECT
    CASE
        WHEN ReturnDate IS NOT NULL                      THEN 'Returned'
        WHEN DueDate < CAST(GETDATE() AS DATE)           THEN 'Overdue'
        ELSE 'Active'
    END                 AS LoanStatus,
    COUNT(*)            AS TotalLoans
FROM Loans
GROUP BY
    CASE
        WHEN ReturnDate IS NOT NULL                      THEN 'Returned'
        WHEN DueDate < CAST(GETDATE() AS DATE)           THEN 'Overdue'
        ELSE 'Active'
    END;
GO
