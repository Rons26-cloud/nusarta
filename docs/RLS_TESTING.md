# RLS Testing — Two-Account Checklist

RLS wajib diuji sebelum rilis. Gunakan **dua akun berbeda**.

## Prasyarat

- Migrasi `001` s.d. `008` sudah dijalankan.
- Dua akun: `alice@example.com` dan `bob@example.com`.

## Prosedur (V1 core)

1. Masuk sebagai **Alice**. Buat akun "Cash", satu transaksi income,
   satu budget, dan satu goal.
2. Masuk sebagai **Bob**. Buka tabel `transactions`, `accounts`,
   `categories`, `budgets`, `financial_goals`.

**Harapan:** Bob tidak melihat satu baris pun milik Alice.

3. Sebagai Bob, coba `INSERT` baris dengan `user_id = <alice_id>`
   langsung via SQL client menggunakan token Bob.

**Harapan:** ditolak oleh RLS (`new row violates row-level security policy`).

## Prosedur (V1.5 — tabel fondasi)

1. Sebagai **Alice**, buat baris di `devices`, `account_connections`,
   `future_transfers`, `transfer_recipients`, `notifications`,
   `security_events`.
2. Sebagai **Bob**, query keenam tabel tersebut.

**Harapan:** Bob tidak melihat satu baris pun milik Alice, dan `INSERT`
dengan `user_id = <alice_id>` ditolak.

### Matriks per tabel (User A vs User B)

| Tabel | SELECT milik A oleh B | INSERT user_id=A oleh B | UPDATE milik A oleh B |
|-------|----------------------|------------------------|----------------------|
| `devices` | Ditolak (devices_all_own) | Ditolak | Ditolak |
| `notifications` | Ditolak (select_own) | Tidak ada grant INSERT | Ditolak |
| `account_connections` | Ditolak (all_own) | Ditolak | Ditolak |
| `future_transfers` | Ditolak (all_own) | Ditolak | Ditolak |
| `transfer_recipients` | Ditolak (all_own) | Ditolak | Ditolak |
| `security_events` | Ditolak (select_own) | Tidak ada grant INSERT | Tidak ada grant UPDATE |

3. `institutions` dan `feature_flags`: Bob (dan siapa pun authenticated)
   **boleh SELECT**, tetapi tidak boleh INSERT/UPDATE/DELETE (read-only).

**Harapan tambahan:** `UPDATE public.institutions SET name = '...'` sebagai
Bob **gagal** (tanpa policy write; roles authenticated hanya punya grant
`select`).

### Penulisan notifikasi

`notifications` tidak punya grant INSERT untuk klien. Satu-satunya jalur
menulis adalah RPC `create_user_notification` (migrasi `008`):

```sql
-- sebagai Alice: boleh, hanya untuk dirinya sendiri
select public.create_user_notification('system', 'Halo', 'Selamat datang', '{}');

-- sebagai Alice: jenis reserved harus ditolak (errcode NUSA4)
select public.create_user_notification('transfer', 'X', null, '{}'); -- gagal
```

**Harapan:** RPC hanya menulis baris dengan `user_id = auth.uid()` (Alice),
dan menolak tipe `account_connection`/`transfer` di V1.

> Jika pengujian memakai Supabase SQL editor, pastikan memakai
> `auth.uid()` lewat klien/database yang memperlakukan pengguna sebagai
> `authenticated`, bukan role `postgres` (postgres melewati RLS).

## Perintah verifikasi cepat

```sql
-- sebagai Alice
insert into public.accounts (user_id, name, type) values ('<alice>', 'Cash', 'cash');

-- sebagai Bob (harus gagal)
select count(*) from public.accounts;    -- hanya baris Bob
insert into public.accounts (user_id, name, type) values ('<alice>', 'X', 'cash'); -- gagal

-- tabel fondasi (migrasi 005/006) — sebagai Bob: tidak boleh lihat/ubah baris Alice
insert into public.devices (user_id, device_identifier, platform)
  values ('<alice>', 'abc', 'android');  -- harus gagal
```

## Regresi otomatis (opsional)

Gunakan `supabase test` bila tersedia atau integrasi test dengan dua
sesi pada CI staging. Jangan pernah melewati hasil gagal.