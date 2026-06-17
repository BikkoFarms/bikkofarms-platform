# BikkoChain Platform — Monorepo

> **Blockchain-powered agricultural micro-lending for smallholder cocoa and coffee farmers in Ghana.**

A farmer dials `*713*77#` or messages a WhatsApp bot, commits their future harvest as collateral, gets approved in under 2 minutes, and receives GHS directly to their MTN MoMo wallet — powered by Lisk smart contracts.

---

## 📦 Packages

| Package | Description | Stack |
|---|---|---|
| [`bikkofarms-backend/`](./bikkofarms-backend/) | REST API, USSD handler, WhatsApp bot, BullMQ workers | Node.js 20, Express 4, Prisma, Redis |
| [`bikkofarms-contracts/`](./bikkofarms-contracts/) | Smart contracts (HarvestToken, LendingPool, Oracle) | Solidity 0.8.20, Hardhat, OpenZeppelin v5 |
| [`bikkofarms-dashboard/`](./bikkofarms-dashboard/) | Co-op Agent dashboard (loan approval) | React 18, Vite, TanStack Query, shadcn/ui |

---

## 🚀 Quick Start (Local Development)

### Prerequisites
- Node.js 20 LTS
- pnpm 9+
- Docker Desktop

### 1. Clone and Install

```bash
git clone https://github.com/BikkoFarms/bikkofarms-platform.git
cd bikkofarms-platform
pnpm install
```

### 2. Start Infrastructure (PostgreSQL + Redis)

```bash
cd bikkofarms-backend
cp .env.example .env   # fill in your values
docker-compose up -d
```

### 3. Run Database Migrations

```bash
cd bikkofarms-backend
pnpm prisma migrate dev
pnpm prisma db seed    # seeds an admin agent account
```

### 4. Start Backend

```bash
cd bikkofarms-backend
pnpm dev               # starts Express on :3000 with ts-node-dev
```

### 5. Start Dashboard

```bash
cd bikkofarms-dashboard
pnpm dev               # starts Vite on :5173
```

### 6. Expose Webhooks (USSD & WhatsApp)

```bash
ngrok http 3000
# Copy the ngrok URL and set it as:
# - WhatsApp webhook in Meta Developer Console
# - USSD callback URL in Africa's Talking dashboard
```

---

## 🔗 Environment Setup

Copy the template and fill in values:

```bash
cd bikkofarms-backend
cp .env.example .env
```

See [`.ai/context/environment-variables.md`](../BikkoFarms-Website/.ai/context/environment-variables.md) for all variables and their descriptions.

**Critical for development:**
- `AT_USERNAME=sandbox` (Africa's Talking sandbox, not production)
- `LISK_RPC_URL=https://rpc.sepolia-api.lisk.com` (Lisk Sepolia testnet)
- Use Meta test phone numbers for WhatsApp (no business verification needed)

---

## 🧱 Architecture

See full architecture documentation: [`.ai/context/architecture.md`](../BikkoFarms-Website/.ai/context/architecture.md)

**System flow:**
```
Farmer (WhatsApp/USSD)
    → Webhook Handler (Express)
    → Loan Service + Redis Session
    → PostgreSQL (loan stored as PENDING)
    → Agent Dashboard (approval)
    → BullMQ disbursement-queue
    → Lisk Smart Contract (collateral lock)
    → Kotani Pay (USDC → GHS)
    → MTN MoMo / AirtelTigo (farmer receives cash)
```

---

## 🔨 Key Commands

```bash
# Run all tests
pnpm -r test

# Type check all packages
pnpm -r tsc --noEmit

# Lint all packages
pnpm -r lint

# Build all packages
pnpm -r build

# Backend only
pnpm --filter bikkofarms-backend dev
pnpm --filter bikkofarms-backend test

# Contracts only
pnpm --filter bikkofarms-contracts compile
pnpm --filter bikkofarms-contracts test
pnpm --filter bikkofarms-contracts hardhat run scripts/deploy.ts --network liskSepolia

# Dashboard only
pnpm --filter bikkofarms-dashboard dev
```

---

## 📋 MVP Sprint Plan

See [`.ai/context/mvp-sprint-plan.md`](../BikkoFarms-Website/.ai/context/mvp-sprint-plan.md) for the 14-day sprint checklist.

**Current status:** See individual package READMEs for progress.

---

## 🔒 Security

- **Private keys:** Never in `.env` committed to git. Use `.env` locally (gitignored), Render encrypted environment variables in production.
- **Backend wallet:** Signs transactions as relayer. In production: Render Secret env var (encrypted at rest). Phase 2: Doppler for rotation.
- **Webhook verification:** WhatsApp (`X-Hub-Signature-256`) and Kotani Pay (HMAC) both verified on every request.
- **Static analysis:** Slither runs on every PR (see `.github/workflows/ci.yml`).

---

## 🌐 Networks

| Environment | Blockchain | RPC |
|---|---|---|
| Development | Lisk Sepolia (chainId: 4242) | `https://rpc.sepolia-api.lisk.com` |
| Production | Lisk Mainnet (chainId: 1135) | `https://rpc.api.lisk.com` |

**Faucet (testnet ETH/LSK):** https://sepolia-faucet.lisk.com

---

## 📚 Documentation

- [Product Context](./../BikkoFarms-Website/.ai/context/product.md)
- [Architecture](./../BikkoFarms-Website/.ai/context/architecture.md)
- [Database Schema](./../BikkoFarms-Website/.ai/context/database-schema.md)
- [Environment Variables](./../BikkoFarms-Website/.ai/context/environment-variables.md)
- [MVP Sprint Plan](./../BikkoFarms-Website/.ai/context/mvp-sprint-plan.md)
- [AI Engineering Rules](./../BikkoFarms-Website/.ai/rules/agent-rules.md)

---

## 📄 License

Proprietary — BikkoFarms Ltd. All rights reserved.
