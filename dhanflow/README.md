# DHANFLOW — Debt Freedom. Wealth Clarity.

Mobile-first **Flutter** application (Android, iOS, macOS, and Web PWA) powered by an offline-first **Hive** ledger and optional cloud synchronization to the **Vercel PHP Backend** (`../dhanflow-api`).

## Features
- **Overview Command Centre:** Separate tracking of Gross Liabilities (*Kul Dena*), Receivables (*Kul Lena*), Net Before Bullion, Bullion Pre-GST Cost Basis, True Net Liability, Direct Pocket Card Debt, **Financial Health Score (0–100)**, **Smart Alerts**, and Balance Sheet Chart.
- **Debt Manager:** 8 Credit Cards Ledger with instant **Update Avl Limit**, **Pay / Spend**, **Edit Limit** (with limit-decrease protection), Loans & EMI countdown dots, Personal Payables, and **Debt Freedom Engine** (**Snowball**, **Avalanche**, **Custom**).
- **Kul Lena Recoveries:** Track pending recoveries independently from cards to avoid double counting, plus one-tap **Apply Received Recovery Directly to a Credit Card**.
- **Gullak Bullion Intelligence:** Gold 24K & Silver tracking with weighted average buy rate, 3% GST split, effective cost/gm, break-even sell rate, and **Live Sell Price P/L Simulator**.
- **Activity, Backup & Sync:** Immutable audit log with reversing Undo, Export/Import JSON backup, Reset Snapshot, and Vercel PHP API sync.

## Quick Start
```bash
cd dhanflow
flutter pub get
flutter run -d chrome   # or android / ios / macos
```

## Build Web PWA
```bash
flutter build web --no-wasm-dry-run
```
