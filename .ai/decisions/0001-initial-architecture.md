# Architectural Decision Record: 0001-initial-architecture

* **Status:** Accepted
* **Date:** 2026-06-15
* **Author:** Senior Full Stack Engineer

---

## Context
BikkoChain requires an accessible, secure, and low-cost microfinance platform that enables coffee and cocoa farmers in Ghana to borrow stablecoins backed by tokenized harvest certificates. Farmers primarily access the system through low-bandwidth channels (USSD and WhatsApp), while cooperatives and liquidity providers use administrative dashboards. We need to define the core frontend, backend, database, and blockchain stack to support these requirements.

---

## Alternatives Considered

1. **Frontend:**
   * *React Single Page App (Vite) + Independent Express Backend:* Great separation of concerns, but lacks out-of-the-box server-side rendering, which is crucial for public landing page SEO.
   * *Next.js (App Router):* (Selected) Combines static-site generation, SEO performance, server-side caching, and structured routing natively.

2. **Backend:**
   * *Express/Fastify (Node.js with TypeScript):* (Selected) Highly performant, huge ecosystem, easy integration with Web3 viem/ethers libraries, and straightforward USSD/WhatsApp webhook handlers.
   * *Go/Python (Django):* Offers good runtime execution speed, but would add language complexity to the team (Node/TypeScript is already used for the frontend).

3. **Blockchain Layer:**
   * *Ethereum Mainnet:* High liquidity but transaction fees ($2.00 - $20.00+) are completely unaffordable for micro-loans ($50.00 - $300.00 value).
   * *Lisk Network:* (Selected) EVM-compatible Layer-2 blockchain with gas fees under $0.01 and rapid block validation. Provides direct access to Ethereum assets while keeping operational costs virtually zero for Ghanaian smallholders.

---

## Decision
Adopt **Next.js (App Router, TS, Tailwind CSS, Radix UI)** for user and cooperative frontends.
Adopt **Node.js (Express, TypeScript, Prisma/Drizzle)** for backend services and gateways.
Adopt **PostgreSQL** as the core relational database.
Adopt **Lisk Network** for collateral tokenization (ERC-721/1155) and loan escrows, integrated via **viem** clients and **Kotani Pay** mobile money rails.

---

## Consequences

### Positive
* **Unified Language:** TypeScript spans from frontend components to API routes and script runs.
* **Low Transaction Cost:** Gas on Lisk is low enough to be easily absorbed by cooperatives or relayer cash balances.
* **Rapid Deployment:** Vercel (frontend) and Render (backend) enable automatic staging and production deploys.

### Risks & Mitigations
* **RPC Dependability:** Public Lisk nodes can experience downtime. 
  * *Mitigation:* Implement RPC client failovers with multiple backup nodes (documented in blockchain skill manuals).
* **USSD Webhook Latency:** USSD carriers drop connections if responses take >3 seconds, but blockchain transactions take longer.
  * *Mitigation:* Queue all transaction relays asynchronously; immediately return pending confirmations to USSD callers.
