# bikkofarms-dashboard

Co-op Agent Dashboard for BikkoChain — approve/reject farmer loan applications, monitor payouts, and manage farmer onboarding.

---

## 🛠️ Stack

| Technology | Purpose |
|---|---|
| React 18 | UI framework |
| Vite 5 | Build tool |
| TypeScript 5 | Type safety |
| TanStack Query v5 | Server state management & polling |
| Tailwind CSS 3 | Styling |
| shadcn/ui | Component library (Radix-based) |
| React Router v6 | Client-side routing |
| Zod | Form validation |

---

## 📁 Folder Structure

```
src/
├── pages/
│   ├── LoginPage.tsx           # JWT login form
│   ├── DashboardPage.tsx       # Overview: metrics, quick actions
│   ├── FarmersPage.tsx         # Farmer list with search + pagination
│   ├── PendingLoansPage.tsx    # Loan approval queue
│   ├── ActiveLoansPage.tsx     # Disbursed + repayment monitoring
│   ├── PayoutsPage.tsx         # Kotani Pay status + retry
│   └── AnalyticsPage.tsx       # Volume charts, default rate
├── components/
│   ├── layout/
│   │   ├── Sidebar.tsx         # Navigation sidebar
│   │   └── DashboardShell.tsx  # Auth wrapper + layout
│   ├── loans/
│   │   ├── LoanTable.tsx       # Data table with status badges
│   │   ├── LoanApprovalModal.tsx # Confirm approve with LTV display
│   │   └── LoanRejectModal.tsx  # Reject with reason
│   ├── farmers/
│   │   ├── FarmerTable.tsx
│   │   └── FarmerCard.tsx
│   └── ui/                     # shadcn/ui components
├── lib/
│   ├── api.ts                  # axios client with JWT interceptor
│   ├── queries/                # TanStack Query hooks
│   │   ├── useLoans.ts
│   │   ├── useFarmers.ts
│   │   └── useAnalytics.ts
│   └── auth.ts                 # JWT storage + refresh logic
└── main.tsx                    # App entry point
```

---

## 🚀 Development

```bash
# Install (from monorepo root)
pnpm install

# Set backend URL
echo "VITE_API_URL=http://localhost:3000" > .env.local

# Start dev server
pnpm dev               # runs on :5173

# Build for production
pnpm build

# Preview production build
pnpm preview
```

---

## 🔗 Backend API Base URL

| Environment | URL |
|---|---|
| Development | `http://localhost:3000` |
| Staging | `https://api-staging.bikkofarms.com` |
| Production | `https://api.bikkofarms.com` |

Set via `VITE_API_URL` environment variable.

---

## 📋 Pages & Routes

| Route | Page | Description |
|---|---|---|
| `/login` | LoginPage | JWT authentication |
| `/dashboard` | DashboardPage | Metrics overview |
| `/farmers` | FarmersPage | Farmer management |
| `/loans/pending` | PendingLoansPage | Loan approval queue |
| `/loans/active` | ActiveLoansPage | Active loan monitoring |
| `/payouts` | PayoutsPage | Kotani payout tracking |
| `/analytics` | AnalyticsPage | Charts and reporting |

All routes except `/login` require valid JWT.

---

## 🎨 Design System

**Status Colors (Tailwind CSS):**
- `Pending` → `bg-amber-100 text-amber-800`
- `Approved / Disbursed` → `bg-blue-100 text-blue-800`
- `Repaid / Completed` → `bg-green-100 text-green-800`
- `Defaulted / Rejected` → `bg-red-100 text-red-800`
- `Disbursing` → `bg-purple-100 text-purple-800`

**UX Patterns:**
- Optimistic UI updates on loan approve/reject (immediate badge change, revert on error)
- TanStack Query 5s polling on active loan view for status updates (disbursement is async)
- Loading skeletons on all data tables
- Confirm modals for destructive actions (approve = irreversible on-chain)

---

## 🧪 Testing

```bash
pnpm test             # Vitest unit tests
pnpm test:e2e         # Playwright E2E (if configured)
```

---

## 🔗 Related Docs

- [Dashboard Skill](../../.ai/skills/dashboard-development.md)
- [API Development Skill](../../.ai/skills/api-development.md)
- [Backend API Reference](../bikkofarms-backend/README.md#api-reference)
