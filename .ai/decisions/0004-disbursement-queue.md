# Architectural Decision Record: 0004-disbursement-queue

* **Status:** Accepted
* **Date:** 2026-06-16
* **Author:** John Okyere (CTO)

---

## Context

When a co-op agent approves a loan, the system must: (1) lock collateral on-chain, (2) approve loan on-chain, (3) transfer USDC to Kotani Pay, (4) initiate mobile money payout. These steps take 10-60 seconds total. The agent dashboard HTTP request cannot wait that long, and failures need automatic retry.

---

## Alternatives Considered

### Option A: Synchronous in HTTP Request Handler
- Run all steps inline in `PUT /loans/:id/approve`
- **Con:** Request timeout after 30s, agent dashboard shows error even on success
- **Con:** No retry logic — transient Kotani/Lisk failures result in stuck loans
- **Verdict:** Rejected

### Option B: Simple setImmediate / setTimeout
- Fire async processing after responding 202
- **Con:** If server crashes, in-flight jobs are lost. No retry.
- **Verdict:** Rejected

### Option C: BullMQ Queue (Redis-backed) ← SELECTED
- Respond 202 immediately, enqueue job, worker processes async
- **Pro:** Survives server crashes (Redis persistence)
- **Pro:** Built-in retry with exponential backoff
- **Pro:** Dead-letter queue + admin alerts on permanent failure
- **Pro:** Observable via Bull Board UI for monitoring
- **Verdict:** Selected

---

## Decision

Use BullMQ `disbursement-queue` for all loan disbursement steps. HTTP handler responds `202 Accepted` immediately. Worker handles: collateral lock → approveLoan on-chain → USDC transfer → Kotani Pay quote → Kotani Pay payout. Retry 5× with exponential backoff (1m, 2m, 4m, 8m, 16m). Dead-letter after 5 failures → Slack/email admin alert.

---

## Consequences

### Positive
- Agent dashboard always gets instant response
- Transient network failures auto-recover
- Full audit trail in Redis/DB

### Risks
- **Status polling:** Agent dashboard needs to poll or use WebSocket to see final loan status (DISBURSED/FAILED). Use TanStack Query with 5s polling interval on the loan detail view.
- **Partial failure:** If loan is approved on-chain but Kotani Pay fails permanently, loan is stuck in APPROVED state. Admin must manually trigger retry or refund. This is handled by the dead-letter admin alert.
