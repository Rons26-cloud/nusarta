# NUSARTA_RELEASE_STATUS

Status release candidate NUSARTA **1.0.0+1** — dibuat oleh AGENT 5 (2026-09-07), diperbarui oleh AGENT 6 (2026-09-07).

Hanya fakta nyata (PASS/FAIL/BLOCKED/NOT_CONFIGURED/NOT_APPLICABLE).

## Identitas Release

| Field | Nilai |
|-------|-------|
| APP_NAME | NUSARTA |
| VERSION_NAME | 1.0.0 |
| BUILD_NUMBER | 1 |
| ANDROID_APPLICATION_ID | com.nusarta.app |
| ANDROID_NAMESPACE | com.nusarta.app |
| APP_LABEL | NUSARTA |
| MIN_SDK | 26 (Android 8.0) |
| TARGET_SDK | 34 |
| COMPILE_SDK | 34 |
| TAGLINE | Keuanganmu, Dalam Kendalimu. |

## Status Checks

| Check | Status | Catatan |
|-------|--------|---------|
| APP_ICON | PASS | Launcher icon legacy 5 density (mipmap). Adaptive icon configured dengan foreground layer di semua density dan monochrome layer. Background color #084C36 (emerald). |
| SPLASH | PASS | Native splash `launch_background.xml` (drawable + drawable-v21) kini emerald `#084C36` + logo `splash_logo.png` (dari `assets/brand/logo.png`). Tidak ada flash putih. Android 12+ system splash tetap mereplikasi launcher icon secara otomatis. |
| PERMISSION_AUDIT | PASS | Merged manifest hanya: INTERNET, USE_BIOMETRIC, USE_FINGERPRINT (local_auth), + DYNAMIC_RECEIVER_NOT_EXPORTED. Tidak ada SMS/Contacts/Location/Camera/Microphone/Storage/Notifications. |
| DEBUG_FLAGS | PASS | `debugShowCheckedModeBanner:false`; tanpa menu dev/mock/bypass. |
| PRODUCTION_ENV | PASS | Config via `--dart-define` (untracked `app_config.dart`); anon key public; RLS otoritas utama. |
| SECRET_SCAN | PASS | Tidak ada `service_role`, DB password, private key, atau keystore di source. `app_config.dart` & `.env*` di-ignore. |
| LOGGING | PASS | Satu debugPrint config di-gate `kDebugMode`; tidak ada log PIN/password/token. |
| SAMPLE_SEED_DATA | PASS | Tidak ada seed/demo otomatis; user baru melihat empty state. |
| NETWORK_SECURITY | PASS | `usesCleartextTraffic=false`; endpoint pakai HTTPS Supabase; tanpa hardcoded localhost. |
| ERROR_REPORTING | NOT_CONFIGURED | Belum ada crash reporting service (sengaja tidak ditambah utk V1); user-facing error handling bekerja. |
| ACCOUNT_DELETION | PASS | Flow hapus akun diimplementasikan dengan UI multi-step konfirmasi, reauthentication, dan server-authoritative deletion via RPC `public.delete_my_account` (SECURITY DEFINER). Tests ditambahkan. |
| SUPPORT_CONTACT | NOT_CONFIGURED | Email support resmi belum aktif. Placeholder `support@nusarta.com` dihapus; Contact page menampilkan notice "belum dikonfigurasi". Isi `NEXT_PUBLIC_CONTACT_EMAIL` sebelum kampanye. |
| GIT_STATUS | NOT_INITIALIZED | Folder bukan git repository. `key.properties`/`*.jks`/`*.keystore` sudah masuk `.gitignore` root & mobile. |

## Build & Tests (dijalankan pada AGENT 5)

| Check | Status | Hasil |
|-------|--------|-------|
| FLUTTER_ANALYZE | PASS | `flutter analyze` → No issues found |
| FLUTTER_TEST | PASS | `flutter test` → 17/17 lulus (3 file: `models_test.dart` 3 tes, `pin_service_test.dart` 9 tes, `account_deletion_test.dart` 5 tes) |
| DEBUG_APK_BUILD | PASS | `app-debug.apk` 212 MB → SHA-256 `35ffcbffedac7d7ee8c4c392f79298c3c051cc51d124d4c296d3c45e2c6b6f47` |
| RELEASE_SIGNING | NOT_CONFIGURED | Tidak ada `android/key.properties` / `.jks`. `build.gradle` fallback ke debug signing. |
| RELEASE_APK_BUILD | BLOCKED_SIGNING | Belum dibangun — butuh keystore produksi. |
| AAB_BUILD | BLOCKED_SIGNING | Belum dibangun — butuh keystore produksi. |
| RELEASE_SMOKE_TEST | BLOCKED | Tidak ada device/emulator Android tersedia di lingkungan ini. |

FLUTTER_TEST_COUNT: 17 (3 file: `models_test.dart` 3 tes, `pin_service_test.dart` 9 tes, `account_deletion_test.dart` 5 tes)

## Website

| Check | Status | Catatan |
|-------|--------|---------|
| WEB_LINT | PASS | `npm run lint` → no warnings/errors |
| WEB_TYPECHECK | PASS | `tsc --noEmit` bersih |
| WEB_TEST | PASS | `vitest run` → 15/15 |
| WEB_BUILD | PASS | `next build` → 15 rute static |
| DOWNLOAD_PAGE | PASS | Tidak ada link mati. Tanpa checksum → tombol "Segera tersedia". |
| RELEASE_METADATA | PASS | `packages/config/src/release.ts` 1.0.0/+1/konsisten; `checksumSha256` & `fileSizeMb` kosong sampai artifact nyata ada (jujur). |
| CHANGELOG | PASS | `apps/web/src/lib/data.ts` changelog 1.0.0 (ID) lengkap |
| PRIVACY_POLICY | PASS | Halaman `/privacy` jujur (akun, catatan manual, pengaturan, metadata keamanan; bukan bank). |
| DATA_SAFETY_PREP | PASS | Daftar kategori data di bawah ini. |

## Data Safety (informasi untuk form Play Store)

Berdasarkan pemindaian code (bukan asumsi):

- **Collected / Stored (akun, otomatis):**
  - Email (autentikasi) — dibutuhkan untuk login
  - `display_name` (opsional, diisi user saat daftar) — profil dasar
  - Session/token autentikasi (PKCE) — disimpan platform
- **Collected / Stored (diinput user secara manual):**
  - Catatan keuangan: transaksi (jumlah, kategori, catatan), akun (nama, tipe, saldo awal), budget, tujuan keuangan
  - Kunci: alamat/info rekening TIDAK dikumpulkan secara otomatis
- **Stored lokal (device):**
  - PIN hash + salt (flutter_secure_storage, encrypted), setting biometrik & auto-lock, preferensi onboarding/hide balance
- **Shared:**
  - Tidak dibagikan ke pihak ketiga untuk iklan
  - Hanya infrastruktur cloud (Supabase) tempat data akun disimpan
- **Optional:**
  - Biometrik (fingerprint/wajah) — opsional, hanya unlock; pemrosesan di perangkat
- **UNKNOWN_REQUIRES_CONFIRMATION:**
  - Analytics/telemetry: tidak ditemukan di code → dianggap none (konfirmasi sebelum submit form)
  - Crash reporting: belum ada (none)

## Blocker sebelum distribusi

1. ~~**Account deletion** — perlu flow hapus akun (dengan konfirmasi + cascade) sebelum Play Store.~~ ✅ SELESAI
2. **Release keystore** — buat & simpan secara aman; lalu `flutter build apk --release` dan `appbundle --release`.
3. **Supabase live** — project production + `supabase db push` (migrasi 001–004) + RLS terverifikasi 2 akun.
4. **Support email / domain** — alamat dukungan resmi aktif lalu `NEXT_PUBLIC_CONTACT_EMAIL`.
5. **Smoke test device nyata** — jalankan alur Launch → Login → Unlock → CRUD → Laporan → Reopen.

## Kesimpulan

Produk siap sebagai **release candidate** untuk dirilis setelah: keystore
produksi dibuat, APK/AAB release dibangun + checksum, dan blocker support email,
Supabase production deployment, serta smoke test device nyata diselesaikan.

## Account Deletion Architecture (AGENT 6)

Account deletion diimplementasikan dengan pendekatan server-authoritative untuk keamanan:

**Client-side (Flutter):**
- UI multi-step konfirmasi dengan penjelasan yang jelas
- Reauthentication password sebelum deletion
- Final confirmation dengan mengetik "HAPUS"
- Service layer: `AccountDeletionService` dengan gateway pattern
- Gateway hanya menggunakan session authenticated (ANON key), bukan service_role
- Local cleanup: PIN hash, lockout state, biometric preferences, cached data

**Server-side (Supabase RPC):**
- Function: `public.delete_my_account(p_confirm text)` (SECURITY DEFINER)
- Validation: authenticated user, reauth freshness (5 minutes), confirmation text
- Target: selalu `auth.uid()` - tidak menerima arbitrary user_id
- Deletion order: transaction_transfers → transactions → budgets → goals → categories → accounts → app_settings → profiles → auth.users
- Cascade terkontrol untuk menghindari orphan data
- Security: safe search_path, auth.uid validation, input validation

**Tests:**
- Widget tests untuk UI flow
- Mock gateway untuk testing client logic
- Error handling untuk unauthenticated scenarios

**Migration:**
- `004_account_deletion.sql` dengan SECURITY DEFINER function
- Revoke execute from public, grant to authenticated only