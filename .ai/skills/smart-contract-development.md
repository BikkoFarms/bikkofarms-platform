# Skill Manual: Smart Contract Development

Development guidelines, patterns, and deployment safety measures for Solidity smart contracts on Lisk EVM.

---

## 🎯 Purpose
Define engineering standards for the three core smart contracts of BikkoChain:
- `HarvestToken.sol` — ERC-1155 collateral token (EPCIS metadata, MINTER_ROLE)
- `BikkoLendingPool.sol` — Full loan lifecycle (wrapped in TransparentUpgradeableProxy)
- `BikkoOracle.sol` — Admin-controlled price oracle (MVP; Chainlink in Phase 2)

---

## 💡 Best Practices

* **Use OpenZeppelin Contracts v5:** Inherit battle-tested contracts — `ERC1155`, `AccessControl`, `SafeERC20`, `Pausable`, `ReentrancyGuard`, `TransparentUpgradeableProxy`.
* **Upgrade Pattern — TransparentUpgradeableProxy only for BikkoLendingPool:** `HarvestToken.sol` and `BikkoOracle.sol` are NOT upgradeable. Only `BikkoLendingPool.sol` uses the proxy. 7-day timelock on the proxy admin for mainnet.
* **Events for State Tracking:** Emit events on ALL state changes: `LoanCreated`, `LoanApproved`, `LoanRepaid`, `CollateralLiquidated`, `HarvestTokenized`, `PriceUpdated`. These are indexed to PostgreSQL by `syncEvents.ts`.
* **Admin Oracle for MVP:** `BikkoOracle.sol` uses `updateCocoaPrice(uint256 usdCentsPerKg)` called by `ORACLE_UPDATER_ROLE`. Store prices as USD cents to avoid floating point (e.g. `320` = $3.20/kg). Add 48h staleness guard in `BikkoLendingPool.sol`.
* **Toolchain:** Foundry (forge) as the primary toolchain for compilation, tests, deployment scripting, and fuzzing.

---

## 🛑 Constraints

* **Strict Solidity Version:** Use `pragma solidity ^0.8.20;` exactly — no higher, no ranges.
* **Access Control Roles:** `MINTER_ROLE` (backend wallet), `AGENT_ROLE` (co-op agents), `ADMIN_ROLE` (multisig/CTO), `ORACLE_UPDATER_ROLE` (backend cron wallet).
* **No Floating Pragmas:** Never use `pragma solidity >=0.8.0;` — always exact caret version `^0.8.20`.
* **Lisk Network:** Deploy to Lisk Sepolia (chainId: 4242) for testing, Lisk Mainnet (chainId: 1135) for production. See `context/architecture.md` for foundry.toml.
* **USDC Safety:** Always use `SafeERC20.safeTransfer()` — never `.transfer()` directly on USDC.

---

## 📐 Code Conventions

* **Function Layout Order:**
  * Constructor / Initializers
  * Receive & Fallback functions
  * External functions
  * Public functions
  * Internal functions
  * Private functions
* **Naming Conventions:**
  * Custom modifiers: `only...` (e.g., `onlySupervisor`)
  * State variables: camelCase (e.g., `loanRepaymentDeadline`)
  * Events: UpperCamelCase (e.g., `LoanRepaid`)

---

## ⚠️ Common Pitfalls

* **Arithmetic Underflow/Overflow:** Prior to Solidity 0.8.0, variables could overflow. For newer compilers, do not use `unchecked` blocks unless gas gains are massive and safety is mathematically proven.
* **Locked Ether/Tokens:** Failing to write recovery/withdraw functions for ERC-20 tokens sent accidentally to the contract.
* **Block Timestamp Manipulation:** Avoid using `block.timestamp` for critical cryptographic random sources. It is acceptable for standard loan durations and expiry checks (variation window is small).

---

## ✅ Acceptance Criteria

1. **Slither / Mythril Check:** Automated audits compile with zero high/medium security warnings.
2. **100% Branch Coverage:** Unit tests cover all conditional execution branches.
3. **Optimized Gas Consumption:** Execution gas is tracked and optimized for deployment on the Lisk Layer-2 node.
