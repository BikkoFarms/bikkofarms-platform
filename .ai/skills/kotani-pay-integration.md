# Skill Manual: Kotani Pay Integration

Guidelines for integrating Kotani Pay as the USDC → Mobile Money off-ramp for BikkoChain loan disbursements.

---

## 🎯 Purpose

Kotani Pay converts USDC held on Lisk into local currency (GHS, KES, UGX) and deposits directly into farmer mobile wallets (MTN MoMo Ghana, AirtelTigo Ghana, M-Pesa Kenya). This is the critical "last mile" payment step that puts money in farmers' hands.

---

## 🔑 Key Facts

- **API Version:** v1 — `https://api.kotanipay.io/v1`
- **Supported chains:** Lisk (confirmed), Ethereum, Polygon
- **Supported corridors:** Ghana (MTN MoMo, AirtelTigo), Kenya (M-Pesa), Uganda (MTN, Airtel)
- **USDC float requirement:** You must maintain a USDC balance in your Kotani Pay settlement account. Plan for float management.
- **Sandbox:** Use sandbox environment for all development. Register at kotanipay.io.
- **Contact dev support early** — API docs are sparse. Reach out to Kotani Pay directly on Day 1.

---

## 💡 Disbursement Flow

```
1. Backend: USDC.transfer(kotaniDepositAddress, amount) via ethers.js
2. POST /v1/quotes → get exchange rate + quoteId (quote expires in ~60s)
3. POST /v1/payouts → {quoteId, recipient: {type: mobile_money, phone, provider}}
4. Store payoutId in loans.kotani_payout_id, set status=DISBURSING
5. Kotani Pay sends mobile money to farmer
6. Kotani Pay webhook POST /webhook/kotani {event: payout.completed, payoutId, txRef}
7. Verify HMAC, check idempotency, update loan status=DISBURSED
8. Send WhatsApp notification to farmer
```

---

## 📐 Code Conventions

### KotaniService.ts Structure

```typescript
// services/KotaniService.ts

interface KotaniQuoteRequest {
  fromAsset: 'USDC';
  toAsset: 'GHS' | 'KES' | 'UGX';
  amount: number; // in USDC
}

interface KotaniQuoteResponse {
  quoteId: string;
  exchangeRate: number;
  fee: number;
  expiresAt: string; // ISO 8601
}

interface KotaniPayoutRequest {
  quoteId: string;
  recipient: {
    type: 'mobile_money';
    phone: string;   // E.164 format: +23324XXXXXX
    provider: 'mtn' | 'airteltigo' | 'mpesa';
  };
}

interface KotaniPayoutResponse {
  payoutId: string;
  status: 'PENDING' | 'PROCESSING' | 'COMPLETED' | 'FAILED';
}

export class KotaniService {
  private readonly baseUrl = process.env.KOTANI_API_URL!;
  private readonly apiKey = process.env.KOTANI_API_KEY!;

  async getQuote(request: KotaniQuoteRequest): Promise<KotaniQuoteResponse> {
    // POST /v1/quotes
  }

  async createPayout(request: KotaniPayoutRequest): Promise<KotaniPayoutResponse> {
    // POST /v1/payouts
  }

  verifyWebhookSignature(payload: string, signature: string): boolean {
    // HMAC-SHA256 with KOTANI_API_SECRET
    const hmac = crypto.createHmac('sha256', process.env.KOTANI_API_SECRET!);
    const digest = hmac.update(payload).digest('hex');
    return crypto.timingSafeEqual(Buffer.from(digest), Buffer.from(signature));
  }
}
```

### Provider Mapping

```typescript
// Map AT phone number prefix to Kotani Pay provider
function detectGhanaProvider(phone: string): 'mtn' | 'airteltigo' {
  const normalized = phone.replace(/\D/g, '');
  // MTN Ghana: 024, 054, 055, 059
  if (/^(0?24|0?54|0?55|0?59)/.test(normalized)) return 'mtn';
  // AirtelTigo Ghana: 026, 027, 057
  return 'airteltigo';
}
```

---

## 🔄 BullMQ Disbursement Queue

All Kotani Pay payouts MUST go through the `disbursement-queue`:

```typescript
// queues/disbursementQueue.ts
import { Queue, Worker } from 'bullmq';

const disbursementQueue = new Queue('disbursement-queue', {
  connection: redisConnection,
  defaultJobOptions: {
    attempts: 5,
    backoff: {
      type: 'exponential',
      delay: 60_000, // 1 minute base
    },
    removeOnComplete: 100,
    removeOnFail: 500,
  },
});

// Worker
const worker = new Worker('disbursement-queue', async (job) => {
  const { loanId, amount, phone, provider } = job.data;
  await disbursePayout({ loanId, amount, phone, provider });
}, { connection: redisConnection });

worker.on('failed', async (job, err) => {
  if (job && job.attemptsMade >= 5) {
    // Move to dead-letter: alert admin
    await notifyAdmin(`Disbursement failed for loan ${job.data.loanId}: ${err.message}`);
  }
});
```

---

## 🛑 Constraints

- **Never call Kotani Pay synchronously in a webhook handler** — always enqueue in BullMQ
- **Always verify HMAC** on incoming Kotani webhooks before processing
- **Always use idempotency check** (WEBHOOK_EVENTS table) before processing `payout.completed`
- **Quote expiry:** A Kotani quote expires in ~60 seconds. Get quote and create payout atomically in the same job worker, not split across queues.
- **USDC transfer before quote:** Transfer USDC to Kotani deposit address BEFORE calling `/v1/quotes`. The quote is contingent on funds being present.
- **Phone number format:** Always use E.164 format with country code: `+23324XXXXXX` for Ghana

---

## ⚠️ Common Pitfalls

- **Quote expiry between API calls:** Quote from `/v1/quotes` must be used within ~60 seconds. Do both steps in a single atomic BullMQ job.
- **Float depletion:** Monitor USDC balance in Kotani account. If float runs out, disbursements fail. Set up CloudWatch alarm on USDC balance.
- **Provider mismatch:** Sending to wrong provider causes failure. Detect provider from phone number prefix (see mapping above) or ask farmer explicitly.
- **Missing webhook verification:** Never trust Kotani webhooks without HMAC verification.

---

## ✅ Acceptance Criteria

1. Quote + payout API calls both succeed in sandbox environment
2. Webhook `payout.completed` correctly updates loan status to DISBURSED
3. Duplicate webhook events are idempotently handled (no double disbursement)
4. Failed payouts after 5 attempts trigger admin Slack/email alert
5. WhatsApp confirmation sent to farmer on successful disbursement
