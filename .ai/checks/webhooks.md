# Quality Checklist: Webhook Handlers

Required checks before merging any webhook endpoint (WhatsApp, USSD, Kotani Pay).

---

## 🔐 Signature Verification

- [ ] **WhatsApp:** `X-Hub-Signature-256` verified with `WA_APP_SECRET` before any processing
- [ ] **Kotani Pay:** HMAC header verified with `KOTANI_API_SECRET` before any processing
- [ ] **Africa's Talking:** Request origin validated (API key check in headers/params)
- [ ] Signature verification failure returns `401` immediately — no processing continues

---

## 🔄 Idempotency

- [ ] Every terminal webhook event is stored in `WEBHOOK_EVENTS` table with `upsert` on `event_id`
- [ ] Handler checks `processed` flag before processing — returns `200 already_processed` if already done
- [ ] `processed` flag set to `true` AFTER processing completes, not before
- [ ] Correct `event_id` extraction documented per source:
  - WhatsApp: `entry[0].changes[0].value.messages[0].id`
  - Kotani: `req.headers['x-kotani-event-id']`
  - AT USSD: `req.body.sessionId` (for terminal `END` events only)

---

## ⚡ Response Time

- [ ] **USSD:** Response sent within **3 seconds** — all async work queued via BullMQ
- [ ] **WhatsApp:** Response (200 OK) sent immediately — processing happens async
- [ ] **Kotani:** 200 OK returned immediately after idempotency check and enqueue

---

## 🛡️ Error Handling

- [ ] Malformed payloads return `400 Bad Request` with no stack traces
- [ ] Internal processing errors return `500` but DO NOT expose internal state
- [ ] All errors logged to Winston with full context (source, eventId, error)
- [ ] Dead-letter queue alert fires on repeated processing failures

---

## 📋 USSD Specific

- [ ] All USSD responses start with exactly `CON ` or `END ` (note: space after prefix)
- [ ] No USSD response exceeds 160 characters (carrier splitting prevention)
- [ ] Session state always stored before sending response
- [ ] Language preference (`1: English`, `2: Twi`) saved to session on first screen
