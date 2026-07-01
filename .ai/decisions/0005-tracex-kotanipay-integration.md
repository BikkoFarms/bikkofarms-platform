# Architectural Decision Record: 0005-tracex-kotanipay-integration

* **Status:** Accepted
* **Date:** 2026-07-01
* **Author:** John Okyere (CTO)

---

## Context

BikkoChain is shifting its trust model from LBCs (Licensed Buying Companies) to established cocoa cooperatives to address regulatory compliance issues in Ghana (where LBCs are not permitted to issue SEC-regulated warehouse receipts). 

As part of this shift, we must decide on the software components for:
1. **Traceability & Compliance:** Mapping farm plots, capturing crop yields, and logging supply chain events to meet EU Deforestation Regulations (EUDR).
2. **Fintech Settlement:** Swapping stablecoins (USDC) and paying out local fiat (GHS) to MTN MoMo wallets.
3. **Lending Protocol Architecture:** Storing capital on-chain and managing the micro-loan disbursement and repayment lifecycle.

We previously considered zenGate Global's Palmyra platform (with the Cardano-based Winter Protocol) and a custom smart contract lending pool. 

---

## Alternatives Considered

### 1. Traceability & Compliance
- **Option A (Palmyra & Winter Protocol):** Use Palmyra Foundry and the Cardano-native Winter Protocol.
  - *Con:* Cardano uses an eUTXO model, which is incompatible with Lisk's EVM. Porting their Haskell logic to Solidity creates massive R&D overhead.
  - *Con:* Requires using the $PALM utility token for fees, adding currency exchange friction.
- **Option B (TraceX SDK & EVM Anchoring):** Use the TraceX pre-harvest and post-harvest SDK and anchor track-and-trace hashes on Lisk L2.
  - *Pro:* EVM-interoperable out-of-the-box. Has an existing developer SDK for farm management and offline map caching.
  - *Verdict:* Selected.

### 2. Lending Protocol Architecture
- **Option A (Fully Custom Lending Pool):** Deploy `BikkoLendingPool.sol` managing all capital and interest rates from scratch.
  - *Con:* High smart contract audit costs and liability risk for a startup MVP shipping this month.
- **Option B (Direct Morpho Blue Integration):** Integrate our contracts directly with Morpho Blue's permissionless lending pools at launch.
  - *Con:* Bootstrapping a public lending vault and sourcing capital on public markets introduces launch delays.
- **Option C (Private Lisk Vault with Morpho Roadmap):** Deploy `BikkoLendingVault.sol` (a private USDC pool funded directly by our partners) for Phase 1, and deploy a Morpho Blue adapter in Phase 2.
  - *Pro:* Simplifies the MVP launch while maintaining a clear upgrade path to public DeFi markets.
  - *Verdict:* Selected.

---

## Decision

1. **Fintech Settlement:** Standardize on **Kotani Pay v3 API** for stablecoin-to-mobile money swaps.
2. **Traceability:** Integrate the **TraceX Farm Management SDK** for pre-harvest/post-harvest mapping. Anchor TraceX hashes directly on Lisk L2 using our custom `HarvestToken.sol` (Solidity ERC-1155).
3. **Lending:** Implement `BikkoLendingVault.sol` as a private USDC deposit and lending pool. Define `BikkoMorphoAdapter.sol` as a Phase 2 component to bridge custom vaults to permissionless Morpho Blue markets.
4. **Risk Insurance:** Integrate **Pula Advisors Area Yield Index Insurance (AYII)** underwritten by GLICO/GAIP as our Phase 2 default mitigation framework.

---

## Consequences

### Positive
- **Faster Time-to-Market:** Bypassing eUTXO translations and public Morpho pools allows us to ship the USSD/WhatsApp channels and dashboards this month.
- **Improved UX:** Farmers interact only with simple messaging channels, while the backend handles all TraceX and Kotani Pay integrations behind the scenes.
- **No $PALM Friction:** Transactions and fees are paid in native assets (ETH/USDC/GHS), preventing fee volatility for the co-ops.

### Risks & Mitigations
- **Third-Party API Downtime:** If TraceX or Kotani Pay APIs go down, backend calls fail.
  - *Mitigation:* Implement BullMQ retry queues with exponential backoffs and dead-letter alarms.
- **Offline Sync Conflicts:** Co-op agents input data offline and sync later.
  - *Mitigation:* Implement strict database upsert constraints on national IDs and GIS plot boundaries.
