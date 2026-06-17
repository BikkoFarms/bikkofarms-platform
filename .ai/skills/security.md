# Skill Manual: Security & Risk Management

Guidelines for writing secure application logic, protecting financial transaction pipelines, and securing the smart contract state.

---

## 🎯 Purpose
To prevent exploits, financial losses, data leaks, and access control breaches across the BikkoChain blockchain infrastructure and backend API interfaces.

---

## 💡 Best Practices

* **Access Control:** Enforce Role-Based Access Control (RBAC) across both API controllers and smart contracts. Use OpenZeppelin's `AccessControl` or `Ownable` contracts for Solidity.
* **Input Validation & Sanitization:** Validate all incoming requests on the backend using schema verification libraries (e.g. Zod or Joi). Sanitize input parameter strings before executing queries.
* **Reentrancy Protection:** Apply OpenZeppelin's `ReentrancyGuard` to all state-changing external functions in contracts. Always follow the **Checks-Effects-Interactions** pattern.
* **Secrets Management:** Keep API keys, private keys, database credentials, and seed phrases in secure environment stores (`.env.local` locally, Render encrypted environment variables in production, Doppler for rotation in Phase 2).

---

## 🛑 Constraints

* **Zero Plaintext Secrets:** Never hardcode secrets, private keys, or API tokens in the code repository.
* **No Inline SQL Queries:** Always run parameterised queries or ORM calls to prevent SQL injection vulnerabilities.
* **Safe Math & Overflow Controls:** Use Solidity 0.8+ which features native overflow checking.
* **Strict CORS & CSP Policies:** Enforce restrictive Content Security Policy headers on the Next.js frontend and precise CORS access rules on backend microservices.

---

## 📐 Code Conventions

* **Checks-Effects-Interactions Pattern (Solidity):**
  ```solidity
  function claimRepayment(uint256 loanId) external nonReentrant {
      // 1. Checks
      Loan storage loan = loans[loanId];
      require(msg.sender == loan.lender, "Unauthorized");
      require(loan.state == State.Repaid, "Not repaid");
      
      // 2. Effects
      loan.state = State.Closed;
      
      // 3. Interactions
      token.safeTransfer(msg.sender, loan.repaymentAmount);
  }
  ```
* **Strict Typecasting & Parsers:** Avoid using parsing functions that fail silently. Use explicit parsers that throw validation errors upon malformed inputs.

---

## ⚠️ Common Pitfalls

* **Tx.origin Vulnerability:** Using `tx.origin` for authentication in contracts instead of `msg.sender`.
* **Exposing Git Configs/Envs:** Accidental inclusion of `.env` files in git tracking. (Enforced by `.gitignore`).
* **Unchecked Return Values:** Failing to verify return states on ERC-20 token transfers. Always use OpenZeppelin's `SafeERC20` wrapper library (`safeTransfer`).

---

## ✅ Acceptance Criteria

1. **Security Scans Passing:** Zero high or medium severity findings on automated security analysis tools (Slither for contracts, Snyk/npm audit for Node dependencies).
2. **Access Control Checklists:** All admin-restricted functions trigger revert transactions when invoked by an unauthorized signer.
3. **No Key Leaks:** Repository scan passes automated secrets scanners (like GitGuardian or GitHub Advanced Security) with clean status.
