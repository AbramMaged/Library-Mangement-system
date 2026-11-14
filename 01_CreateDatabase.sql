-- ============================================================
-- FILE: 01_CreateDatabase.sql
-- PURPOSE: Create the LibraryManagementDB database
-- RUN ORDER: Step 1 of 4 — Run this FIRST on a fresh SQL Server
-- NOTE: This script is intended to be run ONCE on a new server.
--       If the database already exists, this script will skip
--       creation to protect existing data.
-- ============================================================

-- Switch to the master database before creating a new one.
-- The master database is the system database where all new
-- databases are registered.
USE master;
GO

-- ============================================================
-- CREATE DATABASE (Safe Check)
-- ============================================================
-- We check if 'LibraryManagementDB' already exists before
-- trying to create it. This prevents accidental overwriting
-- of an existing database.

IF NOT EXISTS (
    SELECT name
    FROM sys.databases
    WHERE name = N'LibraryManagementDB'
)
BEGIN
    CREATE DATABASE LibraryManagementDB;
    PRINT 'Database "LibraryManagementDB" created successfully.';
END
ELSE
BEGIN
    PRINT 'Database "LibraryManagementDB" already exists. Skipping creation.';
END
GO

-- ============================================================
-- SELECT THE DATABASE
-- ============================================================
-- Switch to the newly created (or existing) database so that
-- all subsequent scripts run in the correct context.

USE LibraryManagementDB;
GO

PRINT 'Now using database: LibraryManagementDB';
GO
