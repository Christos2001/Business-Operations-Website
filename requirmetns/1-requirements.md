# 1. Requirements

### Roles

Users are either a **manager** or an **employee**. A manager has every permission. An employee starts with no permissions and can use the shift-calendar and profiles until a manager grants flags in the `privileges` table. The navbar shows links only for pages the role allows.

### Privileges


| Flag               | What it unlocks                                         |
| ------------------ | ------------------------------------------------------- |
| `income`           | Income: view, add, delete, restore, download attachment |
| `expenses`         | Expenses: --same--                                      |
| `money-tracker`    | History, charts, and forecasts                          |
| `shift`            | Add and delete shifts                                   |
| `manage-employees` | Employee search, privileges, and notes                  |


---



## 1. New company request



### Functional

**FR-COMP-01.** A representative submits a company name and an email. The name is rejected if a company with that name already exists, or if a `pending` request already exists for the same name or the same email.

**FR-COMP-02.** The system stores the request with a unique token and status `pending`, sends an activation link to email of the moderator (1), and sends an instructions email to the requester with the goal to accomandate the price.

**FR-COMP-03.**  The moderator has to check if the email is linked to the company (manually), and reply with the cost. After payment the compnay reviewer approves through the link (1), that creates two unique 14-character codes: one for managers and one for employees. - With these codes is statistical impossiblee for someone to sign up in a foriegn company.

**FR-COMP-04.** Every submission counts toward the request limit ([more info in security-requirements: SEC-RATE-03](./2-security-requirements.md#SEC-RATE-03)).

### Non-functional

**NFR-COMP-01.** `requestCompany.php` inserts the `company_requests` row before the two SMTP calls. If mail fails, the user sees `Could not send email. Please try again later.` or `Email is not configured`, depending on the case. The company creation and request approval are handled as an **atomic database transaction** to ensure **data consistency**. If any error occurs, a **rollback** is triggered to maintain **atomicity**.

**NFR-COMP-02.** The approval token is `bin2hex(random_bytes(32))` (64 hex characters) and is unique on `company_requests.token`.

---



## 2. Sign up



### Functional

**FR-AUTH-01.** Sign up asks for:

- first name
- surname
- username
- email
- password
- password confirmation
- company code
- role (optional)



### Non-functional

**NFR-AUTH-01.** The `signup.html` checks the password pattern before submit. `signup.php` checks the email with `FILTER_VALIDATE_EMAIL` and checks password length, one letter, and one digit again before any insert. 

**NFR-AUTH-02.** The user row, the `manager` or `employee` row, and the verification token are handled as an atomic database transaction to ensure data consistency. If any error occurs, a rollback is triggered to maintain atomicity.

**FR-AUTH-03.** The password is stored with `password_hash` `PASSWORD_DEFAULT`. 

---



## 3. Login and logout



### Functional

**FR-AUTH-02.** Login uses username and password. Success opens a session and goes to the home page only if the email is verified.

**FR-AUTH-03.** Logout returns to login page.

### Non-functional

**NFR-AUTH-04.**  `login.php` checks with one `SELECT`, `password` and `emailVerified` and redirect user to login page with the right alert or check the hashed password with `password_verify`. 

**FR-AUTH-05.** A successful login stores `loggedin = true` and `username` in the server session. Later `/php/` calls read that username and load `user.id` from it. It also stores `navbarUserAccess` in `sessionStorage`: `role`, `userId`, and the privilege list. The navbar reads sessionStorage value first, then refreshes it from `getUserAccess.php`, the RESTAPIs check the real value on the database.

**NFR-AUTH-07. Missing session.** `check_session.php` exist on every page, there are: HTTP 401 and `{"success":false,"errorMsg":"Not logged in."}`. 

**FR-AUTH-06.** Clicking Logout removes `navbarUserAccess` from `sessionStorage`. `logout.php` then empties `$_SESSION`, expires the session cookie, calls `session_destroy()`, and redirects to the login page.

---



## 4. Password and username recovery



### Functional

**FR-AUTH-04** The user requests a password or username reset, only on login page, and must provide his email. If the emal refers to existing account, a link is sent with a token that expires in 24-hours. 

**FR-AUTH-05.** A new token of the same type (`password` / `username`) for the same user replaces the previous one. The token is single-use and is deleted after use.

**FR-AUTH-06.** The new password follows the same rule as sign up and is stored as a hash. 

### Non-functional

**FR-AUTH-04a.** If the emal refers to existing account, a link is sent with a token that expires in 24-hours. 

**NFR-AUTH-07.**  `forgotPassword.php` and `forgotUsername.php` answer with the same success text whether or not `findUserByEmail` finds a row, ++so the form does not say that an email is registered++. An address that fails `FILTER_VALIDATE_EMAIL` is the case that returns an error.

**NFR-AUTH-08.** The password or username change and the deletion of that recovery token are handled as an atomic database transaction to ensure data consistency. If any error occurs, a rollback is triggered to maintain atomicity. The token is not removed while the account field stays unchanged.

---



## 5. Email change and account deletion



### Functional

FR-AUTH-7. A signed-in user requests an email change, at `profile.html`. The new email must not already belong to an account. A verification link is sent, in the new email. Until verification, the old email stays active.

**FR-AUTH-8.** The user deletes their account at `profile.html` after confirming the current password. Deletion removes the user and, through `ON DELETE CASCADE`, the role, privileges, shifts, and tokens. The user's fullname remains on his contributions: employee notes ([FR-EMP-05](#10-employee-management)) and transaction notes ([FR-INC-02](#11-income-and-expenses)).

### Non-functional

**NFR-AUTH-07a. The new address must have a local part,** `@`**, and a domain, for this "**`FILTER_VALIDATE_EMAIL`**" was used. The link is a 24-hour token stored in DB in:** `email_verification_tokens.newEmail` **.**

**NFR-AUTH-09.** `changeMyEmail.php` rejects the current address and an address of another user before it writes `email_verification_tokens.newEmail`. Applying the new address and deleting that verification token are handled as an atomic database transaction to ensure data consistency. If any error occurs, a rollback is triggered to maintain atomicity. An expired token does not change `user.email`. An expired token is destroyed only if a new token is requested and a normal / verified token is destroyed after the successfull change. 

**NFR-AUTH-10.** `deleteMyAccount.php` checks the posted password with `password_verify` 

**NFR-AUTH-10.** `DELETE FROM user`. That delete and the cascaded rows (role, privileges, shifts, and tokens) are one database change. If it fails, those rows stay. The profile file is removed from `uploads/profiles/{company}/` before the user row is deleted, and that file removal is not rolled back.

---



## 6. Home page



### Functional

**FR-HOME-01.** Home shows the signed-in user's next shift when one exists in a 14 days period. 

**FR-HOME-02.** If colleagues are more than 4, they become scrollable in axon x. The modal with theeir heir names and profile photo is a link that redirects their profile.

**NFR-HOME-02.** It loads the signed-in user's shifts and returns the earliest one whose start is still ahead of now.

**FR-HOME-03.** Home shows aswell to the user with `income`, `expenses`, or `money-tracker` flag (and every manager) a recent-transactions block. Income rows appear only with `income / money-tracker` flag(or as a manager). Expense rows appear only with `expenses / money-tracker` flag (or as a manager).

**Reference image:** ![Home page](images/home-ui.jpg)

### Non-functional

**NFR-HOME-01.**  `getHomeRecentTransactions.php` reads at most 5 income rows and 5 expense rows (`HOME_RECENT_LIMIT`), `deletedAt IS NULL`, ordered by date.

**NFR-HOME-02.** `getMyNextShift.php` is a query used for this feature only.

**NFR-HOME-02.** `getMyNextShift.php` is called only by the home page. It loads the signed-in user's shifts and returns the earliest one still ahead of now. A weekly shift is the next matching weekday within 14 days. Coworkers are other users of the same company on that date or weekday whose times overlap, each person once, ordered by name. There is no row limit. If none is upcoming, the response is `shift: null` and an empty coworker list.

---



## 7. Search



### Functional

**FR-SRCH-01.** Search finds users of the signed-in user's company by name and surname. It is opened from add shift, view employee shifts, and employee management. Results stay inside that company.

**FR-SRCH-02.** Each result shows the full name and a photo.  A user with no uploaded photo shows the built-in gray person silhouette. 

**FR-SRCH-03.** Empty list, shows "Search query is empty". No matches showws "0 results".

**FR-SRCH-04.** ++One++ word matches a name or a surname. Results are ordered by:


| Priority | Match                                                     |
| -------- | --------------------------------------------------------- |
| 1        | Exact name (`Name = 'Grace'`)                             |
| 2        | Name starts with the letters (`Name LIKE 'Grace%'`)       |
| 3        | Exact surname (`Surname = 'Grace'`)                       |
| 4        | Surname starts with the letters (`Surname LIKE 'Grace%'`) |


++Two++ words match a name that starts with the first word and a surname that starts with the second:


| Priority | Match                                                                               |
| -------- | ----------------------------------------------------------------------------------- |
| 1        | Name equals the first word and surname equals the second word                       |
| 2        | First Name begins/matches with `Word_1` AND Last Name begins/matches with `Word_2`. |


**FR-SRCH-05.** When two or more results have the same full name and no photo, each of those rows also shows the user id so they can be told apart. 

### Non-functional

**FR-SRCH-05a.**To succeed with minimal cost, this users with no profile photo are collected in a PHP array as they are `selected`. When that array has two or more people, the search compares their full names. The user id, already returned by the same query and is shown only for those who share a full name. 

**NFR-SRCH-06..** The company filter is `user.companyID` taken from the session, not from the query string. The match is a prepared statement. List photos are the 96 px JPEG, not the 512 px profile file.

**NFR-SRCH-07.** The search runs 300 ms after the last keystroke. A new keystroke cancels the previous wait and drops a request that is still in flight. An empty box does not call the server.

**NFR-SRCH-08.** The endpoint returns JSON. An empty query and a query with no rows are separate messages, so the page can show "Search query is empty." and "0 results" ++without treating both as a server error. make it smaller++

---



## 8. Profile



### Functional

**FR-PROF-01.** The user sees their own profile: name, surname, username, email, role, description, photo, and (for an employee) notes written about them.

**FR-PROF-02.** They are able to edit their role title and description / bio., also they are able to upload a profile photo (JPG or PNG). The system resizes it (longest edge 512 px, JPEG) and keeps a smaller search-list version (96 px). Before 1st upload , the profile photo is a built-in gray person silhouette.

**FR-PROF-04.** Any signed-in user can open a partial profile of a colleague in the **same** company (name, role, description, photo), through shift-calendar and from raw API call. They do not see privileges, or management notes.

### Non-functional

**NFR-PROF-01.**  `PROFILE_PHOTO_MAX_BYTES` is 150 MB, checked before GD resize. A larger file returns `Photo must be 150 MB or smaller.` Other image types are rejected by the JPG/PNG loader (`imagecreatefromjpeg` / `imagecreatefrompng`).

**NFR-PROF-02.** Saving the role and saving the description are each one `UPDATE` on `manager` or `employee` and return JSON. They do not reload the application shell.

**NFR-PROF-04.**  The new photo file is written first, then `user.profilePhotoFile` is updated. If the write fails, the proccess terminates. If the update fails, the file is unlinked. If the update succeeds, the previous photo file is unlinked. 

**NFR-PROF-03.**  `getPartialProfile.php` serves the photo only after the session check and only for a user whose `companyID` matches the caller. The response does not include the password hash, privilege flags, or `employee.notes`.

---



## 9. Shifts



### Functional

**FR-SHIFT-01.** Every signed-in user sees shifts from ++all++ employeess in the shift-calendar.

**FR-SHIFT-02.** From the calendar the user can open the partial profile of a colleague shown on a shift (his full name is displayed).

**FR-SHIFT-03.** A weekly shift has a weekday (Monday–Sunday), a start time, and an end time. A one-time shift has a date, a start, and an end time.

**FR-SHIFT-04.** *Time Rules:* End time is after start time. If the end is earlier on the clock, the shift counts as overnight. Duration cannot exceed 12 hours. The one-time date cannot be in the past.

**FR-SHIFT-05** Adding and deleting a shift is allowed for a manager or an employee with `shift` flag after search ([FR-SRCH-01](#7-search)). 

**FR-SHIFT-06.** Following any add or delete action, verified recipients receive an email notification that contains shift details. The initiating manager or employee gets in app notification, tailored to whether the action succeeded or failed.

**FR-SHIFT-07.** Deleting a shift starts from `view employee shifts` button from shift calendar page. That page lists user's weekly shifts and one-time shifts separately.

### Non-functional

**NFR-SHIFT-01.** Optimal way is used on `calendar.js`, 1 fetch is used that retrieves all weekly shifts and one-time shifts of that month and stores them in a variable that persists for the lifetime of the page. For a new month, only selected one-time shifts are fetched 

**NFR-SHIFT-02.** The shift `INSERT` is already done before `MailService::sendShiftNotification`. A mail exception is caught, written with `logAppError`, and the response in app notification is "Shift saved, but the notification email could not be sent". The shift row is not rolled back. Mail is attempted only when `emailVerified` is true.

**NFR-SHIFT-03.** A weekly row has a null date and a weekday. A one-time row has a date. Add, view, and delete use that same distinction.

---



## 10. Employee management



### Functional

**FR-EMP-01.** A manager, or an employee with `manage-employees`, opens an employee managment page after search ([FR-SRCH-01](#7-search)). Managers don't have one.

**FR-EMP-02.** The management page shows : role, description, photo, ++privileges,++ and ++notes++. The manager / employee can check or uncheck the five flags (`income`, `expenses`, `money-tracker`, `shift`, `manage-employees`). Saving replaces employee's previous privilege row.

**FR-EMP-03.** A user can not change their own privileges through this page.

**FR-EMP-04.** The manager appends a note about the employee. Each note ++stores++ a timestamp, the author's name, and the author's id. One note body is max 1,000 characters. The full history in `employee.notes` is at most 10,000 characters. A new note is appended at the end of the history / notes.

### Non-functional

**NFR-EMP-01. Note check.** saveEmployeeNotes.php measures the new body with `mb_strlen` against 1,000 and the appended employee.notes text against 10,000. Over either limit the response is HTTP 400 and the column is not updated.

---



## 11. Income and expenses



### Functional

**FR-TXN-01.** A manager, or an employee with `income / expense`, sees the company's income / expense records. Each record shows source, amount, date, notes, attachment, and delete state.

**FR-TXN-02.** Adding a record requires a source (max 300 characters), a positive amount with max two decimal places, a date, and optional notes (max 1,000 characters). One file may be attached.

**FR-TXN-03.** Creation appends `Created by {name} {surname} (id) at {time}` to `Notes`. Deletion sets `deletedAt` and appends a `Deleted by {name} {surname} (id) at {time}` line. The row after deletion is not displayed in history or used in forecasts. Retrieval clears `deletedAt` and appends a `Retrieved by` line, which restores the row.

**FR-TXN-04.** On the records page a deleted row stays listed where it was but only: source and date stay visible. A record is deleteed permantnly when is older than 6 months, the next transaction-list request deletes the row and its file permanently.

**FR-TXN-05.** The file is stored in the company folder `uploads/income/{company}/` or `uploads/expense/{company}/`) and linked to that row. Allowed types: zip, txt, docx, pdf, jpg, png, xml, csv, json, eml. Maximum size 150 MB.

**FR-TXN-06.** Downloading an attachment requires the matching flag `income` or `expenses`, or the manager role, and the file must belong to the user's company.

### Non-functional

**NFR-TXN-01. Amount / source / notes.** `addIncome.php` and `addExpense.php` validate through `transaction_input_helpers.php`: source with `mb_strlen` against 300; user notes with `mb_strlen` against 1,000; amount must match a positive number with at most two decimal places and fit `DECIMAL(10,2)` (max `999999.99`). Over any limit the response alerts and the row is not inserted. Amount is bound as a string so decimals are not truncated.

**NFR-TXN-05. Attachment.** The income or expense row and the attachment link are handled as an atomic database transaction to ensure data consistency. The file is written in that same step. If any error occurs, a rollback is triggered to maintain atomicity and the new file is unlinked.

**NFR-TXN-02. File name.** `sanitizeAttachmentOriginalName` keeps `basename` only, replaces characters outside `[A-Za-z0-9._-]` with `_`, and stores at most 100 characters. The stored name is prefixed with 16 random bytes in hex, so two uploads of the same original name do not overwrite each other.

**NFR-TXN-03. Lists.** The records query still returns rows with `deletedAt` set, then `maskSoftDeletedIncomeRow` / `maskSoftDeletedExpenseRow` nulls the amount, notes, and attachment flag. Home, history, and forecast queries add `deletedAt IS NULL`. `purgeExpiredSoftDeletedTransactions` runs at the start of a records-list request and `DELETE`s rows whose `deletedAt` is older than `NOW() - INTERVAL 6 MONTH`, then deletes the file.

---



## 12. History and forecasts (Money tracker)



### Functional

**FR-PRED-01.** The user chooses income, expenses, or net income result, for history display or for forecast/s. Results are displayed in a chart (Y year, X months).

**FR-PRED-02.** The user can forecast remaning months or next year. 

**FR-PRED-03.** The user must specify thee years **examined** for the forecast.

**FR-PRED-04.** The user can exclude **current month.** 

**FR-PRED-04.** There is a modal that saves all forecasts of this year. The saved forecasts are cleared after switching / closing the window, the user is warned and have the capability to save the architecture of the .zip is specified in [README](../README.md).

**FR-PRED-05.** Based on a forecast, a new forecast can be calculated. The forecasts that will be used should have been generated from the same model. User can choose from mutliple prev. forecasts. Saved forecasts of the current year can be included as extra training data. 

**FR-PRED-06.** 1st model, `Simple growth-rate forecast`: from monthly history (months with no activity are left out of the average) a growth percentage is applied to income and expenses. The calculation runs in the browser. 

**FR-PRED-04.** 2nd model, `Driver-based forecast`: same as Simple growth-rate forecast, with the difference that user picks income/expense sources of the company and apply growth-percantage for each one. User can search by source name. Also the server serves 10 sources at once, and app shows 5. There is a **Show more** button, that reveales the next 5. This proccess repeats itself if requested. 

**FR-PRED-05.** 3rd model, `Gradient Boost forecast`.

- **Tuning**  
The user chooses a tuning level: Fast (50 Optuna trials), Mid (100), Advanced (200), or Extreme (500). The trial count applies per (income/expense), so net result runs two searches.
- **Pruner** The user chooses a pruner. None lets every trial finish. MedianPruner lets the first 10 trials finish, then stops a later trial whose error is worse than the median of trials so far. Hyperband stops the weaker trials in successive rounds and continues the stronger ones.
- **Time cap**
The user may set a time cap of at least 1 minute. If it is reached before every trial has run, the search stops with the trials that finished.
- **Fit**  
Each chosen model may use up to 1000 trees. Inside each trial, XGBoost adds no further trees after 50 rounds without improvement on the validation fold. 
- **Progress**  
Progress is streamed to the browser as JSON lines and shown on two bars, Optuna and XGBoost, in steps of 10%. The whole forecast is returned when training finishes.
- **Underfit or overfit**
If the selected model underfits or overfits, the user chooses to keep it or to continue tuning while more trials exist (veryy rare case).
- **Cancel**
The user can cancel Gradient Boost forecast training.



### Non-functional

**NFR-PRED-01. History.** Monthly totals are summed in the browser from the year query (`getIncome.php?year=` / `getExpenses.php?year=`). The chart has one value per month.

**NFR-PRED-02. Gradient Boost stream.** `forecastGradientBoost.php` sets `Content-Type: application/x-ndjson`. Python writes progress JSON on stderr. PHP forwards each line as `{"type":"progress","bar","pct","message"}`. The final line is `{"type":"result",...}`. The page reads the body with `res.body.getReader()` and updates the Optuna and XGBoost bars as lines arrive.

**NFR-PRED-03.** **Gradient Boost Python flow.** `forecastGradientBoost.php` builds a JSON payload (plot type, years, trials, pruner, timeout, income/expense rows, training overlays) and runs `src/python/gradient_boost/forecast.py` with `python3` via `proc_open`. The script reads that JSON from stdin. It loads rows, applies overlays, then for each needed side (income and/or expense) builds feature rows (lags 1–3, rolling means, same month in earlier years, historical mean, per-source lags), ++requires++ at least 5 training months, runs Optuna as specified from the user. For minimizing K-fold MAE on `XGBRegressor` (up to 1000 trees, early stop after 50 rounds without improvement), picks a passing model (or the best available with a diagnose flag), fits it, and predicts the target months (values clipped at 0). Net is income − expense. Progress JSON lines go to stderr; the final result JSON goes to stdout.

**NFR-PRED-04. Cancellation.** Leaving the page or pressing cancel calls `abort()` on the fetch. PHP sees `connection_aborted()` and `killGradientBoostProcess` (`posix_kill` / `proc_terminate`). The Python process for that request is not left running.

**NFR-PRED-05. Sources.** `getDriverSources.php` groups `income.Source` or `expenses.source` for the session `companyID` and `deletedAt IS NULL` only. Source search waits 300 ms after the last keystroke, then reloads from the first page.

---



## 13. System as a whole



### Non-functional

**NFR-SYS-01. Environment.** Docker Compose runs `web` (Apache, PHP 8.3, Python 3, Eleventy) and `db` (MySQL 8.0). `init.sql` is mounted on `/docker-entrypoint-initdb.d` and runs only when the `mysql_data` volume is created.

**NFR-SYS-02. Configuration.** `WEB_PORT`, `DB_PORT`, `DB_NAME`, `DB_SERVER_NAME`, `DB_USERNAME`, `DB_PASS`, `APP_BASE_URL`, and `EMAIL_`* are read from `.env`. The application does not embed those secrets in PHP. Email features (verify account, recovery, company request, shift notification) work when SMTP variables are set in `.env`. Without them, the rest of the site still runs. Seed accounts can be used for testing.

**NFR-SYS-03. Data language.** Tables are `utf8mb4` / `utf8mb4_general_ci`, that supports ~any language and makes searching easier.

**NFR-SYS-04. Interface.** HTML pages include `navbar.njk` and `footer.njk`. `docker/entrypoint.sh` runs `npx eleventy`, and Apache serves `/html` from `_site`, so the shared menu is built once.

**NFR-SYS-04. Interface Notifications.** The system uses native js alert instead of built-in modal for notifications.

**NFR-SYS-05. Application Errors.** `logAppError` appends to `logs/appErrorLog.json`. The browser receives a short alert or JSON `errorMsg`. The response does not include the SQL text, a file path, or the MySQL error code.

**NFR-SYS-06. Native Errors.** `display_errors` is Off `docker/php/app.ini` and per-script `ini_set`. PHP warnings, notices, and fatals are written to `logs/php_errors.log` `log_errors` On; `initAppLogging` sets `error_log` to that path. They are not printed in the HTTP response. 

**NFR-SYS-08. Client errors.** `navbar.js` listens for `window` `error` and `unhandledrejection`, then POSTs `{message, source}` to `logClientError.php`. The endpoint accepts POST JSON only, caps message at 2,000 characters and source at 500, and appends the entry to `logs/appErrorLog.json` through `logAppError` with context `client`. The browser does not show an alert for this call. `requestHandler.js` skips the global spinner for that URL.

**NFR-SYS-07. Global spinner.** `requestHandler.js` patches `fetch` and `jQuery.ajax` for GET/POST. It shows a global loading overlay after 700 ms of initiation without response and stays up until every tracked request finishes, with a message stack for nested requests, and disables submit buttons while a request is in flight. Photo upload, search, and Gradient Boost use specific / default  messages, where `logClientError.php` and Gradient Boost skip the auto spinner (Gradient Boost uses its own Optuna/XGBoost bars and cancel control via `window.globalSpinner`). Callers may pass `skipGlobalSpinner` or use `globalSpinner.start` for a manual lock.

**NFR-SYS-09. Helpers.** Shared logic lives in `*_helpers.php` (and `ErrorHandlingHelper.js` on the client), not copied into each endpoint. PHP helpers cover auth/privileges (`auth_helpers.php`), logging and DB-down responses (`log_helpers.php`), rate limits, email verification, account recovery, attachments, soft-delete notes, employee notes, profile photos, and transaction input checks. Endpoints `require_once` the helper they need and call its functions. The browser uses `ErrorHandlingHelper.js` for JSON parsing, 401 redirect to login, 403/error alerts, and connection-failure messages.