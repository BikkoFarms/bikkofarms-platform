# Quality Checklist: Blockchain

Required checks before merging smart contracts or Web3 client modules.

---

## 🧪 Unit Testing & Sim
- [ ] Contract test coverage is 100% for all state-changing functions.
- [ ] Reentrancy test scenarios confirm that malicious callers cannot drain funds.
- [ ] Overflow and underflow conditions are verified as safe.

---

## 🔒 Access Control Checks
- [ ] Restricted functions (such as `pause()`, `disburse()`, `updateOracle()`) enforce proper `onlyRole` access rules.
- [ ] Constructor initialization variables check and reject zero-address inputs (`address(0)`).
- [ ] Ownership transfers and role reassignments require multi-step verification.

---

## 📢 Event Validation
- [ ] All state-modifying actions (lock, repay, claim) emit descriptive, indexed events.
- [ ] Event arguments match expected state transition properties precisely.

---

## ⛽ Gas & Efficiency
- [ ] Storage variables pack into 256-bit slots correctly to minimize write gas.
- [ ] Heavy calculations use `memory` or `calldata` arrays to avoid redundant storage loads.
- [ ] Gas costs are logged for each transaction flow in test reports.
