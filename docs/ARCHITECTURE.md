# Architecture

## Overview

```
┌─────────────────┐   ┌─────────────────────┐
│  NUSARTA Mobile │   │  NUSARTA Website    │
│  (Flutter)      │   │  (Next.js, public)  │
└────────┬────────┘   └──────────┬──────────┘
         │ HTTPS (anon key)      │
         ▼                       │
┌───────────────────┐            │
│ Supabase          │            │
│  Auth · Postgres  │            │
│  · RLS            │            │
└───────────────────┘            │
         │                       │
         └── shared metadata ────┘  (packages/config: brand, release)
```

## Future connected-finance layer

V1 **tidak** menghubungkan aplikasi ke bank secara langsung. Untuk masa
depan, alur disiapkan agar penambahan provider legal mudah tanpa menulis
ulang aplikasi:

```
Flutter
  ↓
NUSARTA Backend  ← (abstraction layer + provider registry)
  ↓
Official Provider (berizin)
  ↓
Bank / Wallet
```

- `transactions.source` memiliki nilai cadangan: `manual`, `imported`,
  `bank_api`, `wallet_api`. V1 hanya memakai `manual`.
- `accounts` menyediakan kolom future-safe: `provider`, `external_id`,
  `is_linked`, `institution_id`, `connection_type`, `connection_status`.
- `accounts.balance` adalah balance **derived** dari ledger
  (`opening_balance` + income − expense ± transfer). Tidak ada kolom
  `provider_balance` di V1; disiapkan saat provider mensinkronkan saldo.
- Transfer masa depan memerlukan step-up auth dan settlement berbasis
  server + webhook — bukan berdasarkan balasan client.

## Domain model (V1 + foundation)

Model dipisahkan agar upgrade ke V2/V3 tidak membutuhkan rewrite:

| Domain           | Table (V1/Baru)            | Catatan                          |
| ---------------- | -------------------------- | -------------------------------- |
| User             | `profiles`                 | Mirror `auth.users`              |
| Account          | `accounts`                 | Diperluas utk koneksi            |
| Institution      | `institutions` *(baru)*    | Katalog bank/e-wallet            |
| Transaction      | `transactions`             | + `status`, `title`, `metadata`  |
| Internal transfer| `transaction_transfers`    | Pindah saldo antar akun V1       |
| Transfer (ext)   | `future_transfers` *(baru)*| Fondasi transfer bank/e-wallet   |
| Recipient        | `transfer_recipients` *(baru)* | Penerima transfer              |
| Budget           | `budgets`                  | + `alert_threshold`, kategori opsional |
| Goal             | `financial_goals`          |                                  |
| Device           | `devices` *(baru)*         | Manajemen perangkat              |
| Connection       | `account_connections` *(baru)* | Linked bank/e-wallet (V2)     |
| Notification     | `notifications` *(baru)*   | In-app / push (V2+)              |
| Audit            | `audit_events`             | + `event_category`, `ip`, `device` |
| Security event   | `security_events` *(baru)* | Terpisah dari audit normal       |
| Feature flags    | `feature_flags` *(baru)*   | Gerbang kapabilitas              |

Tabel `accounts` dan `transactions` **dipertahankan** (bukan di-rename) —
kolom baru bersifat opsional/backward-compatible.

## Monorepo packages

- `packages/config` — brand (warna, tagline), release metadata, site nav,
  feature flags. Sumber tunggal versi untuk seluruh produk.
- `packages/ui` — komponen brand (Logo, Button, Container).
- `packages/types` — shared TS types (termasuk domain keuangan future-ready).
- `packages/utils` — formatting, helpers.

Website (TypeScript) dan aplikasi (Dart) tidak berbagi source code —
hanya metadata. Fitur flag disinkronkan manual antara
`packages/config/src/featureFlags.ts` dan
`apps/mobile/lib/core/config/feature_flags.dart` serta seed DB.

## Money handling

- DB: `numeric(14,2)` — sumber kebenaran.
- Klien: `double` untuk input/tampilan V1 (aman untuk nominal IDR V1),
  dikonversi ke `numeric` saat persisten. Untuk nominal kritis (transfer)
  di V3, gunakan integer minor-unit / library decimal.

## Prinsip prioritas

1. Financial data correctness
2. Security
3. Privacy
4. Professional branding
5. Simple UX
6. Maintainability
7. SEO
8. Future upgradeability