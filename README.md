---

## Database Schema
Entity-Relationship Overview#
<img width="2752" height="1536" alt="image" src="https://github.com/user-attachments/assets/896b679b-35f7-4a0e-8e77-e5e101edd879" />
here the one prof hanfy wants 
<img width="1752" height="1024" alt="schema new" src="https://github.com/user-attachments/assets/42228c2d-45b3-4444-8db7-3c0ff6b1ba60" />

---
## 1. Database Connection Details

| Property | Value |
|---|---|
| **Database Name** | `LibraryManagementDB` |
| **Engine** | Microsoft SQL Server |
| **Recommended Driver** | `mssql` (npm package) |
| **Connection Method** | SQL Server Authentication or Windows Authentication |

> [!IMPORTANT]
> Never hardcode database credentials in your source code. Store the server name, username, and password in environment variables (a `.env` file) and use a package like `dotenv` to load them.

**Example `.env` file (do not commit to version control):**
```
DB_SERVER=localhost
DB_NAME=LibraryManagementDB
DB_USER=your_sql_username
DB_PASSWORD=your_sql_password
DB_PORT=1433
```
## 2. Table Names and Their Purposes

| Table | Purpose | Used By |
|---|---|---|
| `Authors` | Stores author names and biographies | Books listing, book detail pages |
| `Categories` | Stores genre/category names | Filtering books by category |
| `Books` | Main catalog: titles, ISBNs, quantities | Search, browse, availability check |
| `Members` | Library member profiles | Member management, loan history |
| `Librarians` | Staff accounts who process loans | Loan processing (login in Milestone 2) |
| `Loans` | Every borrow/return transaction | Loan management, overdue tracking |

---

## 3. Primary and Foreign Keys

### Primary Keys

| Table | Primary Key Column |
|---|---|
| `Authors` | `AuthorID` |
| `Categories` | `CategoryID` |
| `Books` | `BookID` |
| `Members` | `MemberID` |
| `Librarians` | `LibrarianID` |
| `Loans` | `LoanID` |

All primary keys are auto-incremented integers (`INT IDENTITY`). The database generates them — your backend should **never** manually insert an ID value.# Library Management System — Database Documentation

## Project Information

| Property | Value |
|---|---|
| **Project** | University Library Management System |
| **Milestone** | 1 — Database Development |
| **Database Engine** | Microsoft SQL Server |
| **Database Name** | `LibraryManagementDB` |
| **Language** | T-SQL |
| **Tool** | SQL Server Management Studio (SSMS) |

---


**How to run in SSMS:**
1. Open SQL Server Management Studio.
2. Connect to your SQL Server instance.
3. Open each file: `File → Open → File...`
4. Click **Execute** (or press **F5**) to run the full script.
5. Check the **Messages** tab at the bottom for `PRINT` output and any errors.
