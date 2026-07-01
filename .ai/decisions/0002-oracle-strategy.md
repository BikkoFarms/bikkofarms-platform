# Architectural Decision Record: 0002-oracle-strategy

* **Status:** Accepted
* **Date:** 2026-06-16
* **Author:** John Okyere (CTO)

---

## Context

BikkoChain needs current USD/kg prices for cocoa and coffee to calculate loan-to-value ratios (LTV). The smart contract (`BikkoLendingVault.sol`) calls an oracle contract to get these prices at loan application and approval time.

Three options were evaluated for the MVP.

---

## Alternatives Considered

### Option A: Chainlink Price Feeds
- **Pro:** Industry standard, decentralized, manipulation-resistant
- **Con:** Chainlink does **NOT** have cocoa or coffee commodity price feeds on the Lisk network (as of June 2026). Only crypto pairs (ETH/USD, etc.) are available.
- **Con:** Would require Chainlink Functions (custom off-chain computation) — significant additional complexity for MVP
- **Verdict:** Phase 2 option, not MVP

### Option B: RedStone Oracle
- **Pro:** Supports custom data feeds; more flexible than Chainlink for non-crypto commodities
- **Pro:** RedStone is available on Lisk
- **Con:** Requires integration of RedStone's pull model (wrapping transactions with price data) — backend changes to every transaction that reads price
- **Con:** Adds 2-3 weeks of integration effort for MVP timeline
- **Verdict:** Phase 2 fallback option

### Option C: Admin-Controlled Price Oracle (BikkoOracle.sol) ← SELECTED
- **Pro:** Simple, auditable, no external dependencies
- **Pro:** Backend calls `updatePrice(uint256 cocoaUsdPerKg)` daily via BullMQ cron, pulling price from World Bank commodity API or CoinGecko cocoa futures
- **Pro:** Ships in 1 day, unblocks all LTV calculation work
- **Con:** Centralized — team controls the price. Mitigated by: price is public on-chain, any manipulation is transparent, admin key secured via Render encrypted env vars
- **Con:** No automatic failover if backend is down. Mitigated by: price only changes daily, 24h stale price is acceptable for MVP loan volumes
- **Verdict:** Selected for MVP

---

## Decision

Use `BikkoOracle.sol` (admin-controlled) for MVP. Upgrade to Chainlink Functions in Phase 2 when:
1. Chainlink adds cocoa/coffee feeds on Lisk, OR
2. Volume grows to where daily manual updates become a single point of failure risk

---

## BikkoOracle.sol Interface

```solidity
// contracts/BikkoOracle.sol
pragma solidity ^0.8.20;

interface IBikkoOracle {
    function getCocoaPrice() external view returns (uint256 usdCentsPerKg);
    function getCoffeePrice() external view returns (uint256 usdCentsPerKg);
    function updateCocoaPrice(uint256 usdCentsPerKg) external; // onlyRole(ORACLE_UPDATER_ROLE)
    function updateCoffeePrice(uint256 usdCentsPerKg) external; // onlyRole(ORACLE_UPDATER_ROLE)
    function lastUpdated() external view returns (uint256 timestamp);
}
```

Prices are stored as USD cents per kg (e.g., `320` = $3.20/kg) to avoid floating point.

## Staleness Guard

`BikkoLendingVault.sol` checks that the oracle price is not older than 48 hours:

```solidity
require(oracle.lastUpdated() >= block.timestamp - 48 hours, "Oracle price stale");
```

---

## Consequences

### Positive
- MVP unblocked on Day 1
- Price manipulation is publicly visible on-chain (transparent)
- Backend cron job with BullMQ handles daily updates reliably

### Risks & Mitigations
- **Centralization risk:** Admin wallet can set any price. Mitigated by: Render encrypted env var for key management, price updates logged publicly on-chain, Phase 2 Chainlink migration planned.
- **Backend downtime:** If price update cron fails, 48h staleness guard halts new loans. Mitigation: CloudWatch alarm on `price-update-queue` failure, dead-letter admin alert.
