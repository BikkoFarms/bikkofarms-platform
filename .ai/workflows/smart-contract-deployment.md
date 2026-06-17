# Workflow: Smart Contract Deployment Process

Procedures for executing safe deployments of BikkoChain contracts to testnets and mainnet.

---

## 🧭 Flow Map
`Verify Code Quality → Configure Keys & RPCs → Dry Run (Fork) → Execute Deploy → Verify on Explorer → Log Addresses`

---

## 🛠️ Step-by-Step Procedure

### 1. Compile & Audit Pre-checks
* Verify that all contract tests pass with 100% coverage.
* Run Slither security analyzer. Prohibit deployments if any high/medium findings are present.

### 2. Set Up Keys & RPC Endpoints
* Store deployment private keys securely. Never commit keys or write them in configuration scripts.
* Fetch the target Lisk Network RPC endpoint URL.

### 3. Dry-Run (Local Simulation)
* Run a local deploy dry-run using Hardhat/Foundry against a local fork of Lisk Sepolia/Mainnet.
* Assert that the contract deploys within gas limits and that initializers configure variables correctly.

### 4. Execute Deploy
* Run the deployment command pointing to the live network target:
  ```bash
  # Example Foundry deploy command
  forge script script/DeployLoanEscrow.s.sol:DeployLoanEscrow --rpc-url $LISK_RPC_URL --broadcast --verify
  ```
* Capture output console transaction hashes and contract deployment addresses.

### 5. Verify on Block Explorer
* Verify contract source code on the Lisk Block Explorer (Blockscout/Etherscan interface) using the compiler metadata options.
* Ensure contract methods are readable and interactive in the explorer UI.

### 6. Address Logging & Registries
* Commit the newly generated contract addresses to the repository index `/docs/architecture/contract-addresses.md` or `.ai/context/architecture.md`.
* Notify backend and frontend developers of the updated addresses and supply the updated ABI files.
