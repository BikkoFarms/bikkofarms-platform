# Context: MVP Sprint Plan (June 2026)

Detailed 2-week sprint plan for the BikkoChain MVP. The goal is to have a working, end-to-end testnet demo by end of Week 2 that real users can test. Sourced from CTO Brief (doc.md v1.0, June 2026).

---

## 🎯 Sprint Goal

**End state:** A farmer can register via WhatsApp or USSD → apply for a loan → a co-op agent approves it on the dashboard → USDC is transferred via Kotani Pay → farmer receives GHS on MTN MoMo wallet → all on Lisk Sepolia testnet.

---

## 📅 Week 1 — Foundation (No Blockchain Needed Yet)

### Day 1–2: Environment Setup

- [ ] Initialize monorepo: `bikkofarms-backend/`, `bikkofarms-contracts/`, `bikkofarms-dashboard/`, `bikkofarms-ussd/`, `bikkofarms-whatsappbot/`
- [ ] `docker-compose.yml` in `bikkofarms-backend/`: PostgreSQL 16 + Redis 7 running locally
- [ ] Prisma schema defined (see `context/database-schema.md`) and first migration run
- [ ] Express server + TypeScript compiling with `ts-node-dev`
- [ ] Basic env config with Zod validation on startup
- [ ] Winston logger configured (structured JSON in production, pretty in dev)
- [ ] Health check endpoint: `GET /health` → `{ status: "ok", timestamp, version }`
- [ ] ngrok documented for webhook testing

### Day 3–4: Smart Contract Skeleton

- [ ] Foundry project configured for Lisk Sepolia (foundry.toml)
- [ ] `HarvestToken.sol` (ERC-1155 + MINTER_ROLE) deployed to Lisk Sepolia testnet
- [ ] `BikkoLendingPool.sol` skeleton with `applyLoan()`, `approveLoan()`, `repayLoan()` deployed
- [ ] `BikkoOracle.sol` (admin-controlled price oracle) deployed
- [ ] `TransparentUpgradeableProxy` wrapping `BikkoLendingPool.sol`
- [ ] Unit tests for all contract functions (Forge)
- [ ] Slither passing zero high-severity warnings
- [ ] Contract addresses saved to `bikkofarms-contracts/.env.deployed`

### Day 5–7: WhatsApp Bot (Most Visible MVP Deliverable)

- [ ] Meta developer account + app + WhatsApp product configured
- [ ] Test phone number added (Meta provides one free for dev)
- [ ] Webhook endpoint `/webhook/whatsapp` live on ngrok, GET challenge passing
- [ ] `X-Hub-Signature-256` verification working
- [ ] Redis session state working: key `whatsapp:session:{phone}`, TTL 24h
- [ ] Full flow: `REGISTER` → collect name/GPS/ID → store in DB → WhatsApp reply confirmation
- [ ] Full flow: `APPLY LOAN` → collect amount/harvest kg → LTV check → store as PENDING → reply with ref
- [ ] Idempotency: duplicate webhook events correctly ignored
- [ ] WhatsApp notification on loan submission

---

## 📅 Week 2 — Core Lending Flow

### Day 8–9: USSD Gateway

- [ ] Africa's Talking account + sandbox short code configured
- [ ] `/webhook/ussd` endpoint: USSD state machine matching WhatsApp flows
- [ ] Session stored in Redis keyed by `sessionId` (not phone)
- [ ] `text` parsing: `text.split('*')` → navigate state machine
- [ ] Main menu: 1. Register, 2. Apply Loan, 3. Check Status
- [ ] Full register flow via USSD simulator on AT dashboard
- [ ] Full loan application flow via USSD simulator
- [ ] All responses return in < 3 seconds (blockchain calls fully async)
- [ ] `END Your transaction is processing...` pattern for async operations

### Day 10–11: Agent Dashboard MVP

- [ ] React + Vite project (`bikkofarms-dashboard/`) bootstrapped
- [ ] Login page with JWT authentication (`POST /api/v1/auth/login`)
- [ ] Pending loans table: farmer name, amount (USDC), harvest kg, LTV%, Approve/Reject buttons
- [ ] `PUT /api/v1/loans/:id/approve` → triggers blockchain + Kotani flow
- [ ] `PUT /api/v1/loans/:id/reject` with reason field
- [ ] Farmer list page with pagination
- [ ] Loading states and error boundaries on all actions
- [ ] TanStack Query for data fetching and cache invalidation

### Day 12–13: Blockchain Integration

- [ ] `BlockchainService.ts`: ethers.js v6 connecting to Lisk Sepolia
- [ ] `HarvestToken.mint()` call on farmer registration
- [ ] `BikkoLendingPool.approveLoan()` call on agent approval
- [ ] `HarvestToken.safeTransferFrom()` to lock collateral on approval
- [ ] Event listener process: sync `LoanApproved`, `LoanRepaid` events to PostgreSQL
- [ ] `BikkoOracle.updatePrice()` daily BullMQ cron job working
- [ ] Transaction receipt polling with 5 retry attempts on timeout

### Day 14: Kotani Pay Integration (Testnet)

- [ ] Register Kotani Pay sandbox account
- [ ] `KotaniService.ts`: `getQuote()` and `createPayout()` API calls
- [ ] Disbursement BullMQ queue: 5 attempts, exponential backoff
- [ ] Webhook handler for `payout.completed` with idempotency
- [ ] Dead-letter queue: admin Slack/email alert on 5th failure
- [ ] WhatsApp confirmation message to farmer after payout
- [ ] End-to-end testnet run: Apply → Approve → USDC transfer → Kotani sandbox → mobile money sandbox

---

## ✅ MVP Definition of Done

A task or feature is complete when:
1. Code compiles with zero TypeScript errors (`strict: true`)
2. Relevant unit/integration tests pass
3. Slither clean (for contracts)
4. Zod validation covers all request inputs
5. Winston logs correctly without leaking secrets
6. Feature tested end-to-end on Lisk Sepolia + AT sandbox + Meta test number
7. PR merged with checklist completed

---

## 🚧 Parallel Tasks (Start Day 1)

These tasks are long-lead bureaucratic items. Start them on Day 1 even though they don't block development:

- [ ] **Africa's Talking Ghana USSD short code application** — submit to MTN Ghana, AirtelTigo, Telecel (takes 2–8 weeks)
- [ ] **Meta WhatsApp Business Verification** — submit business documents to Meta (takes 1–5 days for templates, longer for business verification)
- [ ] **Kotani Pay production API access** — contact Kotani Pay dev support directly
- [ ] **Smart contract audit booking** — contact Quantstamp or Hacken, book audit slot now
- [ ] **Render account + service setup** — create Render Web Service, PostgreSQL, and Redis instances; configure Env Groups for all variables

---

## 📊 Progress Tracking

Update this file daily. Use `[x]` for done, `[/]` for in progress, `[ ]` for not started.
