-- ============================================================
-- CONNECTION VERIFICATION
-- ============================================================
-- Run this query after connecting to LibraryManagementDB in
-- SSMS or Azure Data Studio.
-- It confirms you are connected to the correct database and
-- that the Azure SQL engine version is detected correctly.

SELECT
    DB_NAME()                           AS CurrentDatabase,
    @@VERSION                           AS EngineVersion,
    GETUTCDATE()                        AS CurrentUTCTime,
    SERVERPROPERTY('Edition')           AS Edition,
    SERVERPROPERTY('EngineEdition')     AS EngineEdition;
-- EngineEdition = 5 confirms you are on Azure SQL Database.
-- EngineEdition = 8 means Azure SQL Managed Instance.
GO

PRINT 'Connection verified. Run 02_CreateTables.sql next.';
GO
