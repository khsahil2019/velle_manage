# DHANFLOW PHP API (Vercel Serverless)

PHP 8.1+ REST API backend for **DHANFLOW** — Indian Debt Freedom & Bullion Portfolio Tracker, configured for **Vercel (`vercel-php@0.7.1`)** and **MySQL 8 / PlanetScale** (with SQLite support for local dev/tests).

## Key Design Guarantees
- **Integer Paise Arithmetic:** All amounts stored as `BIGINT` paise (`₹100.00 = 10000`), grams stored as `BIGINT × 10000` (`0.5000 gm = 5000`). Zero float rounding drift.
- **Atomic Recovery-to-Card Linking:** `RecoveryService::recordPayment()` updates both `recoveries` and `credit_cards` inside a single PDO transaction.
- **Final EMI Protection:** `RecoveryService::markEMIPaid()` uses actual `total_remaining` on the final EMI.
- **JWT Auth:** Stateless HS256 access (15m) + refresh (30d) tokens.

## Endpoints
- `GET /api/index.php` — Health check
- `POST /api/auth/register` · `POST /api/auth/login` · `POST /api/auth/refresh`
- `GET /api/dashboard/kpis` — Full KPI snapshot, Health Score (0–100), and Smart Alerts
- `GET|POST /api/debt-engine/plan` — Snowball / Avalanche / Custom payoff simulation
- `GET|POST /api/cards` · `GET|PUT|DELETE /api/cards/{id}` · `POST /api/cards/{id}/avl-update` · `GET|POST /api/cards/{id}/transactions`
- `GET|POST /api/loans` · `GET|PUT|DELETE /api/loans/{id}` · `POST /api/loans/{id}/emi-paid`
- `GET|POST /api/payables` · `GET|PUT|DELETE /api/payables/{id}` · `POST /api/payables/{id}/pay`
- `GET|POST /api/recoveries` · `GET|PUT|DELETE /api/recoveries/{id}` · `POST /api/recoveries/{id}/record`
- `GET /api/bullion` · `GET|POST /api/bullion/summary` · `GET|POST|DELETE /api/bullion/transactions`
- `GET /api/activity` — Paginated audit trail
- `GET /api/backup/export` · `POST /api/backup/import` · `POST /api/backup/reset-seed`

## Deploy to Vercel
1. Provision a MySQL 8 database (PlanetScale, Aiven, or Clever Cloud) and run `schema.sql`.
2. Add Vercel environment variables:
   - `DB_HOST`, `DB_NAME`, `DB_USER`, `DB_PASS`, `DB_PORT`, `JWT_SECRET`
3. Deploy:
   ```bash
   cd dhanflow-api
   vercel --prod
   ```

## Local Testing
Run the built-in PHP integration test suite (uses SQLite `:memory:`):
```bash
php tests/IntegrationTest.php
```
