# Skill Manual: Blockchain Integration (Backend)

Rules for communicating with the Lisk L2 network via ethers.js v6, reading chain states, and relaying EVM transactions from the Node.js backend.

---

## 🎯 Purpose

The `BlockchainService.ts` is the single point of contact between the Express backend and the Lisk EVM. It handles minting harvest tokens, approving/repaying loans, locking/releasing collateral, updating oracle prices, and listening to on-chain events.

---

## 🔑 Key Facts

- **Library:** ethers.js v6 (NOT v5, NOT viem — ethers v6 is specified in doc.md)
- **Network (dev):** Lisk Sepolia — `https://rpc.sepolia-api.lisk.com` (chainId: 4242)
- **Network (prod):** Lisk Mainnet — `https://rpc.api.lisk.com` (chainId: 1135)
- **Backend wallet:** Signs transactions as the relayer. Key set as Render encrypted env var in production; plain env var for local dev.
- **USDC contract (mainnet):** `0x18eb25a15ec48db3c42a0f41ec0a716ba6b54514`

---

## 💡 Best Practices

* **ethers.js v6 API differences from v5:**
  - `ethers.providers.JsonRpcProvider` → `new ethers.JsonRpcProvider(url)`
  - `ethers.Wallet` still works the same
  - `BigNumber` → native JavaScript `BigInt`
  - `ethers.utils.parseUnits(...)` → `ethers.parseUnits(...)`
  - `contract.method()` returns a Promise — always `await` and check `.hash`

* **Failover RPC:** Always configure a fallback RPC using ethers `FallbackProvider`:
  ```typescript
  const provider = new ethers.FallbackProvider([
    new ethers.JsonRpcProvider(process.env.LISK_RPC_URL!),
    new ethers.JsonRpcProvider(process.env.LISK_BACKUP_RPC_URL!),
  ]);
  ```

* **Gas estimation:** Call `contract.method.estimateGas()` before sending. Apply 1.2× multiplier.

* **Transaction confirmation:** Always await `.wait(1)` to confirm at least 1 block. Check `receipt.status === 1`.

* **Nonce management:** For high-throughput (multiple tx from same wallet), track nonce in Redis to prevent stuck transactions.

* **Event indexing:** Use `contract.on('EventName', handler)` in a persistent long-running process (`syncEvents.ts`). Store confirmed events to PostgreSQL immediately.

---

## 📐 Code Conventions

### BlockchainService.ts Structure

```typescript
// services/BlockchainService.ts
import { ethers } from 'ethers';
import { HarvestTokenABI } from '../config/abis/HarvestToken';
import { BikkoLendingPoolABI } from '../config/abis/BikkoLendingPool';
import { BikkoOracleABI } from '../config/abis/BikkoOracle';

export class BlockchainService {
  private provider: ethers.FallbackProvider;
  private signer: ethers.Wallet;
  private harvestToken: ethers.Contract;
  private lendingPool: ethers.Contract;
  private oracle: ethers.Contract;

  constructor() {
    this.provider = new ethers.FallbackProvider([
      new ethers.JsonRpcProvider(process.env.LISK_RPC_URL!),
      new ethers.JsonRpcProvider(process.env.LISK_BACKUP_RPC_URL!),
    ]);
    this.signer = new ethers.Wallet(process.env.BACKEND_WALLET_PRIVATE_KEY!, this.provider);
    this.harvestToken = new ethers.Contract(process.env.HARVEST_TOKEN_ADDRESS!, HarvestTokenABI, this.signer);
    this.lendingPool = new ethers.Contract(process.env.LENDING_POOL_ADDRESS!, BikkoLendingPoolABI, this.signer);
    this.oracle = new ethers.Contract(process.env.ORACLE_ADDRESS!, BikkoOracleABI, this.signer);
  }

  async mintHarvestToken(
    farmerWallet: string,
    amountKg: number,
    ipfsUri: string
  ): Promise<{ tokenId: number; txHash: string }> {
    const tx = await this.harvestToken.mint(farmerWallet, amountKg, 1, ipfsUri, '0x');
    const receipt = await tx.wait(1);
    if (receipt.status !== 1) throw new Error(`Mint tx failed: ${tx.hash}`);
    
    // Parse tokenId from HarvestTokenized event
    const event = receipt.logs
      .map((log: ethers.Log) => {
        try { return this.harvestToken.interface.parseLog(log); } catch { return null; }
      })
      .find((e: any) => e?.name === 'HarvestTokenized');
    
    return { tokenId: Number(event.args.tokenId), txHash: tx.hash };
  }

  async approveLoan(loanId: string): Promise<string> {
    const tx = await this.lendingPool.approveLoan(loanId);
    const receipt = await tx.wait(1);
    if (receipt.status !== 1) throw new Error(`ApproveLoan tx failed: ${tx.hash}`);
    return tx.hash;
  }

  async lockCollateral(tokenId: number, farmerWallet: string): Promise<string> {
    const tx = await this.harvestToken.safeTransferFrom(
      farmerWallet,
      process.env.LENDING_POOL_ADDRESS!,
      tokenId,
      1,
      '0x'
    );
    const receipt = await tx.wait(1);
    if (receipt.status !== 1) throw new Error(`LockCollateral tx failed: ${tx.hash}`);
    return tx.hash;
  }

  async updateOraclePrice(cocoaUsdCentsPerKg: bigint, coffeeUsdCentsPerKg: bigint): Promise<void> {
    const tx1 = await this.oracle.updateCocoaPrice(cocoaUsdCentsPerKg);
    await tx1.wait(1);
    const tx2 = await this.oracle.updateCoffeePrice(coffeeUsdCentsPerKg);
    await tx2.wait(1);
  }
}
```

---

## 🛑 Constraints

* **Never store private keys in code or logs.** Log only wallet address, never private key.
* **Transaction nonce:** For concurrent transactions, lock nonce updates in Redis to avoid duplicate nonce errors.
* **Gas limit:** Set explicit `gasLimit` on all transactions. Start with `300_000n` for `approveLoan`, `200_000n` for `mint`. Tune down after profiling.
* **Revert parsing:** Use `ethers.isCallException(error)` to detect contract reverts and extract the revert reason for logging.
* **ABI files:** Export ABIs from Hardhat artifacts (`artifacts/contracts/ContractName.sol/ContractName.json`) and copy to `bikkofarms-backend/src/config/abis/` after each contract change.

---

## ⚠️ Common Pitfalls

* **ethers v5 vs v6 API confusion:** v6 has breaking changes. Always reference v6 docs: https://docs.ethers.org/v6/
* **Awaiting tx.wait() inside USSD handler:** USSD must respond in <3s. NEVER await blockchain tx inside a USSD/WhatsApp webhook — always enqueue via BullMQ.
* **Missing receipt status check:** `tx.wait()` resolves even if the tx reverted. Always check `receipt.status === 1`.
* **ABI mismatch:** If contract is redeployed with changed interface, update the ABI file in backend immediately or all calls will fail silently.

---

## ✅ Acceptance Criteria

1. `BlockchainService.ts` connects to Lisk Sepolia on startup and logs wallet address
2. `mintHarvestToken()` returns tokenId and txHash on success
3. Failed transactions (reverts) throw with the revert reason extracted
4. Event listener (`syncEvents.ts`) syncs `LoanApproved` and `LoanRepaid` to DB within 60 seconds of emission
5. Zero private keys appear in Winston logs or error traces
