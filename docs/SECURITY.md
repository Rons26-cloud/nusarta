# Security Model

## Lapisan perlindungan

| Layer                 | Keterangan                                         |
| --------------------- | -------------------------------------------------- |
| Supabase Auth         | Login email/kata sandi, sesi dikelola Supabase.    |
| PIN 6 digit           | Kunci lokal aplikasi; disimpan sebagai hash + salt.|
| Biometric             | Unlock fingerprint / face bila perangkat mendukung.|
| flutter_secure_storage| Detail sensitif (Android Keystore / iOS Keychain). |
| RLS                   | Policy per-user di setiap tabel data keuangan.     |
| Auto-lock             | Kunci ulang setelah N menit tanpa aktivitas.       |
| No plaintext PIN      | PIN tidak pernah tersimpan sebagai teks asli.      |
| No secrets in APK     | Klien hanya memegang `anon` key.                   |

## Konsep keamanan masa depan

Dipisahkan agar jelas saat fitur V2/V3 aktif:

- **A. App unlock** — PIN/biometrik membuka aplikasi (V1).
- **B. Auth session** — Supabase `AuthState`; menentukan apakah akun masih
  terautentikasi. *App lock ≠ logout.*
- **C. Step-up authentication** — untuk aksi sensitif masa depan
  (transfer, hubungkan/putuskan akun linked, ubah PIN, ubah data sensitif).
  Biometrik **hanya** membuktikan kehadiran pengguna lokal; server tetap
  memiliki flow otorisasi untuk aksi seperti transfer.

## PIN (detail)

- Algoritma: PBKDF2-style berbasis HMAC-SHA256, iterasi tinggi (120k),
  salt acak per perangkat (16 byte via `Random.secure()`).
- Brute-force: 5 percobaan gagal beruntun → kunci 5 menit.
- Klaim yang kami buat: PIN tidak disimpan plaintext. Kami **tidak** mengklaim
  keamanan absolut.
- Lupa PIN: reset melalui alur keamanan dalam aplikasi (memerlukan perangkat
  dalam keadaan terautentikasi). Dokumen ini tidak menyediakan backdoor.

## Biometric

- Dipakai hanya untuk **membuka** aplikasi, bukan per transaksi.
- Jika biometrik gagal/tersedia-nya tidak didukung → fallback PIN.
- Template sidik jari/wajah **tidak** disimpan sendiri — diserahkan ke
  Android/iOS native. Fitur ini mendeteksi ketersediaan & fallback.

## Device management (foundation)

- Tabel `devices` (migrasi 005) menyimpan `device_identifier` (UUID
  per-install, bukan identifikasi vendor/serial), platform, versi app,
  status trusted, last seen, revoked at.
- Jangan simpan hardware identifier raw bila tidak perlu.
- V1.5: aplikasi mendaftarkan perangkat saat dibuka (upsert; `last_seen_at`
  di-refresh) dan menampilkan daftar perangkat **read-only** (halaman
  `Perangkat`). Revoke/remove perangkat ditunda — tidak ada aksi palsu.
- Manajemen perangkat tidak pernah menyimpan kredensial akun.

## Notifications (in-app)

- Klien hanya punya `select`/`is_read` (update) atas `notifications`.
- Satu-satunya jalur menulis: RPC `create_user_notification` (migrasi 008)
  yang membatasi ke `auth.uid()` dan tipe V1 (`transaction`, `budget`,
  `security`, `system`). Push hanya saat flag `push_notifications` aktif.
- **Jangan log** isi notifikasi sensitif ke konsol.

## Account connections & token (future)

- Tabel `account_connections` (migrasi 005) menyimpan penyedia, koneksi,
  status, scopes, consent expiry.
- **Jangan simpan access token mentah.** Bila token perlu disimpan masa
  depan: enkripsi server-side; jangan pernah di Flutter / web client / git.

## Audit & security events

- `audit_events`: aksi normal (login, PIN changed, connection revoked, dst).
- `security_events`: kejadian keamanan (failed PIN berulang, login mencurigakan,
  session di-revoke, auth transfer gagal).
- **Jangan log:** PIN, access token, password, kredensial bank lengkap.

## RLS (semua user-owned)

- Semua tabel user-owned `enable row level security`:
  `profiles`, `accounts`, `categories`, `transactions`,
  `transaction_transfers`, `budgets`, `financial_goals`, `app_settings`,
  `audit_events`, **`devices`, `account_connections`, `future_transfers`,
  `transfer_recipients`, `notifications`, `security_events` (migrasi 006)**.
- `institutions` & `feature_flags`: read-only untuk authenticated.
- Policy memakai `auth.uid()`.
- Verifikasi dua akun wajib: `docs/RLS_TESTING.md`.

## Step-up auth (masa depan)

Abstraksi disiapkan untuk:

- Transfer asli → step-up authentication
- Hubungkan bank → verifikasi kuat
- Ubah pengaturan keamanan → re-authentication

## Larangan

- Jangan klaim "100% tidak bisa diretas".
- Jangan taruh `service_role`, password DB, signing key di repo/kode klien.
- Jangan render secret ke website.
- Jangan simpan token akses bank tanpa enkripsi server-side.