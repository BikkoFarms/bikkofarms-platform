# Skill Manual: Dashboard Development

Guidelines for creating reactive, secure, and user-friendly dashboards for cooperatives and administrators.

---

## 🎯 Purpose
To standardise dashboard construction across the platforms, ensuring co-op managers and system administrators can track loans, approve harvest tokens, and monitor payments without delays.

---

## 💡 Best Practices

* **State Separation:** Use Next.js Server Components for initial shell data rendering and Client Components for dynamic filters and interactive actions.
* **Optimistic UI Updates:** Provide instant visual feedback for admin operations (such as approving a loan or updating a farmer profile) while the API network request resolves.
* **Component Reusability:** Build reusable layouts like data tables, filter bars, status indicators, and modal prompts.
* **Status Colors & Badges:** Establish clear states:
  * `Pending` (Amber/Yellow)
  * `Active/Disbursed` (Blue)
  * `Repaid/Completed` (Green)
  * `Overdue/Defaulted` (Red)

---

## 🛑 Constraints

* **Role-Based Views:** Hide or disable actions/pages based on the user's role (Lender, Co-op Agent, Global Admin).
* **Data Refresh Mechanics:** Support cache invalidation and manual re-validation triggers instead of constant polling.
* **Responsive Layouts:** Dashboards must render cleanly on mobile/tablet widths since field inspectors operate on tablets.

---

## 📐 Code Conventions

* **Server Component Shell with Suspense:**
  ```tsx
  // app/dashboard/loans/page.tsx
  import { Suspense } from 'react';
  import { LoanTable } from './_components/LoanTable';
  import { LoanTableSkeleton } from './_components/LoanTableSkeleton';
  
  export default async function LoansPage() {
    return (
      <div className="p-6">
        <h1 className="text-2xl font-bold mb-4">Loan Requests</h1>
        <Suspense fallback={<LoanTableSkeleton />}>
          <LoanTable />
        </Suspense>
      </div>
    );
  }
  ```
* **Strict Loading States:** Every action trigger must display a disabled state and a loading spinner.

---

## ⚠️ Common Pitfalls

* **Client-side Fetching Overhead:** Fetching raw datasets containing thousands of rows to filter them client-side. Offload filtering, sorting, and search querying to database parameters.
* **Session Expiry Collapses:** Dashboard crashing or showing blank fields when a JWT token expires. Wrap application shells in routing middleware verifying session validity.

---

## ✅ Acceptance Criteria

1. **Role Access Control:** Admin dashboards redirect standard cooperative users instantly with error logs.
2. **Visual Consistency:** Status badges use design system HSL mappings.
3. **Table Usability:** Multi-column sorting, textual search, and pagination complete in under 300ms.
