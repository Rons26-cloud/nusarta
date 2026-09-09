# Database

NUSARTA memakai **Supabase (PostgreSQL)**. Semua perubahan skema lewat
`supabase/migrations/` — jangan mengedit schema produksi secara manual.

## Migrasi

| File | Isi |
| ---- | --- |
| `001_initial_schema.sql` | Skema inti V1 (profiles, accounts, categories, transactions, transaction_transfers, budgets, financial_goals, app_settings, audit_events) + enum. |
| `002_row_level_security.sql` | RLS di semua tabel V1 + auto-create profile/settings + grants. |
| `003_ledger_transfer_rls.sql` | `opening_balance`, derived balance via trigger, transfer atomik via RPC `create_internal_transfer`, RLS kepemilikan referensi, unique kategori. |
| `004_account_deletion.sql` | `delete_my_account` (SECURITY DEFINER, re-auth 5 menit, konfirmasi `HAPUS`). |
| `005_future_foundation.sql` | Fondasi V1.5: enum baru + `institutions`, `devices`, `account_connections`, `future_transfers`, `transfer_recipients`, `notifications`, `feature_flags`, `security_events`; kolom baru di `accounts`, `transactions`, `budgets`, `audit_events`; trigger baru. |
| `006_future_foundation_rls.sql` | RLS + grants untuk tabel fondasi. `institutions` & `feature_flags` read-only. |
| `007_account_deletion_extended.sql` | `delete_my_account` diperluas: membersihkan tabel fondasi juga. |
| `008_future_foundation_harden.sql` | RPC `create_user_notification` (jalur aman menulis notifikasi), index `accounts` untuk `institution_id` & `is_primary`. |

Aturan: migration baru, jangan tulis-ulang migration yang sudah dianggap
applied. Migration bersifat idempotent bila mungkin (`if not exists`,
`do $$ ... exception when duplicate_object`).

## Enum (konsisten lintas versi app)

| Enum | Nilai |
| ---- | ----- |
| `account_type` | `cash`, `bank`, `ewallet`, `custom` |
| `transaction_kind` | `income`, `expense`, `transfer` |
| `transaction_source` | `manual`, `imported`, `bank_api`, `wallet_api` |
| `budget_period` / `goal_period` | `weekly`, `monthly`, `yearly` |
| `institution_type` | `bank`, `ewallet`, `cash`, `other` |
| `connection_type` | `manual`, `bank_api`, `ewallet_api`, `open_banking`, `payment_provider` |
| `connection_status` | `manual`, `disconnected`, `pending`, `active`, `expired`, `error`, `revoked` |
| `balance_source` | `calculated`, `manual`, `provider` |
| `transaction_status` | `pending`, `completed`, `failed`, `reversed`, `cancelled` |
| `transfer_status` | `draft`, `awaiting_authorization`, `pending`, `processing`, `success`, `failed`, `reversed`, `cancelled` |
| `destination_type` | `bank`, `ewallet`, `internal_future` |
| `device_platform` | `android`, `ios`, `web`, `other` |
| `notification_type` | `transaction`, `budget`, `security`, `account_connection`, `transfer`, `system` |
| `event_category` | `auth`, `security`, `connection`, `transfer`, `account`, `system` |

## Uang — bukan float

- Semua nominal: `numeric(14,2)` (sumber kebenaran).
- Klien boleh memakai `double` hanya untuk input/tampilan V1.
- Untuk nominal kritis (transfer V3): integer minor-unit / library decimal.
- Jangan pernah memakai floating point di PostgreSQL untuk uang.

## Balance model

`accounts.balance` = **derived** dari ledger:
`opening_balance + Σ(income) − Σ(expense) ± Σ(transfer legs)`.

- Di-recompute otomatis oleh trigger (`recompute_account_balance`).
- Kolom `last_synced_at`, `connection_type`, `connection_status`, dan
  enum `balance_source` disiapkan untuk balance dari provider (V2).
- UI V1 membaca satu nilai saldo (derived); masa depan bisa membaca
  `provider_balance` dengan sumber yang jelas.

## Indexes

Index utama untuk query umum:

- `transactions (user_id, occurred_at desc)`
- `transactions` referensi: `account_id`, `category_id` (via FK lookup),
  `provider_reference`, `status`
- `institutions (institution_type)`, `(is_active) WHERE is_active`
- `devices (user_id)`, unique `(user_id, device_identifier)`
- `account_connections (user_id)`, `(status)`
- `future_transfers (user_id)`, `(status)`, unique `idempotency_key`,
  `(provider_reference)`
- `transfer_recipients (user_id)`
- `notifications (user_id, is_read, created_at desc)`
- `security_events (user_id, created_at desc)`, `(event_category)`
- `accounts (institution_id) WHERE institution_id`, `(is_primary) WHERE`
  (migrasi `008`)

## Soft delete / archive

- `accounts.is_archived` — jangan hard-delete akun dengan riwayat.
- `categories` — rencanakan arsip; hindari orphan pada transaksi historis.
- `transfer_recipients` — arsip bila ada.

## On delete behavior

- `profiles → auth.users` / tabel user-owned: `on delete cascade`.
- `transaction_transfers.from/to_account_id`: `restrict` (jangan hapus akun
  yang masih jadi kaki transfer — hapus kaki dulu).
- `transactions.category_id`: `set null` (transaksi tetap tersimpan saat
  kategori dihapus).
- `account_connections.financial_account_id`: `set null` saat akun dihapus
  (revoke connection ≠ hapus riwayat transaksi).

## Notifikasi in-app (V1)

- Semua baris `notifications` menunjuk `user_id = auth.uid()`.
- **Klien tidak punya grant INSERT/UPDATE langsung selain `select`/`is_read`**
  (migrasi `006`). Update `is_read` dilakukan via RLS `notifications_update_own`.
- Satu-satunya jalur menulis dari klien adalah RPC
  `public.create_user_notification(p_type, p_title, p_body, p_data)`
  (migrasi `008`), yang:
  - hanya mengizinkan `auth.uid()` (errcode `NUSA1` bila unauthenticated),
  - hanya menerima tipe V1 (`transaction`, `budget`, `security`, `system`;
    tipe lain ditolak dengan errcode `NUSA4`).
- Push notification tetap OFF lewat flag `push_notifications`.

## Perangkat (V1.5)

- Registrasi perangkat: aplikasi menyimpan id per-install (UUID) di secure
  storage, lalu `INSERT`/upsert `devices` dengan `user_id` milik sesi — RLS
  `devices_all_own` memastikan skope ke dirinya sendiri.
- Identitas perangkat bukan identifikasi vendor/serial; tidak pernah
  mengandung kredensial akun. `last_seen_at` di-refresh saat app dibuka.
- Manajemen perangkat versi ini **read-only** (list + tandai "perangkat ini");
  revoke/remove ditunda ke rilis keamanan berikutnya (tanpa aksi palsu).

## Transfer eksternal (belum aktif)

- `future_transfers` & `transfer_recipients` menunggu integrasi resmi.
- `future_transfers.source_financial_account_id` memakai FK default
  `NO ACTION` (efektif RESTRICT): menghapus akun tidak boleh secara diam-diam
  meng-hapus/meng-orphan baris transfer.