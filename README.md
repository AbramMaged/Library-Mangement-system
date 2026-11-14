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

---

## Table Descriptions

### Table 1: `Authors`

Stores information about book authors.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `AuthorID` | `INT` | PK, Identity | Auto-generated unique identifier |
| `AuthorName` | `NVARCHAR(100)` | NOT NULL | Full name of the author |
| `Biography` | `NVARCHAR(500)` | NULL | Optional short biography |

**Relationships:** One `Author` → Many `Books`

---
