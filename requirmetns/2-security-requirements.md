# 2. Security requirements

Each item states the protection and the mechanism.

## 1. Session

**SEC-SESS-01.** Pages and `/php/` endpoints are closed unless the session has `loggedin = true`. Sign up, login, recovery, and the company request stay public.

**SEC-SESS-02.** A session is created only after `password_verify` succeeds and `emailVerified` is true.

**SEC-SESS-03.** The session cookie has `HttpOnly=true` and `SameSite=Lax`. On HTTPS it has also `session.cookie_secure=true`. The session id is sent only in the cookie.

**SEC-SESS-04.** Logout clears and destroys the session.

**SEC-SESS-05.** When a session is missing - user is sent to the login page with HTTP status code: 401 (Unauthorized).

## 2. Passwords

**SEC-PWD-01.** Passwords are stored with `password_hash` (`PASSWORD_DEFAULT`, bcrypt). 

**SEC-PWD-02.** A new password must be at least 8 characters, and is required to have at least one letter and at least one number. This is checked in PHP and in HTML. 

**SEC-PWD-03.** Deleting an account requires input of the password .

## 3. Tokens

**SEC-TOK-01.** Verification, email-change, recovery, and company-approval tokens are 32 random bytes, stored as 64 hex characters.

**SEC-TOK-02.** A recovery token is single-use and is deleted after a successful change. A new request of the same type replaces the previous token.

**SEC-TOK-03.** Verification and recovery tokens expire after 24 hours. An expired token is rejected.

## 4. Attempt limits

**SEC-RATE-01.** Login, sign up, and recovery counter are incresed pe failure and company-request per action. 

**SEC-RATE-02.** 5 failures inside 15 minutes, block that action for 15 minutes.

<a id="SEC-RATE-03"></a>
**SEC-RATE-03.** Every company-request submission counts, with a limit of 10 in the same 15-minute window.

**SEC-RATE-04.** A successful sign up clears that counter. The counters are stored in `logs/auth_rate_limits.json`, not in a cookie. Each log has {action}, {IP}, and {username} ++or++ {email}, timestamp and time_blocked.

## 5. Authorization

**SEC-AUTHZ-01.** A row in `manager` grants every permission. An employee is allowed only where the matching `privileges` flag is true. A false call returns 403 Forbiden code.

**SEC-AUTHZ-02.** Each endpoint checks the session, the company, and the flag again.

**SEC-AUTHZ-03.** All actions are company and privileges scoped.

## 6. Queries and secrets

**SEC-DB-01.** Values the user sends, such as form fields and query parameters, are passed into SQL through prepared statements. 

**SEC-DB-02.** The database password and the SMTP secret are read from environment variables (`.env`). 

## 7. Files

**SEC-FILE-01.** A transaction file must be at most 150 MB. The type is taken from `finfo` and must be zip, docx, pdf, txt, xml,csv,json,eml jpg, png. Both HTML and PHP check.

**SEC-FILE-03.** A profile photo must be JPEG or PNG, and max 150 MB. 

## 8. Errors

**SEC-LOG-01.** Unexpected errors are written to the server log. The browser does not receive a stack trace or the SQL text.

**SEC-LOG-02.** A known message, such as access denied, is returned as that message to the user. Any other exception becomes a generic error.