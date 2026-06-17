# Architectural Decision Record: 0003-monorepo-structure

* **Status:** Accepted
* **Date:** 2026-06-16
* **Author:** John Okyere (CTO)

---

## Context

BikkoChain has three distinct codebases: a Node.js/Express backend, Hardhat smart contracts, and a React dashboard. Additionally, the public marketing website (bikkofarms-platform) is a separate Next.js app. We need to decide how to organize these repositories.

---

## Alternatives Considered

### Option A: Single Monorepo (all in one repo)
- **Pro:** Single PR, unified CI/CD, easy cross-package imports
- **Con:** Dashboard and backend have completely different deploy targets; Next.js website has different concerns entirely
- **Con:** Mixing blockchain toolchain (Hardhat, Foundry) with web toolchain causes dependency conflicts
- **Verdict:** Too much coupling for the team's needs

### Option B: Fully Separate Repositories (4 repos)
- **Pro:** Complete isolation, each team member owns their repo
- **Con:** Coordination overhead, no shared types, cross-repo PRs for connected changes
- **Verdict:** Too much friction for a lean startup team

### Option C: Two Repositories (platform monorepo + public website) ← SELECTED
- **Platform monorepo** (`bikkofarms-platform/`): backend + contracts + dashboard using pnpm workspaces
- **Public website** (`bikkofarms-platform/`): standalone Next.js app, separate deploy pipeline
- **Pro:** Connected codebases share types and can be changed in one PR; website is independent
- **Pro:** pnpm workspaces handles shared TypeScript types (`packages/shared-types/`)
- **Verdict:** Selected

---

## Decision

**Repository 1:** `bikkofarms-platform/` — pnpm monorepo with:
- `bikkofarms-backend/` — Express API
- `bikkofarms-contracts/` — Hardhat/Solidity
- `bikkofarms-dashboard/` — React/Vite
- `packages/shared-types/` — Shared TypeScript interfaces (Loan, Farmer, etc.)

**Repository 2:** `bikkofarms-platform/` — standalone Next.js public site

---

## Package Manager

Use **pnpm** (not npm or yarn) for the platform monorepo:
- `pnpm-workspace.yaml` defines `bikkofarms-*` and `packages/*` as workspace packages
- Run `pnpm --filter bikkofarms-backend dev` to run individual packages
- Run `pnpm -r build` to build all packages

---

## Shared Types

```typescript
// packages/shared-types/src/index.ts
export interface Farmer { id: string; phoneNumber: string; kycStatus: KycStatus; }
export interface Loan { id: string; farmerId: string; amountUsdcCents: bigint; status: LoanStatus; }
export type KycStatus = 'UNVERIFIED' | 'PENDING' | 'VERIFIED' | 'REJECTED';
export type LoanStatus = 'PENDING' | 'APPROVED' | 'DISBURSING' | 'DISBURSED' | 'REPAID' | 'DEFAULTED' | 'LIQUIDATED' | 'REJECTED';
```

---

## Consequences

### Positive
- Single `pnpm install` sets up entire platform
- Shared TypeScript types prevent API contract drift between backend and dashboard
- Independent CI pipelines per package but triggered from single repo

### Risks & Mitigations
- **Hardhat vs Vite dependency conflicts:** Use `pnpm`'s strict hoisting to prevent conflicts
- **Circular dependencies:** `shared-types` must only contain pure types — no runtime dependencies
