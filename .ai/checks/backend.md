# Quality Checklist: Backend

Required checks before merging backend APIs, middleware, or database changes.

---

## 🧪 Automated Testing
- [ ] Unit and integration test suites pass locally and in CI environment.
- [ ] Code statement test coverage meets or exceeds the 85% requirement.
- [ ] External calls (databases, remote RPC nodes, SMS providers) are mocked in tests.

---

## 🛡️ Input Validation & Parsing
- [ ] All request payloads (`req.body`, `req.query`, `req.params`) are parsed against strict Zod/Joi schemas.
- [ ] Database variables are parameterized. Direct string concatenations are banned.
- [ ] Numeric values (like loan amounts, interest rates) check boundary limits (no negative inputs).

---

## 🚨 Error Handling & Stability
- [ ] Controller functions wrap async statements in try/catch handlers.
- [ ] Centralized error mapping middleware parses internal errors into sanitized JSON responses.
- [ ] No database schema errors or raw trace exceptions are exposed in client responses.

---

## 📝 Logging & Diagnostics
- [ ] System events (e.g. loan approval, transaction start) write clear diagnostic logs.
- [ ] No passwords, private keys, session tokens, or farmer identities are printed in plaintext logs.
