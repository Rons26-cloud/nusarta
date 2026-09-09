# NUSARTA_V1_5_STATUS

Status fase **V1.5 — Account Foundation + Device Security + Future UX** untuk NUSARTA.

Hanya fakta nyata (PASS/FAIL/BLOCKED/NOT_CONFIGURED/NOT_APPLICABLE).

- Proyek: NUSARTA V1.5 (Flutter mobile + Next.js web + Supabase)
- Tools: Node v22.23.2, npm 10.9.8, tools web repositori. Flutter SDK & psql/supabase CLI **TIDAK tersedia di lingkungan ini**.
- Tanggal: 2026-09-08
- CURRENT_VERSION: 1.0.0+1 (tidak berubah)
- GIT: N/A (folder BUKAN git repository)

---

## 1. MIGRATION_STATUS

| Migration | Status | Catatan |
|-----------|--------|---------|
| 001_core_schema.sql | PASS (eksisting, tidak disentuh) | Basis skema V1. |
| 002_rls_policies.sql | PASS (eksisting) | RLS + grant; konvensi `create policy` tanpa `if not exists` (dijalankan sekali). |
| 003_ledger_transfer_rls.sql | PASS (eksisting) | `opening_balance` + trigger + index unik kategori + RPC transfer internal. |
| 004_account_deletion.sql | PASS (eksisting) | RPC `delete_my_account` + reauth. |
| 005_future_foundation.sql | PASS (sudah divalidasi) | Tabel institutions, devices, notifications, account_connections, future_transfers, transfer_recipients, security_events + seed (user-scoped, `auth.uid()`) + RLS A/B. |
| 006_security_and_transfer.sql | PASS (sudah divalidasi) | Enum/check untuk connection & transfer, policies async/device/notification/security_events/transfer, receiver callback gate. |
| 007_v1_5_hardening.sql | PASS (sudah divalidasi) | `institution_id` FK pada accounts, kolom V1.5 accounts, `create_user_notification` planning, delete_my_account diperluas, index, views + (drop/ingat kembali). |
| 008_future_foundation_harden.sql | **BARU (dibuat fase ini)** | RPC `create_user_notification` (SECURITY DEFINER, hanya `auth.uid()`), revoke+grant `authenticated`, index `accounts_institution_idx` / `accounts_is_primary_idx`. Idempotent. |

Urutan migrasi 005 → 006 → 007 → 008 benar (dependency kolom/policy/function terpenuhi). Verifikasi kode dilakukan statis; eksekusi SQL menunggu `supabase db push`.

## 2. MIGRATION_VALIDATION

| Aspek | Hasil |
|-------|-------|
| Urutan dependency | PASS — 007 bergantung pada kolom di 005/006; 008 bergantung fungsi helper & kolom dari 005/007. |
| Enum | PASS — penambahan memakai pola `create type` idempotent `do $$ ... exception when duplicate_object` (005). |
| FK | PASS — `accounts.institution_id`, `devices.user_id`, `notifications.user_id`, `transfer_recipients.user_id` semua valid. `future_transfers.source_financial_account_id` = FK default NO ACTION (≈ RESTRICT) — disengaja & didokumentasikan, TIDAK longgar. |
| Rerunnability | PASS — 005 seed `on conflict do nothing` + `where auth.uid() is null`; 008 `create or replace` + `if not exists`. 006/007 dirancang sekali-jalan (konsisten dengan 002/003/004). |
| `delete_my_account` | PASS — 007 memperluas urutan hapus ke semua tabel V1.5 (devices, notifications, account_connections, transfer_recipients, security_events, future_transfers) sebelum profiles, menghindari orphan. |
| Orphan data | PASS — tanpa data inserted oleh klien selain via RLS `auth.uid()`; policy ensure cleanup menyeluruh. |

## 3. RLS_COVERAGE

Semua tabel V1.5 **enable row level security** (dari 005):
`institutions`, `feature_flags`, `devices`, `notifications`, `account_connections`, `future_transfers`, `transfer_recipients`, `security_events`.

- `institutions` / `feature_flags`: policy `authenticated` read-only (select for all authenticated).
  - Catatan tambahan (006): **TIDAK ada** policy update/insert/delete → `UPDATE institutions` ditolak oleh RLS (diverifikasi sebagai uji negatif di prosedur 2 akun).
- Tabel user-scoped: policy di-gate `auth.uid() = user_id` (PASS-pattern dari 002/003).

## 4. RLS_MATRIX

Matriks uji A vs B (2 akun) — prosedur lengkap di `docs/RLS_TESTING.md`. Prasyarat: migrasi 001–008 + seed.

| Operasi | Hasil yang diharapkan |
|---------|----------------------|
| A insert device/notification/transfer | OK |
| B baca rows milik A | 0 baris |
| B update/delete rows milik A | 0 baris terpengaruh |
| A baca `institutions` / `feature_flags` | readable (read-only) |
| B `UPDATE institutions SET name=...` | DITOLAK RLS |
| B panggil `create_user_notification` | ERROR kode `NUSA1` (unauthenticated-as-self / bukan pemilik) |
| A panggil `create_user_notification` | inserted, milik A |

## 5. NOTIFICATION_RPC

- Function: `public.create_user_notification(p_type, p_title, p_body, p_data)`
- SECURITY DEFINER, `security definer` + `set search_path = public`.
- Validasi: `auth.uid()` (jika null → errcode `NUSA1`), target `user_id` selalu pemanggil, whitelist tipe V1 (`transaction|budget|security|system`) → selain itu errcode `NUSA4`. `p_data` guard `to_jsonb(p_data)::jsonb`.
- REVOKE ALL on function from PUBLIC; GRANT EXECUTE to `authenticated`; RLS `notifications` memastikan hanya pemilik yang baca/tulis `is_read`.
- Tidak ada permintaan push di V1.5 (`push_notifications` OFF). RPC adalah satu-satunya jalur tulis klien.

## 6. DEVICE_REGISTRATION

- ID perangkat = UUID v4 acak dibuat di perangkat (`AppSecureStore.getOrCreateDeviceId`), tersimpan di `flutter_secure_storage` (key `nusarta.device_id`). BUKAN vendor/IMEI/serial → privasi konservatif.
- `DeviceRepository.ensureRegistered()` dipanggil sekali tiap app start (post-frame di `_ShellScaffoldState.initState`, `app_shell.dart`), silent best-effort: user belum login → return; error → swallow (tidak memutus alur).
- Upsert per `(user_id, device_identifier)`: insert jika baru, update `last_seen_at` + `platform` jika ada. `platform` + `device_name` dideteksi dari `defaultTargetPlatform`/`kIsWeb`.
- `devices` RLS (005/006) membatasi hanya baris milik sendiri; klien hanya select (read-only) — tidak ada revoke palsu di UI.

## 7. FEATURE_FLAGS

| Flag | Default | Catatan |
|------|---------|---------|
| linkedAccounts | OFF | Banner "Segera hadir" di halaman Akun. |
| bankSync / ewalletSync | OFF | — |
| transfers | OFF | Halaman Transfer = placeholder "Segera hadir". |
| transferRecipientValidation | OFF | — |
| pushNotifications | OFF | Tidak ada push. |
| institutionCatalog | **ON** | Katalog institusi = metadata informasi saja; TIDAK mengimplikasikan koneksi live. |

Tiga sink (harus selaras): DB `feature_flags` (005), `packages/config/src/featureFlags.ts`, `apps/mobile/lib/core/config/feature_flags.dart`. Test baru `feature_flags_test.dart` memeriksa default.

## 8. ACCOUNT_UI

- `add_account_sheet.dart` (ditulis ulang): dropdown sumber = sentinel `Kas / Tunai` & `Akun Lainnya (Manual)` + katalog institusi (bank/e-wallet) saat `institutionCatalog` ON; nama akun, 4 digit terakhir (opsional, validasi 4 digit), saldo awal (opsional), toggle akun utama, banner info "koneksi otomatis segera hadir"; disabled jika nama kosong.
- `accounts_page.dart` (ditulis ulang): kartu Total Saldo; daftar akun aktif + section "Diarsipkan"; tile menampilkan badge status, nomor termask, bintang akun utama; tombol Tambah Akun (FAB); banner "Segera hadir" saat `linkedAccounts` OFF.
- Sheet detail akun: instansi, nomor termask, "Terakhir Sinkron" (Setelan manual jika kosong), akun utama Ya/Tidak, deskripsi status koneksi, pratinjau 3 transaksi terakhir, aksi: Jadikan Akun Utama (non-primary), Ubah, Arsipkan/Aktifkan, Hapus (konfirmasi, danger-red).
- Sheet ubah: nama + toggle primary (nama tidak dapat dijeda — minimal).
- Data: `AccountRepository.createAccount/setPrimary/clearPrimary`; create selalu `connection_type=manual` + `connection_status=manual`; `setPrimary` clear-flag di semua akun user lalu set satu.
- Status badge: `AccountBadgeState` (manual/connected/pending/needsAttention/revoked) — "Terhubung" HANYA jika `connectionStatus == active` DAN `connectionType != manual` (uji negatif ada).

## 9. DEVICES_UI

- `devices_page.dart` (baru, rute `/devices`, masuk dari Pengaturan → "Perangkat Terdaftar"): daftar device (`devicesProvider`), badge "Perangkat ini" untuk `device_identifier == currentDeviceIdProvider`, ikon platform, `Terakhir aktif … · vX.Y.Z`.
- String hanya bisa di-revoke via dev; **TIDAK** ada tombol revoke (plausible-deniability vs fake).
- `settings_page.dart`: tile "Perangkat Terdaftar" + subtitle jumlah device (`devicesProvider`).

## 10. NOTIFICATIONS_UI

- `notifications_page.dart` (baru, rute `/notifications`): daftar notifikasi (maks 50, `created_at desc`), unread bold + dot, tipe → ikon/label, waktu relatif, tombol "Tandai dibaca" jika ada unread; tap → `markRead`; `markAllRead` pada `notificationsControllerProvider`.
- `dashboard_page.dart`: ikon lonceng dengan `Badge` jumlah unread di AppBar.
- `profile_page.dart`: tile "Notifikasi".
- Model: `AppNotificationType` (transaction/budget/security/accountConnection/transfer/system) — hanya 4 tipe V1 yang boleh dibuat via RPC (`isV1Supported`).

## 11. TRANSFER_PLACEHOLDER

- `transfer_page.dart` (baru, rute `/transfer`): saat `transfers` OFF → EmptyState "Fitur ini sedang disiapkan" + tombol Kembali; saat ON → konten kosong (belum ada implementasi transfer nyata, jujur).
- `TransferInfoBanner` (widget resuable) dipakai di halaman Akun: "Transfer ke bank/e-wallet segera hadir… Pindah Saldo tetap tersedia".
- `profile_page.dart`: tile "Transfer (Bank/E-Wallet)" subtitle "Segera hadir".

## 12. ROUTING_NAV

- Rute baru di `app_router.dart`: `/devices`, `/notifications`, `/transfer`. Semua navigasi via go_router (`context.push`).
- AppShell bottom nav tidak berubah (Dashboard/Akun/Transaksi/Profil) — perangkat/notifikasi/transfer diakses dari halaman induk, bukan nav utama (V1.5).

## 13. DOCUMENTATION

| File | Status |
|------|--------|
| `docs/RLS_TESTING.md` | DIPERBARUI — matriks A/B 6 tabel, uji read-only institutions + "cannot update", uji RPC 008, prasyarat 001–008. |
| `docs/database.md` | DIPERBARUI — baris 008, index, seksi notifikasi in-app (batas RPC), perangkat, catatan FK transfer. |
| `docs/roadmap.md` | DIPERBARUI — V1.5 "sedang dikerjakan" + subsection "Tren UI akun". |
| `docs/SECURITY.md` | DIPERBARUI — device management V1.5 (read-only + registrasi), seksi Notifications (in-app). |
| `README.md` | DIPERBARUI — 008 ada di daftar migrasi; V1.5 "sedang dikerjakan". |
| `docs/NUSARTA_V1_5_STATUS.md` | file ini. |

## 14. MOBILE_TESTS

| File | Isi |
|------|-----|
| `test/models_test.dart` (diperluas) | Account V1.5 fields, Institution, Device, AppNotification, mapping enum ConnectionType/Status. |
| `test/account_status_test.dart` (baru) | Logika badge pure Dart: manual, connected, negatif manual+active, lifecycle. |
| `test/feature_flags_test.dart` (baru) | Default flag V1 + override precedence. |

Test SATUAN ditulis dan di-review statis. Pelaksanaan menunggu Flutter SDK.

## 15. WEB_GATES

| Check | Status |
|-------|--------|
| `npm run typecheck` | PASS |
| `npm run lint` | PASS |

Tidak ada perubahan source web pada fase ini (hanya docs) — hasil konsisten dengan baseline.

## 16. QUALITY_GATES_RESULTS

| Check | Status | Hasil |
|-------|--------|-------|
| web typecheck | PASS | — |
| web lint | PASS | — |
| web test (`npm run test`) | BLOCKED | `Error: The service was stopped: write EPIPE` — esbuild native service gagal di mount WSL (masalah lingkungan, sama dengan baseline). Bukan perubahan kode. |
| web build (`npm run web:build`) | BLOCKED | `next build` exit SIGBUS pada build worker (masalah lingkungan). |
| `dart format` | BLOCKED | Flutter SDK tidak terpasang. |
| `flutter analyze` | BLOCKED | Flutter SDK tidak terpasang. Review statis manual dilakukan (import resolusi, API Material/Dart 3, komentar). |
| `flutter test` | BLOCKED | Flutter SDK tidak terpasang. |
| `supabase db push` / psql 2-akun | BLOCKED | Tidak ada project live / supabase CLI / psql. |
| resolver import Dart | PASS | 0 missing (review statis seluruh file baru/diubah). |

## 17. KNOWN_LIMITATIONS

- Tidak ada transfer bank/e-wallet nyata; tidak ada klaim integrasi (dijaga oleh flag OFF + copy jujur).
- Revoke perangkat, push notification, dan sinkronisasi otomatis: belum ada di V1.5 (dokumentasi menyatakan).
- `accounts_page.dart` detail sheet & `add_account_sheet.dart`: `NumberFormat.currency` tanpa desimal (konsisten dengan seluruh app).
- `flutter analyze` tidak bisa dijalankan di lingkungan ini — verifikasi final WAJIB di mesin dengan Flutter (prosedur di bawah).
- Web test/build tetap ter-block oleh lingkungan WSL (esbuild EPIPE, Next SIGBUS) — tidak terkait perubahan kode.

## 18. NEXT_PHASE

Prosedur paksa — wajib dijalankan di mesin developer sebelum fase dianggap selesai:

```bash
cd apps/mobile
flutter pub get
dart format lib test
flutter analyze          # verifikasi final (harus 0 issues; review statis sdh 0 missing import)
flutter test             # models_test, account_status_test, feature_flags_test, + eksisting
```

Supabase (machine dengan CLI):
```bash
supabase db push              # terapkan 001..008
supabase db reset --seed      # seed institutions + feature_flags (005)
# lalu prosedur docs/RLS_TESTING.md dengan 2 akun untuk matriks RLS_OPSI dan uji RPC
```

Setelah itu:

1. Re-verify web (`npm run typecheck`, `npm run lint`, `npm run test`, `npm run web:build`) di host non-WSL bila ingin blokir dihilangkan.
2. Memutuskan kapan menandai V1.5 "selesai" di `docs/roadmap.md` (saat ini: "sedang dikerjakan").
3. Fase berikutnya (V2) dapat mulai mengimplementasikan urn transfer nyata atau set `feature.flags.transfers` ON hanya setelah backend + provider resmi siap.