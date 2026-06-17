# Quality Checklist: Smart Contract

Required checks before merging smart contract changes or deploying to any network.

---

## 🔒 Security (Zero Tolerance)

- [ ] `ReentrancyGuard` applied to ALL external state-changing functions in `BikkoLendingPool.sol`
- [ ] Checks-Effects-Interactions pattern strictly followed in every function
- [ ] `SafeERC20.safeTransfer()` used for all ERC-20 (USDC) transfers — never `.transfer()` directly
- [ ] `AccessControl` roles configured: `MINTER_ROLE`, `AGENT_ROLE`, `ADMIN_ROLE`, `ORACLE_UPDATER_ROLE`
- [ ] `Pausable` implemented — admin can halt all lending in emergency
- [ ] No use of `tx.origin` for authentication — always `msg.sender`
- [ ] No floating pragma (`pragma solidity ^0.8.20;` exactly — never `>=`)
- [ ] `unchecked` blocks only used with mathematical proof that overflow is impossible

---

## 🧪 Testing

- [ ] 100% branch coverage on all financial functions (`applyLoan`, `approveLoan`, `repayLoan`, `liquidate`)
- [ ] Unit tests cover: happy path, all revert cases, reentrancy attack simulation
- [ ] Fuzz tests written for numeric inputs (loan amounts, harvest kg, prices)
- [ ] Tests run on Hardhat local node only — no Lisk Sepolia in unit test suite

---

## 🔍 Static Analysis

- [ ] `slither contracts/ --exclude-low --exclude-informational` passes with ZERO high/medium findings
- [ ] Mythril scan run: `myth analyze contracts/BikkoLendingPool.sol --max-depth 10`
- [ ] OpenZeppelin contract versions pinned (not floating) in `package.json`

---

## 📋 Events & Indexing

- [ ] All state changes emit events: `LoanCreated`, `LoanApproved`, `LoanRepaid`, `CollateralLiquidated`, `HarvestTokenized`
- [ ] Event indexer in `bikkofarms-backend/src/jobs/syncEvents.ts` handles all emitted events
- [ ] Events include sufficient data for full dashboard reconstruction without DB dependency

---

## 🚀 Deployment Safety

- [ ] Deploy to Lisk Sepolia FIRST and test end-to-end before any mainnet consideration
- [ ] Contract addresses saved to `bikkofarms-contracts/.env.deployed.sepolia` (or `.mainnet`)
- [ ] `TransparentUpgradeableProxy` used for `BikkoLendingPool.sol` — NOT for `HarvestToken.sol` or `BikkoOracle.sol`
- [ ] 7-day timelock configured on proxy admin for mainnet
- [ ] ABI files exported from Hardhat and copied to `bikkofarms-backend/src/config/abis/`
- [ ] Deployment script (`scripts/deploy.ts`) is idempotent and logs all addresses

---

## 📝 Code Quality

- [ ] Solidity NatSpec comments on all public/external functions
- [ ] Function layout order: constructor → receive/fallback → external → public → internal → private
- [ ] Gas optimization: struct variables packed into 256-bit slots where possible
- [ ] No infinite loops or unbounded iteration over arrays
