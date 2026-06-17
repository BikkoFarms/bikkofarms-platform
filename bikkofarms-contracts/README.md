# bikkofarms-contracts

Solidity smart contracts for BikkoChain on the Lisk EVM (L2). Handles harvest tokenization (ERC-1155), the lending pool lifecycle, and the admin price oracle.

---

## 🛠️ Stack

| Technology | Purpose |
|---|---|
| Solidity ^0.8.20 | Smart contract language |
| Foundry (forge) | Development, compilation, testing, deployment |
| OpenZeppelin v5 | Base contract libraries |
| Slither | Static security analysis (CI gate) |

---

## 📄 Contracts

### `HarvestToken.sol` (ERC-1155)
Tokenizes future crop harvests as semi-fungible tokens. Each token represents a batch of harvests (e.g. "500kg of Grade-A cocoa, Batch #42") with EPCIS metadata stored on IPFS.

**Key functions:**
- `mint(address to, uint256 id, uint256 amount, string memory uri, bytes memory data)` — `MINTER_ROLE` only
- `uri(uint256 tokenId)` — Returns `ipfs://{CID}` for token metadata
- `safeTransferFrom(...)` — Used to lock collateral into `BikkoLendingPool`

### `BikkoLendingPool.sol` (Upgradeable via TransparentProxy)
Core lending lifecycle management. Wrapped in `TransparentUpgradeableProxy` with 7-day timelock admin.

**Key functions:**
- `registerFarmer(address wallet, string name, string phone, string village)`
- `applyLoan(uint256 loanId, address farmer, uint256 amount, uint256 harvestKg, uint256 collateralTokenId)`
- `approveLoan(uint256 loanId)` — `AGENT_ROLE` only. Emits `LoanApproved`
- `repayLoan(uint256 loanId)` — Releases collateral back to farmer
- `liquidate(uint256 loanId)` — `ADMIN_ROLE` only. Transfers collateral to admin

**Key events:** `LoanCreated`, `LoanApproved`, `LoanRepaid`, `CollateralLiquidated`

### `BikkoOracle.sol` (Admin-Controlled MVP Oracle)
Provides cocoa and coffee USD/kg prices to `BikkoLendingPool`. Updated daily by backend BullMQ cron.

**Key functions:**
- `updateCocoaPrice(uint256 usdCentsPerKg)` — `ORACLE_UPDATER_ROLE` only
- `updateCoffeePrice(uint256 usdCentsPerKg)` — `ORACLE_UPDATER_ROLE` only
- `getCocoaPrice()` — returns current price in USD cents per kg
- `getCoffeePrice()` — returns current price in USD cents per kg
- `lastUpdated()` — timestamp of last price update (48h staleness guard in LendingPool)

> **Note:** Chainlink does NOT have cocoa/coffee feeds on Lisk (as of June 2026). Chainlink integration is Phase 2. See ADR `0002-oracle-strategy.md`.

---

## 🌐 Networks

| Network | ChainId | RPC | Purpose |
|---|---|---|---|
| Lisk Sepolia | 4242 | `https://rpc.sepolia-api.lisk.com` | Development & testing |
| Lisk Mainnet | 1135 | `https://rpc.api.lisk.com` | Production (CTO sign-off required) |

**Testnet faucet:** https://sepolia-faucet.lisk.com

---

## 🚀 Development

```bash
# Install (from monorepo root)
pnpm install

# Compile contracts
forge build

# Run tests
forge test

# Run specific test file (contract)
forge test --match-path test/BikkoLendingPool.t.sol

# Gas report
forge test --gas-report

# Check contract sizes
forge build --sizes

# Run Slither static analysis
pip3 install slither-analyzer
slither src/ --exclude-low --exclude-informational
```

---

## 🚀 Deployment

```bash
# Deploy to Lisk Sepolia testnet
forge script script/Deploy.s.sol --rpc-url liskSepolia --broadcast

# Verify on Blockscout (Lisk Sepolia explorer)
forge verify-contract DEPLOYED_ADDRESS src/BikkoLendingPool.sol:BikkoLendingPool --rpc-url liskSepolia --verifier blockscout --verifier-url https://sepolia-blockscout.lisk.com/api

# Export ABIs to backend (run after any contract change)
# ABIs can be copied from out/ContractName.sol/ContractName.json
cp out/BikkoLendingPool.sol/BikkoLendingPool.json ../bikkofarms-backend/src/config/abis/
```

**After deployment**, update:
1. `bikkofarms-backend/.env` with new contract addresses
2. `bikkofarms-contracts/.env.deployed.sepolia` with addresses + tx hashes
3. Copy ABI files to `bikkofarms-backend/src/config/abis/`

---

## 🔒 Security

- `ReentrancyGuard` on all external state-changing functions in `BikkoLendingPool`
- `Pausable` — admin can halt all lending in emergency
- `SafeERC20` for all USDC transfers
- `AccessControl` roles: `MINTER_ROLE`, `AGENT_ROLE`, `ADMIN_ROLE`, `ORACLE_UPDATER_ROLE`
- Slither must pass **zero high/medium** findings before any deployment
- No mainnet deployment without explicit CTO approval

---

## 🧪 Test Coverage Requirements

| Contract | Coverage Target |
|---|---|
| `HarvestToken.sol` | 100% branch coverage |
| `BikkoLendingPool.sol` | 100% branch coverage |
| `BikkoOracle.sol` | 100% branch coverage |

---

## 🔗 Related Docs

- [**Smart Contract Architecture (Full)**](./ARCHITECTURE.md) — EF-quality design, security analysis, emergency runbook, all diagrams
- [Smart Contract Skill](../../.ai/skills/smart-contract-development.md)
- [Blockchain Integration Skill](../../.ai/skills/blockchain-integration.md)
- [Oracle Strategy ADR](../../.ai/decisions/0002-oracle-strategy.md)
- [Smart Contract Checklist](../../.ai/checks/smart-contract.md)
