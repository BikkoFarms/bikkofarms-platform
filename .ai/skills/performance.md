# Skill Manual: Performance Optimization

Performance guidelines, asset optimization rules, and gas minimization patterns for BikkoChain.

---

## 🎯 Purpose
To keep user-facing systems lightweight, responsive, and cost-effective under resource-constrained scenarios (e.g. mobile networks with low connectivity and high gas costs on-chain).

---

## 💡 Best Practices

* **Next.js Asset Optimizations:**
  * Compress and size images using `next/image` to serve modern formats (WebP/AVIF).
  * Load custom fonts using `next/font` to avoid layout shifts and optimize fetching.
* **Database Query Optimization:**
  * Define explicit indexes for columns frequently queried in `WHERE`, `JOIN`, or `ORDER BY` operations (e.g., `farmer_id`, `status`).
  * Avoid N+1 query patterns. Use ORM-specific relations loading (e.g. `include` or joins).
* **Solidity Gas Tuning:**
  * Keep storage operations (`SSTORE`) to a minimum. Use `memory` or `calldata` references.
  * Structure variables to take advantage of EVM slot packing (256-bit grouping).
  * Use events instead of storing historical transaction structures in contract states.

---

## 🛑 Constraints

* **Maximum JS Bundle Size:** No single page bundle exceeds 100KB (gzipped).
* **API Response Latency:** Target <200ms latency for critical USSD and WhatsApp bot endpoints.
* **Database Connections:** Utilize database pooling with optimized limits to prevent connection pool exhaustion.

---

## 📐 Code Conventions

* **EVM Slot Packing Example:**
  ```solidity
  // Good: Struct variables grouped to pack into a single 256-bit slot
  struct Loan {
      uint128 principal;    // 16 bytes
      uint64 interestRate;  // 8 bytes
      uint32 duration;      // 4 bytes
      uint32 loanTimestamp; // 4 bytes (Total 32 bytes = 1 slot)
      address borrower;     // Takes another slot
  }
  ```
* **Pagination by Default:** Never serve un-paginated list queries. Implement offset-based or cursor-based pagination for all historical transaction lists.

---

## ⚠️ Common Pitfalls

* **Client-Side Heavy Imports:** Importing bulky JS libraries directly on the client rather than dynamic importing or offloading to server execution.
* **Unindexed Foreign Keys:** Missing database indexes on foreign keys (`loan_id` in payment logs), leading to full table scans.
* **Re-fetching Immutable Data:** Constantly calling RPC nodes to read static blockchain parameters instead of caching the parameters locally.

---

## ✅ Acceptance Criteria

1. **Lighthouse Performance Score:** 90+ on desktop, 85+ on mobile.
2. **Gas Efficiency:** Contract deployments and loan creation transactions fall within budgeted gas limits (e.g. <300,000 gas for loan creation).
3. **Cache hit rates:** Static assets are served with appropriate `Cache-Control` headers.
