# bikkofarms-backend

Node.js/TypeScript backend API, USSD webhook handler, WhatsApp bot, BullMQ job queues, and blockchain service for BikkoChain.

---

## 🛠️ Stack

| Technology | Purpose |
|---|---|
| Node.js 20 LTS | Runtime |
| TypeScript 5 | Type safety |
| Express 4 | HTTP server |
| Prisma 5 | PostgreSQL ORM |
| ioredis | Redis client |
| BullMQ | Job queues (disbursement, reminders, sync, price update) |
| ethers v6 | Lisk smart contract calls |
| Winston | Structured logging |
| Zod | Request validation |
| Jest + Supertest | Testing |

---

## 📁 Folder Structure

```
src/
├── config/
│   ├── env.ts              # Zod-validated env config
│   ├── db.ts               # Prisma client singleton
│   ├── redis.ts            # ioredis client (shared)
│   ├── logger.ts           # Winston structured logger
│   └── abis/               # Contract ABI JSON files
│       ├── HarvestToken.json
│       ├── BikkoLendingVault.json
│       └── BikkoOracle.json
├── routes/
│   ├── webhook.ts          # POST /webhook/whatsapp, /webhook/ussd, /webhook/kotani
│   ├── loans.ts            # CRUD /api/v1/loans
│   ├── farmers.ts          # CRUD /api/v1/farmers
│   ├── auth.ts             # POST /api/v1/auth/login
│   └── admin.ts            # Admin-only routes
├── services/
│   ├── WhatsAppService.ts  # Meta Cloud API calls + session management
│   ├── UssdService.ts      # USSD state machine
│   ├── LoanService.ts      # Core loan business logic
│   ├── TokenService.ts     # Harvest token minting (Pinata + Lisk)
│   ├── KotaniService.ts    # USDC → Mobile Money off-ramp
│   ├── NotificationService.ts # WhatsApp + SMS notifications
│   ├── BlockchainService.ts   # ethers v6 contract calls
│   └── PinataService.ts    # IPFS metadata storage
├── queues/
│   ├── disbursementQueue.ts  # Kotani Pay payout queue
│   ├── reminderQueue.ts      # Repayment reminder queue (cron)
│   ├── syncQueue.ts          # Lisk event indexer queue
│   └── priceUpdateQueue.ts   # Oracle price update queue (cron)
├── middleware/
│   ├── auth.ts             # JWT verification
│   ├── idempotency.ts      # Webhook deduplication (WEBHOOK_EVENTS table)
│   ├── rateLimiter.ts      # express-rate-limit config
│   └── errorHandler.ts     # Global error middleware
├── jobs/
│   ├── disbursePayout.ts   # Disbursement job processor
│   ├── sendReminder.ts     # Repayment reminder processor
│   ├── syncEvents.ts       # Lisk event indexer processor
│   └── updatePrice.ts      # Oracle price update processor
├── prisma/
│   └── schema.prisma
└── index.ts                # App entry point
```

---

## 🚀 Development

```bash
# Start infrastructure (PostgreSQL + Redis)
docker-compose up -d

# Install deps (from monorepo root)
pnpm install

# Set up database
pnpm prisma migrate dev
pnpm prisma db seed

# Start dev server (hot reload)
pnpm dev

# Health check
curl http://localhost:3000/health
```

---

## 🧪 Testing

```bash
# Run all tests
pnpm test

# Run with coverage
pnpm test --coverage

# Run in watch mode
pnpm test:watch

# Run integration tests only (requires Docker services running)
pnpm test:integration
```

**Test stack:** Jest + ts-jest + Supertest + testcontainers (for DB)

---

## 📋 API Reference

All routes are prefixed with `/api/v1/`.

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/health` | None | Health check |
| `POST` | `/api/v1/auth/login` | None | Agent login → JWT |
| `GET` | `/api/v1/loans` | Agent | List loans (filter by status) |
| `PUT` | `/api/v1/loans/:id/approve` | Agent | Approve loan + trigger disbursement |
| `PUT` | `/api/v1/loans/:id/reject` | Agent | Reject loan with reason |
| `GET` | `/api/v1/farmers` | Agent | Paginated farmer list |
| `POST` | `/api/v1/farmers` | None | Register new farmer |
| `POST` | `/api/v1/farmers/import` | Agent | Bulk CSV import |
| `GET` | `/api/v1/payouts` | Agent | Kotani payout statuses |
| `POST` | `/api/v1/payouts/:id/retry` | Agent | Manual retry payout |
| `GET` | `/api/v1/analytics/summary` | Agent | Dashboard metrics |
| `POST` | `/webhook/whatsapp` | HMAC | WhatsApp incoming messages |
| `POST` | `/webhook/ussd` | AT key | USSD session handler |
| `POST` | `/webhook/kotani` | HMAC | Kotani Pay payout webhooks |

---

## 🐳 Docker Compose (Dev)

```yaml
# docker-compose.yml
services:
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

## 🔗 Related Docs

- [Environment Variables](../../.ai/context/environment-variables.md)
- [Database Schema](../../.ai/context/database-schema.md)
- [Job Queue Skill](../../.ai/skills/job-queue.md)
- [API Development Skill](../../.ai/skills/api-development.md)
- [Kotani Pay Skill](../../.ai/skills/kotani-pay-integration.md)
