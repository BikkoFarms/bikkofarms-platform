# Skill Manual: Job Queue Architecture (BullMQ)

Guidelines for building and operating BullMQ-based job queues for all async operations in BikkoChain.

---

## 🎯 Purpose

All operations that take longer than 3 seconds or involve external APIs (Kotani Pay, Lisk RPC, WhatsApp, IPFS) MUST be executed asynchronously through BullMQ queues. This is especially critical for USSD handlers which must respond in under 3 seconds.

---

## ⚠️ Critical: Use BullMQ, NOT bull

The doc.md references `bull` but the current recommended library is **BullMQ** (`bullmq` on npm). `bull` v3/v4 is deprecated. Use `bullmq` for all new queue implementations.

```bash
pnpm add bullmq ioredis
```

---

## 📋 Defined Queues

| Queue Name | Priority | Workers | Purpose |
|---|---|---|---|
| `disbursement-queue` | HIGH | 2 | Kotani Pay payout. 5 attempts, exponential backoff |
| `reminder-queue` | LOW | 1 | Repayment WhatsApp reminders. Daily cron 8am Ghana (UTC+0) |
| `sync-queue` | MEDIUM | 1 | Lisk event indexer. Polls every 30 seconds |
| `price-update-queue` | LOW | 1 | BikkoOracle.updatePrice() daily cron |

---

## 💡 Best Practices

* **Never block synchronous request handlers:** Always enqueue and return `202 Accepted` to the caller immediately.
* **Idempotent job processors:** Job processors must be safe to run multiple times. Use the loan ID or event ID as a deduplication key.
* **Graceful shutdown:** Workers must handle `SIGTERM` and allow in-flight jobs to complete before exiting.
* **Dead-letter handling:** Set up explicit failure handlers that alert the admin team via Slack webhook or email on job exhaustion.
* **Redis connection reuse:** Share a single `ioredis` connection across all queues. Do not create a new connection per queue.

---

## 📐 Code Conventions

### Shared Redis Connection

```typescript
// config/redis.ts
import { Redis } from 'ioredis';

export const redisConnection = new Redis(process.env.REDIS_URL!, {
  maxRetriesPerRequest: null, // Required by BullMQ
  enableReadyCheck: false,     // Required by BullMQ
});
```

### Queue Definition Pattern

```typescript
// queues/disbursementQueue.ts
import { Queue, Worker, QueueEvents } from 'bullmq';
import { redisConnection } from '../config/redis';
import logger from '../config/logger';

export const disbursementQueue = new Queue('disbursement-queue', {
  connection: redisConnection,
  defaultJobOptions: {
    attempts: 5,
    backoff: { type: 'exponential', delay: 60_000 }, // 1m, 2m, 4m, 8m, 16m
    removeOnComplete: { count: 100 },
    removeOnFail: { count: 500 },
  },
});

const worker = new Worker(
  'disbursement-queue',
  async (job) => {
    logger.info({ jobId: job.id, data: job.data }, 'Processing disbursement job');
    await disbursePayout(job.data);
  },
  { connection: redisConnection, concurrency: 2 }
);

worker.on('completed', (job) => {
  logger.info({ jobId: job.id }, 'Disbursement job completed');
});

worker.on('failed', (job, err) => {
  logger.error({ jobId: job?.id, attemptsMade: job?.attemptsMade, err }, 'Disbursement job failed');
  if (job && job.attemptsMade >= 5) {
    // Alert admin
    notifyAdmin(`Loan ${job.data.loanId} disbursement permanently failed: ${err.message}`);
  }
});
```

### Cron Job Pattern (Recurring)

```typescript
// queues/priceUpdateQueue.ts
import { Queue } from 'bullmq';
import { redisConnection } from '../config/redis';

const priceUpdateQueue = new Queue('price-update-queue', { connection: redisConnection });

// Schedule daily at 6am UTC (6am Ghana time = UTC+0)
await priceUpdateQueue.add(
  'update-cocoa-price',
  {},
  {
    repeat: { cron: '0 6 * * *' },
    jobId: 'daily-price-update', // Stable ID prevents duplicate cron registrations
  }
);
```

### Enqueuing from Request Handler

```typescript
// routes/loans.ts — correct pattern
router.put('/:id/approve', requireAgent, async (req, res, next) => {
  try {
    const loan = await loanService.markAsApproving(req.params.id, req.agent.id);
    
    // Enqueue — do NOT await blockchain/Kotani calls here
    await disbursementQueue.add('disburse-loan', {
      loanId: loan.id,
      amount: loan.amountUsdcCents,
      phone: loan.farmer.phoneNumber,
    });
    
    res.status(202).json({ status: 'success', message: 'Loan approved. Disbursement processing.' });
  } catch (error) {
    next(error);
  }
});
```

---

## 🛑 Constraints

* **`maxRetriesPerRequest: null`** is required in the ioredis config for BullMQ — without it, BullMQ throws errors
* **Cron job `jobId`** must be stable (not auto-generated) to prevent duplicate cron job registrations on server restart
* **Never create queues or workers inline in request handlers** — initialize them at application startup
* **Worker concurrency for disbursements:** Max 2 concurrent workers to prevent Kotani rate limiting

---

## ⚠️ Common Pitfalls

* **Using `bull` instead of `bullmq`:** They are different packages with different APIs. Check `package.json` imports.
* **Duplicate cron jobs:** On server restart, cron jobs can register duplicates if `jobId` is not stable. Always use a static `jobId` for repeatable crons.
* **Redis connection sharing issue:** BullMQ uses `BLPOP` internally which blocks the connection. Use separate Redis connections for BullMQ vs application code if sharing the same Redis instance.
* **Forgetting `removeOnComplete`:** Without it, completed jobs accumulate in Redis indefinitely.

---

## ✅ Acceptance Criteria

1. All 4 queues defined and workers initialized at startup
2. Disbursement queue retries 5 times with exponential backoff
3. Dead-letter produces admin Slack/email notification
4. Price update cron runs daily at 6am UTC
5. No synchronous blockchain or Kotani calls in request handlers
