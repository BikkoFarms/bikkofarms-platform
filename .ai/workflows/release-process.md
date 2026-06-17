# Workflow: Release Process

Procedures for migrating code changes through environments to a production deployment.

---

## 🧭 Release Pipeline
`Local Dev → Sepolia Testnet / Staging DB → CI Check Gates → Dev Branch (Staging) → Main Branch (Production) → Mainnet Contracts`

---

## 🛠️ Release Checklist

### 1. Build Verification
* Run local compile check: `npm run build`
* Run full linter and formatting verify: `npm run lint` and `npm run format`

### 2. QA & Test Run
* Ensure unit, integration, and contract test suites run successfully:
  * `npm run test`
  * `npm run test:backend`
  * `npm run test:contracts`

### 3. Deploy to Staging (Dev Branch)
* Merge approved feature/fix branches into the `dev` branch.
* Monitor automated GitHub Action builds deploying to staging nodes:
  * Next.js app to Vercel staging.
  * Node.js backend to Render staging.
  * Contracts deployed to Lisk Sepolia testnet.
* Run visual smoke checks and execute a sample loan flow via staging USSD.

### 4. Production Release (Main Branch)
* Open Pull Request from `dev` to `main`.
* A DevOps engineer and Senior Full-Stack Engineer must approve.
* Merges to `main` auto-deploy to production:
  * Main site to Vercel.
  * APIs to Render.
* If deploying new smart contracts, run the deployment scripts pointing to Lisk Mainnet RPCs and write the contract address logs to production docs.
