# Quality Checklist: Security

Required security checks before merging any pull request.

---

## 🔑 Secrets & Key Scanning
- [ ] No private keys, mnemonic phrases, API tokens, or credentials exist in code commits.
- [ ] Automated git scanning tools (like GitGuardian or GitHub Advanced Security) return clean reports.
- [ ] Environment file examples (`.env.example`) contain placeholders only.

---

## 📦 Dependency Audit
- [ ] Dependency tree scan (e.g. `npm audit` or `snyk`) returns zero high/critical severity security vulnerabilities.
- [ ] No un-vetted, un-maintained packages are added to the package list.
- [ ] Pin version numbers for crucial security/cryptographic modules.

---

## 🛡️ Input Validation & CSP
- [ ] Cross-Site Scripting (XSS) prevention: React elements sanitize user inputs by default; `dangerouslySetInnerHTML` is avoided unless explicitly approved.
- [ ] SQL Injection prevention: Raw query statements parameterized.
- [ ] Content Security Policy (CSP) headers are configured on production servers.
- [ ] Session tokens (JWT) use `httpOnly`, `secure`, and `sameSite: strict` cookie attributes.
