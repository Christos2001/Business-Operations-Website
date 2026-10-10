# 3. Database structure

Engine: `InnoDB`.

Table charset: `utf8mb4`. 

---

Below there are 3 ER (Entity-Relationship) diagrams, each one is a seperate section. 

They contain; all tables and relationships in the projeet.

The number in parentheses is the column length. `NN` means NOT NULL, `NULL` means the column may be empty, `AI` means AUTO_INCREMENT, `DEF` means the default, and `CASCADE` means ON DELETE CASCADE. Amounts are `DECIMAL(10,2)`.

## 1. Organizational structure

```mermaid
---
config:
  htmlLabels: false
  themeVariables:
    fontSize: 26px
  er:
    diagramPadding: 36
    layoutDirection: LR
    entityPadding: 26
    minEntityWidth: 560
    fontSize: 26
---
erDiagram
    direction LR

    company ||--o{ user : "CASCADE 1:N"
    user ||--o| employee : "CASCADE 1:0..1"
    user ||--o| manager : "CASCADE 1:0..1"
    user ||--o{ shifts : "CASCADE 1:N"
    employee ||--o| privileges : "CASCADE 1:0..1"

    company {
        int id PK "AI"
        varchar(60) name UK "NN"
        varchar(14) codeManager UK "NN"
        varchar(14) codeEmployee UK "NN"
    }

    user {
        int id PK "AI"
        varchar(40) Name "NN"
        varchar(40) Surname "NN"
        varchar(255) email UK "NN"
        varchar(30) username UK "NN"
        varchar(255) password "NN"
        varchar(255) profilePhotoFile "NULL"
        boolean emailVerified "NN DEF FALSE"
        int companyID FK "NN CASCADE"
    }

    employee {
        int id PK, FK "CASCADE"
        varchar(50) role "NN"
        varchar(255) description "NULL"
        text notes "NULL"
    }

    manager {
        int id PK, FK "CASCADE"
        varchar(50) role "NN"
        varchar(255) description "NULL"
    }

    shifts {
        int userID FK "NN CASCADE"
        varchar(20) Day "NULL"
        time startTime "NN"
        time endTime "NN"
        date Date "NULL"
    }

    privileges {
        int employeeID PK, FK "CASCADE"
        boolean income "NN DEF FALSE"
        boolean expenses "NN DEF FALSE"
        boolean money-tracker "NN DEF FALSE"
        boolean shift "NN DEF FALSE"
        boolean manage-employees "NN DEF FALSE"
    }
```



The `user.profilePhotoFile` refers to a file under `uploads/profiles/{company}/`.

A weekly shift row has a null date. A one-time row has null day.

## 2. Finance

```mermaid
---
config:
  htmlLabels: false
  themeVariables:
    fontSize: 26px
  er:
    diagramPadding: 36
    layoutDirection: LR
    entityPadding: 26
    minEntityWidth: 560
    fontSize: 26
---
erDiagram
    direction LR

    company ||--o{ expenses : "CASCADE 1:N"
    company ||--o{ income : "CASCADE 1:N"
    company ||--o{ attachments : "CASCADE 1:N"
    income ||--o{ attachments : "CASCADE 0..1:N"
    expenses ||--o{ attachments : "CASCADE 0..1:N"

    company {
        int id PK "AI"
        varchar(60) name UK "NN"
        varchar(14) codeManager UK "NN"
        varchar(14) codeEmployee UK "NN"
    }

    expenses {
        int id PK "AI"
        varchar(300) source "NN"
        decimal expense "10,2 NN"
        date DateOfExpense "NN"
        text Notes "NULL"
        int companyID FK "NN CASCADE"
        timestamp deletedAt "NULL"
    }

    income {
        int id PK "AI"
        varchar(300) Source "NN"
        decimal Income "10,2 NN"
        date DateOfIncome "NN"
        text Notes "NULL"
        int companyID FK "NN CASCADE"
        timestamp deletedAt "NULL"
    }

    attachments {
        int id PK "AI"
        int companyID FK "NN CASCADE"
        varchar(255) fileName UK "NN"
        int incomeID FK "NULL CASCADE"
        int expenseID FK "NULL CASCADE"
    }
```



Attachments are uploaded in `uploads/income/{company}/` and `uploads/expense/{company}/`. 

## 3. Accounts, tokens, and company requests

```mermaid
---
config:
  htmlLabels: false
  themeVariables:
    fontSize: 26px
  er:
    diagramPadding: 36
    layoutDirection: LR
    entityPadding: 26
    minEntityWidth: 560
    fontSize: 26
---
erDiagram
    direction LR

    user ||--o{ email_verification_tokens : "CASCADE 1:N"
    user ||--o{ account_recovery_tokens : "CASCADE 1:N"

    user {
        int id PK "AI"
        varchar(255) email UK "NN"
        boolean emailVerified "NN DEF FALSE"
    }

    email_verification_tokens {
        varchar(64) token PK
        int userID FK "NN CASCADE"
        varchar(255) newEmail "NULL"
        timestamp expiresAt "NN"
    }

    account_recovery_tokens {
        varchar(64) token PK
        int userID FK "NN CASCADE"
        enum type "password, username"
        timestamp expiresAt "NN"
    }

    company_requests {
        int id PK "AI"
        varchar(60) companyName "NN"
        varchar(255) requesterEmail "NN"
        varchar(64) token UK "NN"
        enum status "pending, approved DEF pending"
        timestamp createdAt "DEF now"
    }
```



---

---



## Data kept outside MySQL


| Data                           | Where it is stored                                                        |
| ------------------------------ | ------------------------------------------------------------------------- |
| Income and expense attachments | Files under `uploads/income/{company}/` and `uploads/expense/{company}/`. |
| Profile photos                 | Files under `uploads/profiles/{company}/`.                                |
| Rate-limit counters            | `logs/auth_rate_limits.json`                                              |
| Application error log          | `logs/appErrorLog.json`                                                   |
| Logged-in session              | PHP session cookie. There is no sessions table.                           |
| Forecasts                      | Trained model / forecast data aren't saved in the database.               |


