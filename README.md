# Library Management System — Database Documentation

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

## Script Execution Order

> [!IMPORTANT]
> Run the SQL scripts **in this exact order** on a fresh SQL Server instance. Scripts `01` through `03` are designed to be run **once only** on a new database. Running them again on an existing database may produce duplicate data errors.

| Order | File | Purpose |
|---|---|---|
| 1 | `01_CreateDatabase.sql` | Creates `LibraryManagementDB` (skips if already exists) |
| 2 | `02_CreateTables.sql` | Creates all six tables with constraints |
| 3 | `03_InsertSampleData.sql` | Inserts realistic sample data |
| 4 | `04_TestQueries.sql` | Verifies data with 10 queries + constraint tests |

**How to run in SSMS:**
1. Open SQL Server Management Studio.
2. Connect to your SQL Server instance.
3. Open each file: `File → Open → File...`
4. Click **Execute** (or press **F5**) to run the full script.
5. Check the **Messages** tab at the bottom for `PRINT` output and any errors.

---

## Database Schema
Entity-Relationship Overview#
<img width="2752" height="1536" alt="image" src="https://github.com/user-attachments/assets/896b679b-35f7-4a0e-8e77-e5e101edd879" />

Table Descriptions#
Table 1: Authors#
Stores information about book authors.

Column	Type	Constraints	Description
AuthorID	INT	PK, Identity	Auto-generated unique identifier
AuthorName	NVARCHAR(100)	NOT NULL	Full name of the author
Biography	NVARCHAR(500)	NULL	Optional short biography
Relationships: One Author → Many Books

Table 2: Categories#
Stores book genre/category names.

Column	Type	Constraints	Description
CategoryID	INT	PK, Identity	Auto-generated unique identifier
CategoryName	NVARCHAR(100)	NOT NULL, UNIQUE	Category label (e.g., Fiction, Science)
Relationships: One Category → Many Books

Table 3: Books#
The central catalog of all books in the library.

Column	Type	Constraints	Description
BookID	INT	PK, Identity	Auto-generated unique identifier
Title	NVARCHAR(200)	NOT NULL	Full book title
ISBN	NVARCHAR(20)	NOT NULL, UNIQUE	International Standard Book Number
AuthorID	INT	FK → Authors	Links to the book's author
CategoryID	INT	FK → Categories	Links to the book's genre
Quantity	INT	NOT NULL, ≥ 0	Total copies owned by the library
AvailableCopies	INT	NOT NULL, 0 ≤ value ≤ Quantity	Copies currently on the shelf
PublishYear	INT	NULL, ≥ 1450	Optional publication year
CHECK Constraints:

Quantity >= 0 — cannot own a negative number of books
AvailableCopies >= 0 AND AvailableCopies <= Quantity
PublishYear IS NULL OR PublishYear >= 1450
Relationships: Many Books → One Author; Many Books → One Category; One Book → Many Loans

Table 4: Members#
Stores library member (student/staff) records.

Column	Type	Constraints	Description
MemberID	INT	PK, Identity	Auto-generated unique identifier
FullName	NVARCHAR(150)	NOT NULL	Member's full name
Email	NVARCHAR(254)	NOT NULL, UNIQUE	Contact email address
Phone	NVARCHAR(30)	NULL	Optional phone number
RegistrationDate	DATE	NOT NULL, Default: today	Date the member registered
Relationships: One Member → Many Loans

Table 5: Librarians#
Stores staff accounts who process loan transactions.

Column	Type	Constraints	Description
LibrarianID	INT	PK, Identity	Auto-generated unique identifier
FullName	NVARCHAR(150)	NOT NULL	Librarian's full name
Email	NVARCHAR(254)	NOT NULL, UNIQUE	Staff email address
Username	NVARCHAR(50)	NOT NULL, UNIQUE	Login username (no password in Milestone 1)
Relationships: One Librarian → Many Loans

Table 6: Loans#
Records every borrowing transaction. This is the most important table as it connects books, members, and librarians.

Column	Type	Constraints	Description
LoanID	INT	PK, Identity	Auto-generated unique identifier
BookID	INT	FK → Books	Which book was borrowed
MemberID	INT	FK → Members	Who borrowed it
LibrarianID	INT	FK → Librarians	Who processed the loan
BorrowDate	DATE	NOT NULL, Default: today	Date the book was taken out
DueDate	DATE	NOT NULL, ≥ BorrowDate	Date the book must be returned
ReturnDate	DATE	NULL, ≥ BorrowDate	Date returned; NULL = not yet returned
CHECK Constraints:

DueDate >= BorrowDate — due date cannot be before borrow date
ReturnDate IS NULL OR ReturnDate >= BorrowDate
Loan Status Logic:

ReturnDate IS NULL AND DueDate >= today → Active
ReturnDate IS NULL AND DueDate < today → Overdue
ReturnDate IS NOT NULL → Returned
Foreign Key Summary#
Constraint Name	Table	Column	References
FK_Books_Authors	Books	AuthorID	Authors.AuthorID
FK_Books_Categories	Books	CategoryID	Categories.CategoryID
FK_Loans_Books	Loans	BookID	Books.BookID
FK_Loans_Members	Loans	MemberID	Members.MemberID
FK_Loans_Librarians	Loans	LibrarianID	Librarians.LibrarianID
