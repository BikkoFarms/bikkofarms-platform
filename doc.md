# BikkoChain — CTO Technical Architecture & Engineering Brief

**Prepared by:** John Okyere (CTO / Founding Engineer)
**Date:** June 2026
**Version:** 1.0
**Audience:** Engineering Team / Antigravity / Technical Partners

---

## 1. Executive Summary

BikkoChain is a blockchain-based agricultural micro-lending platform. A smallholder farmer in Ghana dials a USSD short code or messages a WhatsApp bot, commits their future cocoa/coffee harvest as collateral, receives a loan approval in under 2 minutes, and gets paid to their M-Pesa or MTN MoMo wallet — all powered by Lisk smart contracts and a Node.js/TypeScript backend.

This document covers the complete technical architecture: every layer, every service, every third-party integration, all Mermaid diagrams, technology choices with justifications, and an honest build plan for a 6-month MVP on a lean team.

---

## 2. High-Level System Architecture

```mermaid
graph TB
    subgraph FARMER["Farmer Access Layer"]
        WA["WhatsApp Bot\n(Meta Cloud API)"]
        USSD["USSD Gateway\n(Africa's Talking)"]
    end

    subgraph AGENT["Co-op Agent Layer"]
        DASH["Agent Dashboard\n(React + Vite)"]
    end

    subgraph BACKEND["BikkoChain Backend (Node.js / TypeScript)"]
        API["Express REST API\n:3000"]
        WH["Webhook Handler\n/webhook/whatsapp\n/webhook/ussd\n/webhook/kotani"]
        Q["Bull Queue\n(Redis-backed)\nJob: disbursePayout\nJob: retryPayout\nJob: sendReminder"]
        AUTH["JWT Auth Middleware\n(agent + admin roles)"]
        KYC["KYC Service\n(PostgreSQL, encrypted)"]
        LOAN["Loan Service"]
        TOKEN["Token Service"]
        NOTIFY["Notification Service\n(WhatsApp + SMS)"]
    end

    subgraph DB["Data Layer"]
        PG["PostgreSQL 16\nfarmers, loans,\nwebhook_events,\nkyc_documents"]
        REDIS["Redis 7\nsession store\njob queues\nUSSD state cache"]
        IPFS["IPFS / Pinata\nHarvest token\nmetadata JSON"]
    end

    subgraph CHAIN["Lisk Blockchain Layer (EVM)"]
        HT["HarvestToken.sol\nERC-1155\n(EPCIS metadata)"]
        LP["BikkoLendingPool.sol\n(lock/unlock collateral\nloan lifecycle)"]
        ORC["Chainlink Price Feed\ncocoa/coffee USD/kg\n(fallback: RedStone)"]
    end

    subgraph PAY["Payment & Settlement Layer"]
        KP["Kotani Pay API\nUSDC → GHS/KES/UGX\nMobile Money off-ramp"]
        USDC["Circle Bridged USDC\n0x18eb25a1...b54514\n(Lisk mainnet)"]
        MM["Mobile Money\nMTN MoMo Ghana\nAirtelTigo Ghana\nM-Pesa Kenya"]
    end

    WA -->|POST /webhook/whatsapp| WH
    USSD -->|POST /webhook/ussd| WH
    DASH -->|REST calls| API
    WH --> API
    API --> AUTH
    API --> KYC
    API --> LOAN
    API --> TOKEN
    API --> NOTIFY
    API --> Q
    LOAN --> PG
    KYC --> PG
    KYC --> REDIS
    NOTIFY --> WA
    Q --> KP
    TOKEN --> IPFS
    TOKEN --> HT
    LOAN --> LP
    LP --> ORC
    LP --> USDC
    KP --> MM
    API --> REDIS
```

---

## 3. Detailed Component Breakdown

### 3.1 Farmer Interface

#### 3.1.1 WhatsApp Bot (Meta Cloud API)

**How it actually works:**

Meta's WhatsApp Cloud API (hosted by Meta) is the only production-grade, free-to-access WhatsApp Business API. You do NOT need a Business Solution Provider (BSP) for this — you register directly at [developers.facebook.com](https://developers.facebook.com), create a "Business" type app, add WhatsApp as a product, and get a `PHONE_NUMBER_ID` and a `CLOUD_API_ACCESS_TOKEN`.

**Key facts:**
- All incoming messages are delivered to your server via HTTP POST webhook (JSON payload)
- You verify webhook registration with a `GET` challenge/response on the same endpoint
- To send messages back: `POST https://graph.facebook.com/v20.0/{PHONE_NUMBER_ID}/messages`
- **Conversation window:** You can only send free-form messages within 24 hours of a user-initiated message. After that, you must use pre-approved **Message Templates**
- Templates must be submitted and approved by Meta before use (takes 1–5 days). Critical templates: `loan_approved`, `repayment_reminder`, `loan_disbursed`
- Rate limits: 1,000 messages/second on Cloud API (well above our needs)

**SDK:** Use the official Meta Node.js SDK (`@whatsapp/whatsapp-business-sdk`) or the community-maintained fork `whatsapp-js-sdk`. For production, raw `axios` calls give you the most control.

**Session state management (critical):**
WhatsApp has no native session concept. You build it on Redis:
- Key: `whatsapp:session:{phoneNumber}`
- Value: `{ step: "AWAITING_LOAN_AMOUNT", farmerId: "uuid", tempData: {} }`
- TTL: 24 hours

```mermaid
sequenceDiagram
    participant F as Farmer (WhatsApp)
    participant META as Meta Cloud API
    participant WH as Webhook Handler
    participant REDIS as Redis Session
    participant DB as PostgreSQL
    participant CHAIN as Lisk Smart Contract

    F->>META: "APPLY" (keyword)
    META->>WH: POST /webhook/whatsapp (message event)
    WH->>REDIS: GET session:{phone}
    REDIS-->>WH: null (no session)
    WH->>DB: SELECT farmer WHERE phone=?
    DB-->>WH: farmer record
    WH->>REDIS: SET session:{phone} {step: ASK_AMOUNT}
    WH->>META: POST /messages "How much USDC do you need? (max $X)"
    META->>F: "How much USDC do you need?"

    F->>META: "150"
    META->>WH: POST /webhook/whatsapp
    WH->>REDIS: GET session:{phone}
    REDIS-->>WH: {step: ASK_AMOUNT}
    WH->>REDIS: SET session:{phone} {step: ASK_HARVEST_KG, loanAmount: 150}
    WH->>META: POST /messages "How many kg of cocoa do you expect?"
    META->>F: "How many kg?"

    F->>META: "500"
    META->>WH: POST /webhook/whatsapp
    WH->>CHAIN: calculateLoanAmount(500kg)
    CHAIN-->>WH: maxLoan = $210 USDC
    WH->>DB: INSERT loan {status: PENDING}
    WH->>META: "Loan of $150 submitted. Ref: LOAN-0042. Agent reviewing."
    META->>F: Confirmation message
```

#### 3.1.2 USSD Gateway (Africa's Talking)

**How it actually works:**

Africa's Talking (AT) is the dominant USSD aggregator in Ghana, Kenya, Uganda, and 8+ other African markets. You register at [africastalking.com](https://africastalking.com), buy a USSD short code (e.g., `*713*77#`), and point it to your callback URL.

**Critical mechanics:**
- AT sends a `POST` request to your callback URL on **every user input** (including the first dial)
- Request body is `application/x-www-form-urlencoded` with: `sessionId`, `serviceCode`, `phoneNumber`, `text` (cumulative input, asterisk-separated)
- Your response MUST begin with `CON ` (continue) or `END ` (terminate)
- USSD response must arrive in **under 3 seconds** or the session times out
- Sessions time out after ~180 seconds of no user input (varies by telco)
- In Ghana: MTN, AirtelTigo, Telecel (formerly Vodafone Ghana) — all supported by AT

**State management:**
Parse the `text` field by splitting on `*`. `text=""` = first dial, `text="1"` = selected option 1, `text="1*500"` = selected option 1, then typed 500.

Use Redis to store multi-step state keyed by `sessionId` (AT's session ID, not yours).

```mermaid
sequenceDiagram
    participant F as Farmer (Feature Phone)
    participant TELCO as MTN Ghana
    participant AT as Africa's Talking
    participant WH as USSD Handler
    participant REDIS as Redis

    F->>TELCO: Dials *713*77#
    TELCO->>AT: USSD session initiation
    AT->>WH: POST {sessionId, phone, text=""}
    WH->>REDIS: SET ussd:{sessionId} {step: MAIN_MENU}
    WH-->>AT: "CON Welcome to BikkoChain\n1. Register\n2. Apply for Loan\n3. Check Status"
    AT->>F: Menu displayed

    F->>TELCO: Presses 2
    TELCO->>AT: User input
    AT->>WH: POST {sessionId, phone, text="2"}
    WH->>REDIS: GET ussd:{sessionId}
    WH->>REDIS: SET ussd:{sessionId} {step: LOAN_AMOUNT}
    WH-->>AT: "CON Enter loan amount in USD\n(Max: $200)"
    AT->>F: Input prompt

    F->>TELCO: Types 100
    TELCO->>AT: User input
    AT->>WH: POST {sessionId, phone, text="2*100"}
    Note over WH: Parse text.split("*") → ["2","100"]
    WH->>REDIS: SET ussd:{sessionId} {step: HARVEST_KG, amount: 100}
    WH-->>AT: "CON Enter expected harvest in kg:"
    AT->>F: Input prompt

    F->>TELCO: Types 400
    AT->>WH: POST {sessionId, phone, text="2*100*400"}
    WH->>REDIS: GET ussd:{sessionId}
    Note over WH: Submit loan application
    WH-->>AT: "END Loan of $100 submitted.\nRef: LOAN-0043\nYou will get SMS update."
    AT->>F: Final message (session ends)
```

---

### 3.2 Backend Architecture

**Stack:** Node.js 20 LTS + TypeScript 5 + Express 4 + Prisma ORM

**Folder structure:**

```
bikkochain-backend/
├── src/
│   ├── config/         # env, db, redis, blockchain clients
│   ├── routes/         # Express routers
│   │   ├── webhook.ts  # /webhook/whatsapp, /webhook/ussd, /webhook/kotani
│   │   ├── loans.ts    # CRUD for agent dashboard
│   │   ├── farmers.ts
│   │   └── admin.ts
│   ├── services/
│   │   ├── WhatsAppService.ts   # Meta Cloud API calls
│   │   ├── UssdService.ts       # State machine for USSD menus
│   │   ├── LoanService.ts       # Business logic
│   │   ├── TokenService.ts      # Mint/lock harvest tokens
│   │   ├── KotaniService.ts     # Payout off-ramp
│   │   ├── NotificationService.ts
│   │   └── BlockchainService.ts # ethers.js v6 contract calls
│   ├── queues/
│   │   ├── disbursementQueue.ts # Bull queue, USDC → mobile money
│   │   └── reminderQueue.ts     # Repayment reminders
│   ├── middleware/
│   │   ├── auth.ts         # JWT verification
│   │   ├── idempotency.ts  # Webhook deduplication
│   │   └── rateLimiter.ts
│   ├── prisma/
│   │   └── schema.prisma
│   └── jobs/
│       └── disbursePayout.ts
├── contracts/              # Solidity (separate Hardhat project)
├── docker-compose.yml
└── package.json
```

**Key dependencies:**

| Package | Purpose |
|---|---|
| `express` | HTTP server |
| `@prisma/client` | PostgreSQL ORM |
| `ioredis` | Redis client |
| `ethers` v6 | Lisk smart contract interaction |
| `bull` | Redis-backed job queue |
| `jsonwebtoken` | Agent/admin authentication |
| `axios` | Kotani Pay & Meta API calls |
| `zod` | Request validation |
| `winston` | Structured logging |
| `express-rate-limit` | API rate limiting |
| `helmet` | HTTP security headers |

---

### 3.3 Database Schema (PostgreSQL)

```mermaid
erDiagram
    FARMERS {
        uuid id PK
        string phone_number UK
        string wallet_address
        string name_encrypted
        string national_id_hash
        float gps_lat
        float gps_lng
        float farm_size_ha
        string village
        enum kyc_status
        timestamp created_at
    }

    LOANS {
        uuid id PK
        uuid farmer_id FK
        bigint amount_usdc_cents
        int harvest_kg
        bigint ltv_percent
        int collateral_token_id
        string on_chain_tx_hash
        enum status
        timestamp applied_at
        timestamp approved_at
        timestamp due_date
        timestamp repaid_at
        string kotani_payout_id
        string mobile_tx_id
    }

    HARVEST_TOKENS {
        uuid id PK
        uuid farmer_id FK
        int token_id_on_chain
        string epcis_uri
        string ipfs_metadata_cid
        string crop_type
        float estimated_kg
        bool organic_certified
        string mint_tx_hash
        bool is_locked
        timestamp minted_at
    }

    WEBHOOK_EVENTS {
        uuid id PK
        string event_id UK
        string source
        jsonb payload
        bool processed
        timestamp received_at
    }

    AGENTS {
        uuid id PK
        string email UK
        string password_hash
        string coop_name
        enum role
        timestamp created_at
    }

    FARMERS ||--o{ LOANS : "has"
    FARMERS ||--o{ HARVEST_TOKENS : "owns"
    LOANS ||--|| HARVEST_TOKENS : "collateral"
    AGENTS ||--o{ LOANS : "approves"
```

---

### 3.4 Smart Contract Architecture (Solidity on Lisk)

**Toolchain:** Hardhat + TypeScript, OpenZeppelin v5, ethers v6, Chainlink AggregatorV3Interface

**Lisk network config for `hardhat.config.ts`:**
```typescript
networks: {
  liskSepolia: {
    url: "https://rpc.sepolia-api.lisk.com",
    chainId: 4242,
    accounts: [process.env.PRIVATE_KEY!]
  },
  liskMainnet: {
    url: "https://rpc.api.lisk.com",
    chainId: 1135,
    accounts: [process.env.PRIVATE_KEY!]
  }
}
```

**Important:** Chainlink does NOT have cocoa/coffee price feeds natively. You have two realistic options:
1. **Use Chainlink's commodity feeds** if they exist on Lisk (check [data.chain.link](https://data.chain.link)); otherwise deploy a custom Chainlink Function that pulls from CMC or CoinGecko API for cocoa futures
2. **Use a Tellor or RedStone oracle** as primary, Chainlink as backup — RedStone supports custom data feeds and is more flexible for non-crypto commodity data
3. **Admin-controlled price oracle** (simplest for MVP): a privileged `updatePrice(uint256 cocoaUsdPerKg)` function called by your backend daily using a Chainlink off-chain scheduler

**For MVP, use the admin price oracle.** It's honest, auditable, and avoids oracle dependency complexity in week 1–6.

```mermaid
graph LR
    subgraph CONTRACTS["Smart Contracts (Lisk EVM)"]
        HT["HarvestToken.sol\nERC-1155\nEPCIS metadata\nMINTER_ROLE"]
        LP["BikkoLendingPool.sol\n- registerFarmer()\n- applyLoan()\n- approveLoan()\n- repayLoan()\n- liquidate()"]
        PO["BikkoOracle.sol\n(MVP: admin-controlled)\nupdatePrice()\ngetCocoaPrice()\ngetCoffeePrice()"]
        PROXY["TransparentUpgradeableProxy\n(OpenZeppelin)\n7-day timelock admin"]
    end

    BACKEND["Backend\n(BlockchainService.ts)"] -->|mint()| HT
    BACKEND -->|applyLoan()| LP
    BACKEND -->|approveLoan()| LP
    AGENT["Agent Dashboard"] -->|approveLoan() via backend| LP
    LP -->|getCocoaPrice()| PO
    LP -->|transferFrom farmer → pool| HT
    LP -->|transfer pool → farmer| HT
    BACKEND -->|updatePrice() daily| PO
    PROXY -.->|proxies calls| LP
```

**Contract events to index (for dashboard):**
- `LoanCreated(loanId, farmer, amount)`
- `LoanApproved(loanId)`
- `LoanRepaid(loanId, amount)`
- `CollateralLiquidated(loanId, tokenId)`
- `HarvestTokenized(tokenId, farmer, amount, epcisUri)`

Use `ethers.js` event listeners in a long-running Node.js process to sync these to PostgreSQL.

---

### 3.5 Harvest Token Metadata (EPCIS + EUDR)

Each minted ERC-1155 token's metadata JSON (stored on IPFS via Pinata) must include:

```json
{
  "name": "Cocoa Harvest — Batch #0042",
  "description": "Tokenized future harvest, Tepa district, Ghana",
  "image": "ipfs://Qm...",
  "properties": {
    "farmerId": "0xabc...",
    "gpsCoordinates": { "lat": 6.2345, "lng": -2.3456 },
    "cropType": "cocoa",
    "estimatedKg": 500,
    "harvestSeason": "2026-Q1",
    "organicCertified": true,
    "deforestationFreeProof": "https://eudr-registry.example/proof/0042",
    "epcisEvents": [
      {
        "eventType": "ObjectEvent",
        "action": "ADD",
        "bizStep": "urn:epcglobal:cbv:bizstep:planting",
        "eventTime": "2026-01-15T00:00:00Z",
        "location": "Tepa, Ahafo Region, Ghana"
      },
      {
        "eventType": "ObjectEvent",
        "action": "ADD",
        "bizStep": "urn:epcglobal:cbv:bizstep:harvest_forecast",
        "eventTime": "2026-06-01T00:00:00Z",
        "expectedYieldKg": 500
      }
    ]
  }
}
```

**EUDR compliance note:** The EU Deforestation Regulation (EUDR) — effective December 2024 for large operators — requires geo-polygon evidence of deforestation-free production. For MVP, GPS point + farmer declaration is acceptable. Phase 2 requires integration with Global Forest Watch or Satelligence API for automated polygon verification.

---

### 3.6 Payment Settlement Flow (Kotani Pay)

**How Kotani Pay actually works:**

Kotani Pay provides a REST API to off-ramp USDC (on Lisk and other EVM chains) to mobile money in 8+ African countries including Ghana (MTN MoMo, AirtelTigo), Kenya (M-Pesa), Uganda (MTN, Airtel). You register at [kotanipay.io](https://kotanipay.io), get API keys, and maintain a USDC float in their custody wallet.

**Critical requirement:** You must maintain a USDC balance in your Kotani Pay settlement account. The flow is: your smart contract holds USDC → backend transfers USDC to Kotani Pay's deposit address → Kotani Pay sends local currency to farmer's mobile wallet.

```mermaid
sequenceDiagram
    participant AGENT as Co-op Agent
    participant API as BikkoChain API
    participant LP as LendingPool.sol
    participant USDC as USDC Contract (Lisk)
    participant KP as Kotani Pay API
    participant MM as MTN MoMo / M-Pesa

    AGENT->>API: PUT /loans/:id/approve
    API->>LP: approveLoan(loanId) [ethers.js]
    LP->>LP: emit LoanApproved(loanId)
    LP-->>API: tx confirmed

    API->>USDC: transfer(kotaniDepositAddress, amount) [ethers.js]
    USDC-->>API: tx confirmed

    API->>KP: POST /v1/quotes {fromAsset: USDC, toAsset: GHS, amount}
    KP-->>API: {quoteId, exchangeRate, fee, expiresAt}

    API->>KP: POST /v1/payouts {quoteId, recipient: {type: mobile_money, phone: "+23320...", provider: mtn}}
    KP-->>API: {payoutId, status: PENDING}

    API->>DB: UPDATE loans SET kotani_payout_id=payoutId, status=DISBURSING

    Note over KP,MM: Kotani Pay converts USDC → GHS and sends to farmer

    KP->>API: POST /webhook/kotani {event: payout.completed, payoutId, txRef}
    API->>API: idempotency check: webhook_events table
    API->>DB: UPDATE loans SET status=DISBURSED, mobile_tx_id=txRef
    API->>MM: (already sent by Kotani)
    API->>WA: Send "Your loan of GHS X has been sent to 024XXXXXXX"
```

**Webhook idempotency (critical to implement correctly):**

```typescript
// middleware/idempotency.ts
app.post('/webhook/kotani', async (req, res) => {
  const eventId = req.headers['x-kotani-event-id'] as string;
  
  // Check if we've seen this event
  const existing = await db.webhookEvent.findUnique({ where: { eventId } });
  if (existing?.processed) {
    return res.status(200).json({ status: 'already_processed' });
  }
  
  // Store event immediately (upsert)
  await db.webhookEvent.upsert({
    where: { eventId },
    create: { eventId, source: 'kotani', payload: req.body, processed: false },
    update: {}
  });
  
  // Process...
  await processKotaniWebhook(req.body);
  
  await db.webhookEvent.update({ where: { eventId }, data: { processed: true } });
  res.status(200).send('OK');
});
```

---

### 3.7 Job Queue Architecture (Bull + Redis)

```mermaid
graph LR
    subgraph QUEUES["Bull Queues (Redis)"]
        DQ["disbursement-queue\nPriority: HIGH\nAttempts: 5\nBackoff: exponential"]
        RQ["reminder-queue\nPriority: LOW\nCron: daily 8am Ghana"]
        SQ["sync-queue\nChain event sync\nevery 30s"]
    end

    API -->|job.add| DQ
    API -->|job.add| RQ
    
    DQ -->|worker| KP["Kotani Pay\noff-ramp"]
    RQ -->|worker| WA["WhatsApp\nreminder"]
    SQ -->|worker| CHAIN["Lisk event\nindexer"]

    DQ -->|on fail| DEAD["dead-letter-queue\n(admin alert)"]
```

**Disbursement queue worker logic:**
1. Attempt Kotani Pay payout
2. On failure: exponential backoff (1m, 5m, 15m, 1h, 4h)
3. After 5 failures: move to dead-letter queue, alert admin via email/Slack webhook
4. Admin can manually trigger fallback (bank transfer or cash via agent)

---

### 3.8 Agent Dashboard (React)

**Stack:** React 18 + Vite + TypeScript + TanStack Query + Tailwind CSS + shadcn/ui

**Pages:**

```mermaid
graph TD
    LOGIN["Login\n/login"]
    OVERVIEW["Overview\n/dashboard\nTotal loans, volume, repayment rate"]
    FARMERS["Farmers\n/farmers\nSearch, view, bulk import CSV"]
    PENDING["Pending Loans\n/loans/pending\nApprove / Reject"]
    ACTIVE["Active Loans\n/loans/active\nMonitor, send reminder"]
    PAYOUTS["Payouts\n/payouts\nKotani status, retry"]
    ANALYTICS["Analytics\n/analytics\nVolume chart, default rate"]

    LOGIN --> OVERVIEW
    OVERVIEW --> FARMERS
    OVERVIEW --> PENDING
    OVERVIEW --> ACTIVE
    OVERVIEW --> PAYOUTS
    OVERVIEW --> ANALYTICS
```

**Key API endpoints consumed:**

| Method | Path | Description |
|---|---|---|
| `GET` | `/api/loans?status=pending` | Pending loan queue |
| `PUT` | `/api/loans/:id/approve` | Approve loan (triggers chain tx + payout) |
| `PUT` | `/api/loans/:id/reject` | Reject with reason |
| `GET` | `/api/farmers` | Paginated farmer list |
| `POST` | `/api/farmers/import` | Bulk CSV upload |
| `GET` | `/api/payouts` | Kotani payout statuses |
| `POST` | `/api/payouts/:id/retry` | Manual retry |
| `GET` | `/api/analytics/summary` | Dashboard metrics |

---

## 4. End-to-End Loan Lifecycle

```mermaid
sequenceDiagram
    participant F as Farmer
    participant BOT as WhatsApp/USSD
    participant API as BikkoChain API
    participant DB as PostgreSQL
    participant CHAIN as Lisk Blockchain
    participant AGENT as Co-op Agent
    participant KP as Kotani Pay
    participant MM as Mobile Money

    rect rgb(220, 240, 255)
        Note over F,MM: Phase 1 — Onboarding (one-time)
        F->>BOT: REGISTER
        BOT->>API: POST /farmers {phone, name, gpsLat, gpsLng, nationalId, farmSize}
        API->>DB: INSERT farmer (name_encrypted, national_id_hash)
        API->>CHAIN: registerFarmer(walletAddress, name, phone, village)
        CHAIN-->>API: tx hash
        API->>BOT: "Registration complete! Ref: FARM-0012"
    end

    rect rgb(220, 255, 220)
        Note over F,MM: Phase 2 — Tokenization
        API->>CHAIN: BikkoOracle.getCocoaPrice() → $3.20/kg
        API->>IPFS: Upload metadata JSON (GPS, kg, EPCIS events)
        IPFS-->>API: CID: Qm...
        API->>CHAIN: HarvestToken.mint(farmerWallet, 500kg, ipfsUri)
        CHAIN-->>API: tokenId: 42, tx hash
        API->>DB: INSERT harvest_token {token_id: 42, farmer_id, ipfs_cid}
    end

    rect rgb(255, 245, 220)
        Note over F,MM: Phase 3 — Loan Application
        F->>BOT: "Apply for $150 loan, 500kg harvest"
        BOT->>API: POST /loans {farmerId, amount: 15000, harvestKg: 500, tokenId: 42}
        Note over API: LTV check: 500kg × $3.20 = $1600 × 70% = $1120 max → $150 OK
        API->>DB: INSERT loan {status: PENDING}
        API->>BOT: "Loan #0043 submitted. Agent will review shortly."
        BOT->>F: Confirmation
    end

    rect rgb(255, 220, 220)
        Note over F,MM: Phase 4 — Agent Approval
        AGENT->>API: PUT /loans/0043/approve (JWT authenticated)
        API->>CHAIN: HarvestToken.safeTransferFrom(farmer, lendingPool, tokenId, 1, "")
        CHAIN-->>API: Collateral locked ✓
        API->>CHAIN: BikkoLendingPool.approveLoan(0043)
        CHAIN-->>API: LoanApproved event ✓
        API->>DB: UPDATE loan {status: APPROVED}
    end

    rect rgb(240, 220, 255)
        Note over F,MM: Phase 5 — Disbursement (< 2 min total)
        API->>CHAIN: USDC.transfer(kotaniDepositAddress, 150 USDC)
        API->>KP: POST /v1/quotes {USDC→GHS, 150}
        KP-->>API: {quoteId, rate: 1USDC=15.2GHS}
        API->>KP: POST /v1/payouts {quoteId, phone: "+23324XXXXXX", provider: mtn}
        KP->>MM: Send GHS 2,280 to MTN MoMo
        KP->>API: Webhook: payout.completed
        API->>DB: UPDATE loan {status: DISBURSED}
        API->>BOT: "GHS 2,280 sent to your MTN MoMo! Due date: Sept 15 2026"
        BOT->>F: Payout confirmation
    end

    rect rgb(220, 255, 240)
        Note over F,MM: Phase 6 — Repayment
        F->>MM: Sends repayment via mobile money
        MM->>KP: On-ramp fiat → USDC
        KP->>CHAIN: USDC.transfer(lendingPool, repayAmount)
        API->>CHAIN: BikkoLendingPool.repayLoan(0043)
        CHAIN->>CHAIN: Release HarvestToken back to farmer
        CHAIN-->>API: LoanRepaid event
        API->>DB: UPDATE loan {status: REPAID}
        API->>BOT: "Loan repaid! Your harvest token is released."
    end
```

---

## 5. Security Architecture

### 5.1 Smart Contract Security

| Risk | Mitigation |
|---|---|
| Reentrancy | `ReentrancyGuard` on all external-facing functions |
| Integer overflow | Solidity 0.8.x (built-in overflow protection) |
| Access control | OpenZeppelin `AccessControl` with `MINTER_ROLE`, `AGENT_ROLE`, `ADMIN_ROLE` |
| Upgradeability | `TransparentUpgradeableProxy` (OpenZeppelin) with 7-day timelock |
| Oracle manipulation | Admin-controlled for MVP; add Chainlink + RedStone fallback in Phase 2 |
| Emergency stop | `Pausable` contract — admin can halt all lending |
| Audit | Quantstamp or Hacken before mainnet ($20–30k budgeted) |
| Static analysis | Run Slither + Mythril in CI before every merge |

### 5.2 API Security

- **JWT authentication** for all agent/admin endpoints (HS256, 8h expiry)
- **Webhook signature verification:** WhatsApp signs payloads with `X-Hub-Signature-256`; Kotani Pay uses their own HMAC header — verify both
- **Rate limiting:** `express-rate-limit` — 100 req/15min per IP globally; stricter on `/webhook`
- **Helmet.js** for HTTP security headers
- **Input validation:** `zod` schemas on every incoming request body
- **KYC data encryption:** National ID and name stored encrypted in PostgreSQL using `pgcrypto` (AES-256); only hash stored on-chain

### 5.3 Infrastructure Security

- **Environment variables:** Never commit. Use AWS Secrets Manager or Doppler
- **Private keys:** Backend wallet (for contract calls) stored in AWS KMS or HashiCorp Vault — never in `.env` in production
- **HTTPS only:** Enforce TLS 1.2+ via nginx reverse proxy
- **Database:** PostgreSQL not exposed to internet; VPC private subnet

---

## 6. Infrastructure & Deployment

```mermaid
graph TB
    subgraph AWS["AWS (or GCP) — Production"]
        subgraph VPC["Private VPC"]
            EC2["EC2 t3.medium\nNode.js Backend\n+ Bull workers"]
            RDS["RDS PostgreSQL 16\nMulti-AZ (prod)"]
            CACHE["ElastiCache Redis 7\n(session + queues)"]
        end
        ALB["Application Load Balancer\n+ ACM SSL cert"]
        S3["S3 Bucket\nFrontend static files"]
        CF["CloudFront CDN\nAgent Dashboard"]
        CW["CloudWatch\nLogs + Alarms"]
        SM["Secrets Manager\nAPI keys, DB password,\nwallet private key"]
    end

    INTERNET["Internet"] --> ALB
    ALB --> EC2
    EC2 --> RDS
    EC2 --> CACHE
    EC2 --> SM
    EC2 --> CW
    INTERNET --> CF
    CF --> S3
```

**For weeks 1–8 (development/testnet), use instead:**
- Docker Compose locally: backend + PostgreSQL + Redis all in containers
- Railway.app or Render.com for cheap cloud deployment ($20–50/month)
- Lisk Sepolia testnet for all smart contract work
- ngrok for exposing local webhook endpoints to AT and Meta

**`docker-compose.yml` (dev):**
```yaml
services:
  backend:
    build: .
    ports: ["3000:3000"]
    env_file: .env
    depends_on: [db, redis]
  db:
    image: postgres:16
    environment:
      POSTGRES_DB: bikkochain
      POSTGRES_USER: bikko
      POSTGRES_PASSWORD: dev_password
    ports: ["5432:5432"]
    volumes: ["pgdata:/var/lib/postgresql/data"]
  redis:
    image: redis:7-alpine
    ports: ["6379:6379"]
volumes:
  pgdata:
```

---

## 7. Technology Reference & Official Resources

| Technology | Version | Official Docs | Purpose |
|---|---|---|---|
| Node.js | 20 LTS | [nodejs.org](https://nodejs.org) | Backend runtime |
| TypeScript | 5.x | [typescriptlang.org](https://typescriptlang.org) | Type safety |
| Express | 4.x | [expressjs.com](https://expressjs.com) | HTTP server |
| Prisma | 5.x | [prisma.io/docs](https://www.prisma.io/docs) | ORM |
| PostgreSQL | 16 | [postgresql.org](https://www.postgresql.org) | Primary database |
| Redis | 7 | [redis.io/docs](https://redis.io/docs) | Session + queues |
| Bull | 4.x | [docs.bullmq.io](https://docs.bullmq.io) | Job queues |
| ethers.js | 6.x | [docs.ethers.org](https://docs.ethers.org) | Lisk contract interaction |
| Hardhat | 2.x | [hardhat.org/docs](https://hardhat.org/docs) | Smart contract toolchain |
| OpenZeppelin | 5.x | [docs.openzeppelin.com](https://docs.openzeppelin.com) | Contract libraries |
| Solidity | 0.8.20+ | [soliditylang.org](https://soliditylang.org) | Smart contracts |
| Lisk Testnet RPC | — | `https://rpc.sepolia-api.lisk.com` (chainId: 4242) | Testnet |
| Lisk Mainnet RPC | — | `https://rpc.api.lisk.com` (chainId: 1135) | Mainnet |
| Lisk Sepolia Faucet | — | [sepolia-faucet.lisk.com](https://sepolia-faucet.lisk.com) | Test ETH/LSK |
| Meta Cloud API | v20.0 | [developers.facebook.com/docs/whatsapp](https://developers.facebook.com/docs/whatsapp/cloud-api) | WhatsApp bot |
| Africa's Talking | — | [developers.africastalking.com](https://developers.africastalking.com/docs/ussd) | USSD gateway |
| Kotani Pay | v1 | [docs.kotanipay.io](https://docs.kotanipay.io) | USDC → mobile money |
| Circle USDC (Lisk) | — | Contract: `0x18eb25a15ec48db3c42a0f41ec0a716ba6b54514` | Stablecoin |
| Pinata | — | [docs.pinata.cloud](https://docs.pinata.cloud) | IPFS hosting (metadata) |
| React | 18 | [react.dev](https://react.dev) | Agent dashboard |
| Vite | 5 | [vitejs.dev](https://vitejs.dev) | Frontend build |
| TanStack Query | 5 | [tanstack.com/query](https://tanstack.com/query/latest) | Server state |
| shadcn/ui | — | [ui.shadcn.com](https://ui.shadcn.com) | UI components |
| Tailwind CSS | 3 | [tailwindcss.com](https://tailwindcss.com) | Styling |
| Slither | — | [github.com/crytic/slither](https://github.com/crytic/slither) | Contract static analysis |

---

## 8. Two-Week Sprint Plan (Weeks 1–2 Priority)

Given the 2-week immediate deadline, here is what must be built first, in order:

### Week 1 — Foundation (no blockchain needed yet)

**Day 1–2: Environment setup**
- [ ] Initialize monorepo: `bikkochain-backend/`, `bikkochain-contracts/`, `bikkochain-dashboard/`
- [ ] Docker Compose: PostgreSQL + Redis running locally
- [ ] Prisma schema defined and migrated
- [ ] Express server + TypeScript compiling
- [ ] Basic env config with `zod` validation

**Day 3–4: Smart contract skeleton**
- [ ] Hardhat project configured for Lisk Sepolia
- [ ] `HarvestToken.sol` (ERC-1155) deployed to Lisk Sepolia testnet
- [ ] `BikkoLendingPool.sol` skeleton deployed
- [ ] `BikkoOracle.sol` (admin price oracle) deployed
- [ ] Write unit tests with Hardhat local node

**Day 5–7: WhatsApp bot (most visible deliverable)**
- [ ] Meta developer account + app + WhatsApp product configured
- [ ] Test phone number added (Meta provides one for free for dev)
- [ ] Webhook endpoint `/webhook/whatsapp` live on ngrok
- [ ] Session state in Redis working
- [ ] Full flow: REGISTER → store in DB → reply confirmation
- [ ] Full flow: APPLY LOAN → store in DB as PENDING → reply confirmation

### Week 2 — Core Lending Flow

**Day 8–9: USSD gateway**
- [ ] Africa's Talking account + sandbox short code
- [ ] `/webhook/ussd` endpoint: USSD state machine matching WhatsApp flows
- [ ] Test full loan application via USSD simulator on AT dashboard

**Day 10–11: Agent dashboard MVP**
- [ ] React + Vite project
- [ ] Login page (JWT)
- [ ] Pending loans table: farmer name, amount, LTV, Approve/Reject buttons
- [ ] `PUT /loans/:id/approve` API endpoint

**Day 12–13: Blockchain integration**
- [ ] `BlockchainService.ts`: ethers.js v6 connecting to Lisk Sepolia
- [ ] On loan approve: call `approveLoan()` on contract
- [ ] Mint `HarvestToken` on registration + loan application
- [ ] Event listener: sync chain events to PostgreSQL

**Day 14: Kotani Pay integration (testnet)**
- [ ] Register Kotani Pay sandbox account
- [ ] `KotaniService.ts`: quote + payout API calls
- [ ] Webhook handler for `payout.completed`
- [ ] End-to-end testnet run: Apply → Approve → USDC transfer → Kotani → mobile money (sandbox)

---

## 9. Known Risks & Honest Assessment

| Risk | Realistic Assessment | Mitigation |
|---|---|---|
| **Chainlink cocoa/coffee price feeds on Lisk** | These DO NOT exist yet on Lisk. Using them in the pitch deck is aspirational. | MVP: Admin-controlled price oracle (update daily via backend). Phase 2: Chainlink Functions for custom feeds |
| **Kotani Pay Lisk integration** | Kotani Pay supports Lisk (confirmed on their site) but API docs are sparse. Integration may take longer than expected | Contact Kotani Pay dev support early. Have fallback: manual USDC transfer + agent cash payout |
| **Africa's Talking Ghana USSD** | AT has Ghana coverage but getting a live short code from telcos (MTN Ghana) takes 2–8 weeks of bureaucracy | Use AT sandbox for all development. Begin short code application on Day 1 — it runs in parallel |
| **WhatsApp Business Account approval** | Meta requires Business Verification (business documents) for production access. Sandbox is instant. | Use sandbox (test numbers) for MVP. Submit business verification paperwork immediately |
| **EUDR polygon compliance** | GPS point is not sufficient for full EUDR compliance (needs polygon + satellite verification) | For MVP, GPS point + declaration is acceptable. Flag in docs as "Phase 2 enhancement" |
| **Smart contract audit timeline** | Good audit firms (Quantstamp, Hacken) book 4–6 weeks in advance | Book audit slot now, even before contracts are finished. Use Slither/Mythril for interim security |
| **Winter Protocol / Palmyra adaptation** | Winter Protocol is built for Cardano's eUTXO. Adapting to Lisk EVM is non-trivial | We are NOT porting Winter Protocol. We are re-implementing its data schema in Solidity. The EPCIS metadata is JSON stored on IPFS. This is much simpler and the right call |

---

## 10. Environment Variables Reference

```bash
# Blockchain
LISK_RPC_URL=https://rpc.sepolia-api.lisk.com   # testnet
BACKEND_WALLET_PRIVATE_KEY=0x...                  # DO NOT COMMIT
HARVEST_TOKEN_ADDRESS=0x...
LENDING_POOL_ADDRESS=0x...
ORACLE_ADDRESS=0x...
USDC_ADDRESS=0x18eb25a15ec48db3c42a0f41ec0a716ba6b54514

# Database
DATABASE_URL=postgresql://bikko:password@localhost:5432/bikkochain
REDIS_URL=redis://localhost:6379

# WhatsApp (Meta Cloud API)
WA_PHONE_NUMBER_ID=...
WA_BUSINESS_ACCOUNT_ID=...
CLOUD_API_ACCESS_TOKEN=...
CLOUD_API_VERSION=v20.0
WA_VERIFY_TOKEN=your_random_string_here
WA_APP_SECRET=...   # for signature verification

# Africa's Talking
AT_API_KEY=...
AT_USERNAME=...
AT_SHORTCODE=*713*77#

# Kotani Pay
KOTANI_API_KEY=...
KOTANI_API_SECRET=...
KOTANI_API_URL=https://api.kotanipay.io/v1

# IPFS / Pinata
PINATA_API_KEY=...
PINATA_SECRET_API_KEY=...

# Auth
JWT_SECRET=...   # min 32 chars, random
JWT_EXPIRY=8h

# App
PORT=3000
NODE_ENV=development
LOG_LEVEL=info
```

---

## 11. Testing Strategy

| Layer | Tool | What to test |
|---|---|---|
| Smart contracts | Hardhat + Mocha/Chai | Unit tests for all contract functions; fuzz with Foundry |
| Static analysis | Slither | Run on every PR; zero high-severity issues before mainnet |
| Backend unit | Jest + ts-jest | Services in isolation with mocked DB/chain |
| Backend integration | Supertest | API endpoints with real Docker DB/Redis |
| Webhook idempotency | Jest | Send duplicate event IDs; assert DB state unchanged |
| USSD flows | Manual + AT simulator | All menu paths, edge cases (empty input, invalid numbers) |
| WhatsApp flows | Manual + ngrok | Full conversation flows with test phone number |
| End-to-end | Manual (testnet) | Apply → approve → disburse → repay on Lisk Sepolia |
| Load | k6 | 1000 loan applications/hour; 10k concurrent USSD sessions |

---