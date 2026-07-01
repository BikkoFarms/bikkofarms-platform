# Global AI Agent Rules: BikkoChain / BikkoFarms

This document defines the strict rule set that governs all AI coding tools and agents working on this repository. These rules are authoritative — they supersede any model defaults. Updated: 2026-06-16.

---

## 📐 General Code Directives

1. **Never generate code without checking context:**
   Always locate and inspect relevant architecture files under `.ai/context/` and skill guides in `.ai/skills/` before proposing, creating, or editing components.

2. **Simplicity over abstraction — MVP bias:**
   We are shipping an MVP this month. Do not introduce complex design patterns or premature abstractions. Keep implementations simple, straightforward, and directly shippable. When in doubt, choose the simpler path.

3. **Strict TypeScript compilation:**
   Implicit and explicit `any` declarations are strictly banned. Define robust interfaces and utilize Zod for all incoming API inputs/webhook payloads.

4. **Follow existing patterns:**
   Ensure new code conforms to the structures, naming conventions, and file divisions already present in the codebase. Read existing source files before creating new ones.

5. **Monorepo awareness:**
   The platform lives in five packages: `bikkofarms-backend/`, `bikkofarms-contracts/`, `bikkofarms-dashboard/`, `bikkofarms-ussd/`, and `bikkofarms-whatsappbot/`. The public website lives in `bikkofarms-platform/`. Never mix concerns across these boundaries. Run `pnpm` commands with `--filter` when working on specific packages.

---

## 🔒 Security & Reliability Guidelines

6. **Security first:**
   Never output hardcoded keys, passwords, private variables, or configuration secrets. All private keys (especially the backend relayer wallet key) must be read from environment variables. In production, set them as **Render encrypted environment variables** via the Render Dashboard. For Phase 2 rotation and audit, use Doppler. Never commit `.env` files to git.

7. **Webhook signature verification is mandatory:**
   - WhatsApp: always verify `X-Hub-Signature-256` using the `WA_APP_SECRET` env var.
   - Kotani Pay: always verify their HMAC header using `KOTANI_API_SECRET`.
   - Africa's Talking: verify `AT_API_KEY` in request headers.

8. **Webhook idempotency is mandatory:**
   All webhook handlers MUST use the `WEBHOOK_EVENTS` table pattern (upsert by `event_id`, check `processed` flag) to prevent duplicate processing. See `context/database-schema.md` for schema.

9. **Robust error handling:**
   Do not swallow errors. Every async action must have a try/catch with structured Winston logging. Every UI layout must have a React error boundary and loading skeleton.

10. **Verify dependencies before adding them:**
    Do not install external npm modules unless absolutely required. Check existing packages first. Prefer packages already listed in `doc.md` section 3.2.

---

## 🚀 Stack Constraints (Non-Negotiable)

11. **Backend stack is fixed:**
    - Node.js 20 LTS + TypeScript 5 + Express 4 + Prisma ORM
    - BullMQ (NOT `bull` v3/v4 which is deprecated) for Redis-backed job queues
    - `ioredis` for direct Redis access (sessions, USSD state)
    - `ethers` v6 (not v5, not viem) for Lisk smart contract calls in backend
    - `winston` for all logging (never `console.log` in production code)
    - `zod` for all validation schemas
    - `helmet` + `express-rate-limit` on all Express apps

12. **Smart contract stack is fixed:**
    - Solidity `^0.8.20` — no floating pragmas
    - Foundry (forge) — compilation, testing, and deployment scripting
    - OpenZeppelin Contracts v5 for all base contracts
    - Solidity scripts (`script/Deploy.s.sol`) and tests (`test/*.t.sol`) in Solidity
    - MVP Oracle: `BikkoOracle.sol` admin-controlled price oracle — NOT Chainlink (Chainlink has no cocoa/coffee feeds on Lisk)
    - Upgrade pattern: `TransparentUpgradeableProxy` with 7-day timelock on `BikkoLendingVault.sol`

13. **Frontend stack is fixed:**
    - Agent Dashboard: React 18 + Vite + TypeScript + TanStack Query v5 + Tailwind CSS v3 + shadcn/ui
    - Public Website: Next.js (App Router) + TypeScript + Tailwind CSS + shadcn/ui (Radix UI)

14. **Database is fixed:**
    - PostgreSQL 16 (primary store)
    - Redis 7 (session store + BullMQ queues + USSD state cache)
    - IPFS via Pinata (harvest token metadata JSON)

15. **Payment is fixed:**
    - Kotani Pay API v1 for USDC → GHS/KES/UGX off-ramp
    - Circle-bridged USDC on Lisk Mainnet: `0x18eb25a15ec48db3c42a0f41ec0a716ba6b54514`
    - Mobile money targets: MTN MoMo Ghana, AirtelTigo Ghana, M-Pesa Kenya

---

## 📈 Quality Assurance

16. **Co-develop test coverage:**
    Whenever editing or creating API routes, smart contracts, or core hooks, generate matching test scripts alongside. See `skills/testing.md` for standards.

17. **Document architectural shifts:**
    Any changes to core data structures, smart contracts, or system integrations must be documented using an ADR under `.ai/decisions/`. Use the template in `.ai/templates/adr-template.md`.

18. **ARIA & Semantic HTML compliance:**
    All UI elements must be accessible. Correct ARIA attributes and semantic tags are required. Agent dashboard must be tablet-responsive (field inspectors use tablets).

---

## ⚡ MVP Velocity Rules (June 2026)

19. **Ship first, perfect later:**
    The MVP must be live this month. Prefer working code over perfect code. Flag tech debt with `// TODO(MVP-DEBT):` comments but do not block shipping.

20. **Admin oracle for MVP:**
    Use `BikkoOracle.sol` admin-controlled price for cocoa/coffee USD/kg. The backend updates price daily via a BullMQ cron job. Do NOT attempt to integrate Chainlink or RedStone for MVP — it is explicitly out of scope.

21. **USSD short code timing:**
    The AT production short code takes 2–8 weeks of Ghana telco approval. All USSD development MUST use AT sandbox. Begin production short code application on Day 1 in parallel.

22. **WhatsApp production gating:**
    Meta Business Verification for production WhatsApp access takes time. Use Meta test numbers for MVP. Submit business verification paperwork immediately but do not block development.

23. **Use ngrok for local webhook testing:**
    For local development of WhatsApp and USSD webhooks, use ngrok to expose the local Express server. Document the ngrok URL update process in the README.

24. **Docker Compose for local dev:**
    All developers must use the `docker-compose.yml` in `bikkofarms-backend/` to run PostgreSQL 16 + Redis 7 locally. No manual database installations.

---

## 🌐 Environment & Secrets

25. **Environment variables reference:**
    All environment variables are documented in `.ai/context/environment-variables.md`. Never add a new env var without adding it to that file.

26. **Testnet first:**
    All blockchain work targets Lisk Sepolia (chainId: 4242, RPC: `https://rpc.sepolia-api.lisk.com`) until explicitly approved for mainnet. Never deploy to Lisk Mainnet (chainId: 1135) without explicit CTO sign-off.
