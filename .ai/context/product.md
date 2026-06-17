# Product Context: BikkoChain

Full product scope, MVP boundaries, and business goals. Sourced from CTO Technical Architecture Brief (doc.md, v1.0, June 2026).

---

## 🔍 Problem Statement

Smallholder cocoa and coffee farmers in Ghana face severe financial exclusion:

1. **Collateral Deficit:** Traditional banks require real estate, vehicles, or formal salaries as collateral — smallholders have none.
2. **Exorbitant Interest Rates:** Local microfinance charges 40-60%+ APY, trapping farmers in debt cycles.
3. **Delayed Financing:** Agricultural loan cycles take weeks, missing critical windows for fertilizer, seeds, or harvest labor.
4. **Lack of Credit History:** Cash-based operations means no formal credit ratings.

**BikkoChain's Solution:** A blockchain-based agricultural micro-lending platform. A farmer dials a USSD short code or messages a WhatsApp bot, commits their future cocoa/coffee harvest as collateral, receives loan approval in **under 2 minutes**, and gets paid to their MTN MoMo or M-Pesa wallet — all powered by Lisk smart contracts and a Node.js/TypeScript backend.

---

## 🎯 Target Users

### Primary Users (Farmers)
- Smallholder cocoa and coffee farmers in Ghana
- Mostly rural, operating 2-10 acres
- Tech literacy: low-to-medium
- Devices: basic feature phones (USSD) or entry-level smartphones (WhatsApp)
- Target regions: Ashanti, Western, Eastern regions of Ghana

### Secondary Users (Co-op Agents)
- Agricultural cooperative supervisors
- Verify crop conditions, manage farmer onboarding, approve loans via dashboard
- Higher technical literacy, use web dashboards on desktop/tablet
- Role in BikkoChain: approve loan applications, manage farmer KYC, monitor payouts

### Tertiary Users (Liquidity Providers / Admins)
- Institutional or decentralized Web3 investors
- Supply capital to the lending pool
- Managed via admin dashboard with analytics

---

## 💼 Business Goals & Success Criteria

### Business Goals
- Provide competitive interest rates (12-18% APY) vs local 40-60%+
- Onboard 5,000+ farmers in pilot regions within 12 months post-launch
- Default rate under 3% (leverage cooperative verification + oracle pricing)
- **Immediate goal: Ship working MVP this month (June 2026) for user testing**

### MVP Success Criteria
- **Disbursal Speed:** Loan application to mobile money cash-out in under 10 minutes
- **Uptime:** WhatsApp and USSD endpoints respond in < 3 seconds (USSD hard limit)
- **Usability:** 95% task completion rate on USSD/WhatsApp workflows
- **Coverage:** End-to-end testnet run: Apply → Approve → Disburse → Repay on Lisk Sepolia

---

## 📦 Scope of the MVP (This Month)

### ✅ In-Scope for MVP (Must Ship)

1. **Farmer Registration & KYC (via WhatsApp & USSD)**
   - Register: phone number, name (encrypted), GPS coordinates, national ID (hashed), farm size
   - Store in PostgreSQL, register on Lisk smart contract
   - Support languages: English (MVP); Twi and Fante in backlog

2. **Harvest Tokenization**
   - Co-op agent or backend mints ERC-1155 `HarvestToken` after farmer registration
   - Metadata (GPS, kg estimate, crop type, EPCIS events) stored on IPFS via Pinata
   - Token ID tracked in `HARVEST_TOKENS` table

3. **Loan Application (via WhatsApp & USSD)**
   - Farmer specifies loan amount and expected harvest kg
   - LTV check: harvestKg × cocoaPrice × 70% must exceed loan amount
   - Loan stored in PostgreSQL as `PENDING`
   - Farmer receives reference number confirmation

4. **Agent Loan Approval Dashboard**
   - React + Vite web app
   - Login page (JWT)
   - Pending loans table with farmer info, LTV, Approve/Reject buttons
   - `PUT /api/loans/:id/approve` triggers: lock HarvestToken collateral + call `approveLoan()` on chain

5. **Loan Disbursement (Kotani Pay)**
   - On approval: transfer USDC to Kotani Pay → quote → payout to farmer mobile money
   - Webhook idempotency enforced via `WEBHOOK_EVENTS` table
   - WhatsApp notification to farmer on successful disbursement

6. **Repayment Tracking**
   - Farmer repays via mobile money (Kotani Pay on-ramp)
   - `BikkoLendingPool.repayLoan()` releases HarvestToken back to farmer
   - Loan status updated to `REPAID`

7. **Admin Oracle Price Updates**
   - BullMQ daily cron job calls `BikkoOracle.updatePrice(cocoaUsdPerKg)` from backend
   - Price sourced from external commodity API (e.g., World Bank or CMC cocoa futures)

8. **Basic Analytics API**
   - `GET /api/analytics/summary` — total loans, total volume, repayment rate, active farmers

### ❌ Out-of-Scope for MVP

- Chainlink or RedStone oracle integration (no cocoa/coffee feeds on Lisk yet)
- EUDR polygon compliance (GPS point + declaration is acceptable for MVP)
- Decentralized peer-to-peer loan bidding (MVP uses single pooled liquidity)
- AI-assisted crop yield estimation (MVP relies on cooperative physical inspection)
- Cross-border trading integrations
- Native mobile app (WhatsApp + USSD + Web only)
- Smart contract audit (use Slither/Mythril in CI for interim security)
- Multi-language support beyond English for MVP

---

## 🛠️ Feature Roadmap Matrix

| Feature | MVP (This Month) | Phase 2 | Phase 3 |
|---|---|---|---|
| **Harvest NFT Minting** | Co-op/backend initiated | Automated via inspection data | Multi-crop standard |
| **Oracle Pricing** | Admin-controlled (BikkoOracle.sol) | Chainlink Functions custom feed | RedStone fallback |
| **Loan Approval** | Agent dashboard manual approval | Semi-automated risk scoring | Fully automated |
| **Disbursement** | Kotani Pay (USDC → Mobile Money) | Multi-currency expansion | Bank transfer fallback |
| **USSD Interface** | Registration + loan application | Full state recovery | Offline signatures |
| **WhatsApp Bot** | Registration + loan + notifications | Document upload + OCR | AI-assisted support |
| **EUDR Compliance** | GPS point + farmer declaration | Global Forest Watch polygon | Satelligence API |
| **Repayment** | Mobile money on-ramp via Kotani | Automated harvest deductions | Crop buyer split |
| **Dashboard** | Agent loan approval + farmers table | Analytics, bulk CSV import | Liquidity provider portal |
| **Audit** | Slither/Mythril in CI | Quantstamp or Hacken ($20-30k) | Ongoing security reviews |

---

## 🚨 Known Risks

| Risk | Assessment | Mitigation |
|---|---|---|
| Chainlink cocoa/coffee on Lisk | These DO NOT exist. Pitch deck is aspirational. | Admin oracle for MVP. Chainlink Functions in Phase 2. |
| Kotani Pay Lisk integration | Confirmed supported but docs are sparse | Contact dev support early. Fallback: manual USDC + agent cash |
| AT Ghana USSD short code | 2–8 weeks telco bureaucracy | Use AT sandbox for all dev. Apply Day 1 in parallel. |
| WhatsApp Business verification | Meta requires business docs for production | Use test numbers for MVP. Submit verification immediately. |
| Smart contract audit timeline | Good firms book 4–6 weeks ahead | Book audit slot now. Use Slither/Mythril interim. |
| EUDR polygon compliance | GPS point insufficient for full EUDR | Flag as Phase 2. GPS point + declaration acceptable for MVP. |

---

## 💰 Business Model (Context for Engineers)

- **Interest Rate:** 12-18% APY on loan principal (vs 40-60% local)
- **Protocol Fee:** 0.5-1% per loan disbursement (taken before off-ramp)
- **Float Management:** BikkoChain maintains USDC float in Kotani Pay settlement account
- **Liquidity:** Initially from founding team/seed investors; Phase 2 opens to LP pool
