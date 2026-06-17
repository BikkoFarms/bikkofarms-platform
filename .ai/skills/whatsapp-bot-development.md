# Skill Manual: WhatsApp Bot Development

Guidelines for building the WhatsApp farmer interface using Meta Cloud API v20.0.

---

## 🎯 Purpose
Provide farmers with a conversational loan application and status-checking interface via WhatsApp. Supports registration, loan application, status checks, and disbursement notifications via pre-approved message templates.

---

## 🔑 Meta Cloud API Key Facts (v20.0)

- **Webhook URL:** Register at `POST https://graph.facebook.com/v20.0/{PHONE_NUMBER_ID}/messages`
- **Incoming messages:** HTTP POST to your server webhook at `/webhook/whatsapp`
- **Webhook verification:** `GET /webhook/whatsapp?hub.mode=subscribe&hub.verify_token=...&hub.challenge=...` — respond with `hub.challenge` value
- **Signature verification:** `X-Hub-Signature-256: sha256={hash}` — verify with `WA_APP_SECRET` using HMAC-SHA256
- **24-hour window rule:** You can only send free-form messages within 24h of user initiating contact. After 24h, you MUST use pre-approved Message Templates.
- **Pre-approved templates needed:** `loan_approved`, `repayment_reminder`, `loan_disbursed` — submit to Meta and wait 1-5 days for approval
- **Rate limits:** 1,000 messages/second (well above MVP needs)
- **Test phone numbers:** Meta provides free test numbers for developers — use these for MVP (no business verification needed)

## 💡 Best Practices

* **Session State in Redis (critical):** WhatsApp has no native session concept. Build it on Redis:
  - Key: `whatsapp:session:{phoneNumber}` (E.164 format: `+23324XXXXXX`)
  - Value: `{ step: 'AWAITING_LOAN_AMOUNT', farmerId: 'uuid', tempData: {} }`
  - TTL: 24 hours

* **State Machine Steps:**
  - `IDLE` → `AWAITING_NAME` → `AWAITING_GPS` → `AWAITING_ID` → `REGISTERED`
  - `IDLE` → `AWAITING_LOAN_AMOUNT` → `AWAITING_HARVEST_KG` → `LOAN_SUBMITTED`

* **Fallback to Human Agent:** If bot cannot parse farmer input 3 consecutive times, set session step to `ESCALATED` and notify agent.

* **Immediate 200 OK:** Return `200 OK` to Meta webhook immediately. Process messages asynchronously. Meta will retry on non-200 responses.

* **Interactive Buttons:** Use button messages to reduce typing errors:
  ```json
  { "type": "interactive", "interactive": { "type": "button", "body": { "text": "Welcome to BikkoChain. What would you like to do?" }, "action": { "buttons": [ { "type": "reply", "reply": { "id": "btn_register", "title": "Register" } }, { "type": "reply", "reply": { "id": "btn_apply", "title": "Apply for Loan" } }, { "type": "reply", "reply": { "id": "btn_status", "title": "Check Status" } } ] } } }
  ```

---

## 🛑 Constraints

* **Webhook Signature Validation:** ALWAYS verify `X-Hub-Signature-256` using `WA_APP_SECRET` before processing any payload. Reject with `401` on failure.
* **Idempotency:** WhatsApp may retry webhook delivery. Use `message.id` as `event_id` in the `WEBHOOK_EVENTS` table.
* **Rate Limits:** Do not send more than 1,000 messages/second. For MVP, far below this limit.
* **Document Retention:** Do not store farmer ID photos in public buckets. If accepting document uploads (Phase 2), use S3 pre-signed expiring URLs.
* **Template Submission:** Submit `loan_approved`, `repayment_reminder`, `loan_disbursed` templates to Meta on Day 1. They take 1-5 days to approve.

---

## 📐 Code Conventions

* **Interactive Menu Construction (Meta API JSON structure example):**
  ```json
  {
    "type": "interactive",
    "interactive": {
      "type": "button",
      "body": {
        "text": "Welcome to BikkoChain. Please select an option:"
      },
      "action": {
        "buttons": [
          { "type": "reply", "reply": { "id": "btn_apply", "title": "Apply for Loan" } },
          { "type": "reply", "reply": { "id": "btn_balance", "title": "Check Balance" } }
        ]
      }
    }
  }
  ```

---

## ⚠️ Common Pitfalls

* **Storing Media URLs in Plaintext:** Leaking links to download farmer IDs or crop receipt tickets. Always use signed, expiring URLs (S3 Pre-signed URLs) for dashboard review views.
* **Template Rejections:** Sending free-form marketing/outbound messages outside the 24-hour customer window. Always send template-approved messages for notification triggers.

---

## ✅ Acceptance Criteria

1. **Secure Endpoints:** All webhook controllers verify signature payloads.
2. **Dynamic UI:** Option lists, select buttons, and text messages match localization configurations.
3. **Robust Media Processing:** Document/photo uploads are successfully logged and queued without server memory leaks.
