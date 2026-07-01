# Context: Environment Variables Reference

All environment variables used across BikkoChain services. Every variable must be documented here before being added to any `.env` file. **NEVER commit `.env` files to git.** In production, set all variables via **Render Dashboard → Environment → Secret Files / Env Groups**. For rotation and audit trails in Phase 2, use [Doppler](https://doppler.com).

---

## 🔗 Blockchain

| Variable | Example | Description |
|---|---|---|
| `LISK_RPC_URL` | `https://rpc.sepolia-api.lisk.com` | Lisk Sepolia testnet RPC (dev). Use `https://rpc.api.lisk.com` for mainnet |
| `LISK_BACKUP_RPC_URL` | `https://rpc.api.lisk.com` | Backup RPC for failover |
| `BACKEND_WALLET_PRIVATE_KEY` | `0x...` | **DO NOT COMMIT.** Backend relayer wallet private key. In production: set as Render Secret env var (encrypted at rest). Phase 2: migrate to Doppler or HashiCorp Vault. |
| `HARVEST_TOKEN_ADDRESS` | `0x...` | Deployed `HarvestToken.sol` contract address |
| `LENDING_VAULT_ADDRESS` | `0x...` | Deployed `BikkoLendingVault.sol` proxy address |
| `ORACLE_ADDRESS` | `0x...` | Deployed `BikkoOracle.sol` address |
| `USDC_ADDRESS` | `0x18eb25a15ec48db3c42a0f41ec0a716ba6b54514` | Circle USDC on Lisk Mainnet. Use testnet USDC address on Sepolia. |

---

## 🗄️ Database

| Variable | Example | Description |
|---|---|---|
| `DATABASE_URL` | `postgresql://bikko:password@localhost:5432/bikkochain` | PostgreSQL connection string |
| `REDIS_URL` | `redis://localhost:6379` | Redis connection URL |

---

## 📱 WhatsApp (Meta Cloud API)

| Variable | Example | Description |
|---|---|---|
| `WA_PHONE_NUMBER_ID` | `1234567890` | WhatsApp Business phone number ID from Meta Developer Console |
| `WA_BUSINESS_ACCOUNT_ID` | `0987654321` | WhatsApp Business Account ID |
| `CLOUD_API_ACCESS_TOKEN` | `EAABs...` | Meta Cloud API access token (long-lived) |
| `CLOUD_API_VERSION` | `v20.0` | Meta Graph API version |
| `WA_VERIFY_TOKEN` | `bikkochain_webhook_2026` | Random string for webhook GET verification |
| `WA_APP_SECRET` | `abc123...` | Used to verify `X-Hub-Signature-256` on incoming webhooks |

---

## 📞 Africa's Talking (USSD)

| Variable | Example | Description |
|---|---|---|
| `AT_API_KEY` | `atsk_...` | Africa's Talking API key |
| `AT_USERNAME` | `bikkochain` | AT account username (`sandbox` for dev) |
| `AT_SHORTCODE` | `*713*77#` | USSD short code (use AT sandbox code for dev) |

---

## 💸 Kotani Pay

| Variable | Example | Description |
|---|---|---|
| `KOTANI_API_KEY` | `kp_live_...` | Kotani Pay API key |
| `KOTANI_API_SECRET` | `kp_secret_...` | Kotani Pay API secret (used for HMAC webhook verification) |
| `KOTANI_API_URL` | `https://api.kotanipay.io/v1` | Kotani Pay base URL |

---

## 🗂️ IPFS / Pinata

| Variable | Example | Description |
|---|---|---|
| `PINATA_API_KEY` | `abc123...` | Pinata API key |
| `PINATA_SECRET_API_KEY` | `xyz789...` | Pinata secret API key |
| `PINATA_GATEWAY_URL` | `https://gateway.pinata.cloud` | IPFS gateway for reading metadata |

---

## 🔐 Authentication

| Variable | Example | Description |
|---|---|---|
| `JWT_SECRET` | `min-32-chars-random-string` | JWT signing secret (min 32 chars, random) |
| `JWT_EXPIRY` | `8h` | JWT token expiry (8 hours for agent sessions) |

---

## 🌐 Application

| Variable | Example | Description |
|---|---|---|
| `PORT` | `3000` | Express server port |
| `NODE_ENV` | `development` | `development` / `staging` / `production` |
| `LOG_LEVEL` | `info` | Winston log level (`debug`, `info`, `warn`, `error`) |
| `ADMIN_EMAIL` | `admin@bikkofarms.com` | Alert destination for dead-letter queue failures |
| `SLACK_WEBHOOK_URL` | `https://hooks.slack.com/...` | Slack webhook for critical failure alerts |
| `FRONTEND_URL` | `http://localhost:5173` | Dashboard URL for CORS configuration |

---

## 📁 Local .env Template

Copy this to `bikkofarms-backend/.env` for local development:

```bash
# Blockchain (Lisk Sepolia Testnet)
LISK_RPC_URL=https://rpc.sepolia-api.lisk.com
LISK_BACKUP_RPC_URL=https://rpc.api.lisk.com
BACKEND_WALLET_PRIVATE_KEY=0x_YOUR_TESTNET_PRIVATE_KEY_HERE
HARVEST_TOKEN_ADDRESS=0x_AFTER_DEPLOY
LENDING_VAULT_ADDRESS=0x_AFTER_DEPLOY
ORACLE_ADDRESS=0x_AFTER_DEPLOY
USDC_ADDRESS=0x_SEPOLIA_USDC_ADDRESS

# Database (from docker-compose.yml)
DATABASE_URL=postgresql://bikko:dev_password@localhost:5432/bikkochain
REDIS_URL=redis://localhost:6379

# WhatsApp (Meta Cloud API)
WA_PHONE_NUMBER_ID=your_phone_number_id
WA_BUSINESS_ACCOUNT_ID=your_business_account_id
CLOUD_API_ACCESS_TOKEN=your_access_token
CLOUD_API_VERSION=v20.0
WA_VERIFY_TOKEN=bikkochain_dev_verify_2026
WA_APP_SECRET=your_app_secret

# Africa's Talking (Sandbox)
AT_API_KEY=your_at_api_key
AT_USERNAME=sandbox
AT_SHORTCODE=*713*77#

# Kotani Pay (Sandbox)
KOTANI_API_KEY=your_kotani_api_key
KOTANI_API_SECRET=your_kotani_api_secret
KOTANI_API_URL=https://api.kotanipay.io/v1

# IPFS / Pinata
PINATA_API_KEY=your_pinata_api_key
PINATA_SECRET_API_KEY=your_pinata_secret_key
PINATA_GATEWAY_URL=https://gateway.pinata.cloud

# Auth
JWT_SECRET=change_this_to_a_real_random_32_char_string
JWT_EXPIRY=8h

# App
PORT=3000
NODE_ENV=development
LOG_LEVEL=debug
ADMIN_EMAIL=admin@bikkofarms.com
SLACK_WEBHOOK_URL=
FRONTEND_URL=http://localhost:5173
```

---

## ⚠️ Production Security Notes (Render)

- Set all variables in **Render Dashboard → Your Service → Environment → Add Environment Variable**
- Use **Render Secret Files** for any multi-line secrets (e.g. service account JSON)
- Use **Render Env Groups** to share the same variables across multiple services (backend + cron jobs)
- `BACKEND_WALLET_PRIVATE_KEY` — set as Render encrypted env var. Never in `.env` committed to git.
- Never log any of these values. Winston loggers must sanitize sensitive fields.
- Rotate `JWT_SECRET` on any suspected compromise — this invalidates all active agent sessions
- `AT_USERNAME=sandbox` for all development; change to real username only for production short code
- Phase 2 secret management: [Doppler](https://doppler.com) syncs directly with Render services for rotation + audit
