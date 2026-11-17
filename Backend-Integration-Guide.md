# Backend Integration Guide — Library Management System

> **Audience:** Node.js + Express backend developers connecting to `LibraryManagementDB` in Milestone 2.

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

**Example connection with `mssql`:**
```javascript
const sql = require('mssql');

const config = {
  server:   process.env.DB_SERVER,
  database: process.env.DB_NAME,
  user:     process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  port:     parseInt(process.env.DB_PORT) || 1433,
  options: {
    encrypt: false,          // set to true if using Azure SQL
    trustServerCertificate: true
  }
};
```

---

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

All primary keys are auto-incremented integers (`INT IDENTITY`). The database generates them — your backend should **never** manually insert an ID value.

### Foreign Keys in `Books`

| Column | References |
|---|---|
| `AuthorID` | `Authors.AuthorID` |
| `CategoryID` | `Categories.CategoryID` |

### Foreign Keys in `Loans`

| Column | References |
|---|---|
| `BookID` | `Books.BookID` |
| `MemberID` | `Members.MemberID` |
| `LibrarianID` | `Librarians.LibrarianID` |

---

## 4. Important Columns to Know

### `Books.AvailableCopies`
- Tracks how many copies are currently on the shelf.
- Must always be between `0` and `Quantity`.
- **Must be decremented by 1** when a book is borrowed.
- **Must be incremented by 1** when a book is returned.
- Never set it directly to an arbitrary number; always use `+1` or `-1`.

### `Loans.ReturnDate`
- `NULL` = the book has **not been returned** yet (active loan).
- A date value = the book **has been returned**.
- When recording a return, set this to the current date: `CAST(GETDATE() AS DATE)`.

### `Members.RegistrationDate` and `Loans.BorrowDate`
- Both have `DEFAULT GETDATE()`.
- If the backend does not send these values, SQL Server will use today's date automatically.

---

## 5. How to Retrieve Books, Members, and Loans

### Get All Books with Author and Category
```sql
SELECT
    b.BookID,
    b.Title,
    b.ISBN,
    a.AuthorName,
    c.CategoryName,
    b.Quantity,
    b.AvailableCopies,
    b.PublishYear
FROM Books       AS b
JOIN Authors     AS a ON b.AuthorID    = a.AuthorID
JOIN Categories  AS c ON b.CategoryID = c.CategoryID
ORDER BY b.Title;
```

### Get a Single Book by ID
```sql
SELECT
    b.BookID, b.Title, b.ISBN,
    a.AuthorName, c.CategoryName,
    b.Quantity, b.AvailableCopies, b.PublishYear
FROM Books b
JOIN Authors    a ON b.AuthorID    = a.AuthorID
JOIN Categories c ON b.CategoryID = c.CategoryID
WHERE b.BookID = @BookID;        -- Replace @BookID with the route parameter
```

### Search Books by Title or ISBN
```sql
SELECT b.BookID, b.Title, b.ISBN, a.AuthorName, b.AvailableCopies
FROM Books b
JOIN Authors a ON b.AuthorID = a.AuthorID
WHERE b.Title LIKE '%' + @SearchTerm + '%'
   OR b.ISBN  LIKE '%' + @SearchTerm + '%';
```

### Get All Active Loans
```sql
SELECT
    l.LoanID,
    b.Title        AS BookTitle,
    m.FullName     AS MemberName,
    lib.FullName   AS LibrarianName,
    l.BorrowDate,
    l.DueDate
FROM Loans      AS l
JOIN Books      AS b   ON l.BookID      = b.BookID
JOIN Members    AS m   ON l.MemberID    = m.MemberID
JOIN Librarians AS lib ON l.LibrarianID = lib.LibrarianID
WHERE l.ReturnDate IS NULL
ORDER BY l.DueDate;
```

### Get Loan History for a Member
```sql
SELECT
    l.LoanID,
    b.Title  AS BookTitle,
    l.BorrowDate,
    l.DueDate,
    l.ReturnDate,
    CASE
        WHEN l.ReturnDate IS NOT NULL              THEN 'Returned'
        WHEN l.DueDate < CAST(GETDATE() AS DATE)   THEN 'Overdue'
        ELSE 'Active'
    END AS LoanStatus
FROM Loans  AS l
JOIN Books  AS b ON l.BookID = b.BookID
WHERE l.MemberID = @MemberID
ORDER BY l.BorrowDate DESC;
```

---

## 6. Borrow and Return Operations

> [!WARNING]
> These two operations each update **two tables**. Both updates must succeed or neither should be saved. In Milestone 2, wrap them in a **database transaction** to prevent data inconsistency.

### Borrow a Book (Two Steps)

**Step 1 — Check availability before borrowing:**
```sql
SELECT AvailableCopies FROM Books WHERE BookID = @BookID;
-- If AvailableCopies = 0, reject the request in your backend code.
```

**Step 2a — Create the loan record:**
```sql
INSERT INTO Loans (BookID, MemberID, LibrarianID, BorrowDate, DueDate)
VALUES (@BookID, @MemberID, @LibrarianID, CAST(GETDATE() AS DATE), @DueDate);
```

**Step 2b — Decrement available copies:**
```sql
UPDATE Books
SET AvailableCopies = AvailableCopies - 1
WHERE BookID = @BookID
  AND AvailableCopies > 0;    -- Safety check: never go below 0
```

---

### Return a Book (Two Steps)

**Step 1 — Mark the loan as returned:**
```sql
UPDATE Loans
SET ReturnDate = CAST(GETDATE() AS DATE)
WHERE LoanID      = @LoanID
  AND ReturnDate IS NULL;     -- Only update if not already returned
```

**Step 2 — Increment available copies:**
```sql
UPDATE Books
SET AvailableCopies = AvailableCopies + 1
WHERE BookID = @BookID
  AND AvailableCopies < Quantity;    -- Never exceed total Quantity
```

---

### Recommended Transaction Pattern (Milestone 2)

```javascript
const pool = await sql.connect(config);
const transaction = new sql.Transaction(pool);

try {
    await transaction.begin();

    // Run both UPDATE statements here using the transaction

    await transaction.commit();
} catch (err) {
    await transaction.rollback();
    throw err;
}
```

---

## 7. API Endpoint Suggestions

The following endpoints are suggested for Milestone 2 based on the database structure:

| Method | Endpoint | Action | Tables Used |
|---|---|---|---|
| `GET` | `/api/books` | Get all books with author & category | Books, Authors, Categories |
| `GET` | `/api/books/:id` | Get one book by ID | Books, Authors, Categories |
| `GET` | `/api/books/search?q=` | Search books | Books, Authors |
| `GET` | `/api/members` | Get all members | Members |
| `GET` | `/api/members/:id` | Get one member | Members |
| `GET` | `/api/members/:id/loans` | Get a member's loan history | Loans, Books |
| `GET` | `/api/loans/active` | Get all active loans | Loans, Books, Members |
| `GET` | `/api/loans/overdue` | Get overdue loans | Loans, Books, Members |
| `POST` | `/api/loans` | Borrow a book | Loans + Books (AvailableCopies) |
| `PUT` | `/api/loans/:id/return` | Return a book | Loans + Books (AvailableCopies) |

---

## 8. Data Integrity Rules the Backend Must Enforce

These rules are enforced by database constraints, but the backend should also validate them before sending queries to provide user-friendly error messages:

| Rule | Where Enforced |
|---|---|
| A book can only be borrowed if `AvailableCopies > 0` | Backend + DB CHECK |
| A loan cannot be created with `DueDate < BorrowDate` | DB CHECK |
| A loan's `ReturnDate` cannot be earlier than `BorrowDate` | DB CHECK |
| Email addresses must be unique for members and librarians | DB UNIQUE |
| ISBN must be unique across all books | DB UNIQUE |
| Cannot delete a member or book that has existing loans | DB Foreign Key |

---

## 9. Notes for Milestone 2

- **Authentication:** The `Librarians` table has a `Username` column ready. Add a `PasswordHash` column in Milestone 2 and store hashed passwords (never plaintext).
- **Pagination:** For large datasets, add `OFFSET` / `FETCH NEXT` to `SELECT` queries.
- **Input Validation:** Always use **parameterized queries** (never string concatenation) to prevent SQL injection.
- **Error Handling:** Catch SQL constraint violations (error codes `2627` = unique violation, `547` = FK violation) and return meaningful HTTP error responses.
