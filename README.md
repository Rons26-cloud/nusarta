# NUSARTA

**Keuanganmu, Dalam Kendalimu.**

Repository: [Rons26-cloud/nusarta](https://github.com/Rons26-cloud/nusarta).
Maintainer: [Rons26-cloud](https://github.com/Rons26-cloud).

NUSARTA adalah *personal finance platform* untuk mencatat dan mengelola
keuangan pribadi secara manual. V1 terdiri dari aplikasi Android (Flutter),
situs web resmi (Next.js), dan backend Supabase.

> NUSARTA V1 tidak terhubung ke rekening bank/e-wallet, tidak melakukan
> transfer uang asli, dan tidak membaca saldo rekening asli. Arsitektur
> disiapkan agar kelak dapat ditingkatkan menjadi connected-finance tanpa
> menulis ulang aplikasi dari nol.

---

## Repository structure

```
nusarta/
├── apps/
│   ├── mobile/            # Flutter app (Android)
│   └── web/               # Official website (Next.js)
├── packages/
│   ├── config/            # Brand + release + feature flags (shared)
│   ├── ui/                # Shared UI (Logo, Button, Container)
│   ├── types/             # Shared TypeScript types (incl. finance domain)
│   └── utils/             # Shared utilities
├── supabase/
│   ├── migrations/        # Schema + RLS (tracked in Git)
│   └── seed/              # Default categories seed
├── assets/
│   └── brand/             # nusarta02.png (sumber tunggal logo) + nusaarta.png master
├── docs/                  # Architecture, security, RLS, database, roadmap, payments
├── .github/workflows/     # CI (web + mobile)
└── README.md
```

Website dan Flutter tetap independen. Yang dibagikan hanyalah metadata
merek dan rilis melalui `packages/config` sehingga versi tidak
di-hardcode di banyak tempat.

## Roadmap singkat

- **V1 — Personal Finance (Current):** pencatatan manual, laporan, budget,
  goals, PIN, biometrik, cloud sync.
- **V1.5 — Foundation Hardened (sedang dikerjakan):** model multi-account
  extended, katalog institusi, account connection, device management,
  audit/security events, notifications, transfer/recipient foundation,
  feature flags.
- **V2 — Smart Finance (Planned):** import transaksi, kategorisasi otomatis,
  sinkronisasi bila tersedia integrasi resmi.
- **V3 — Connected Finance (Future):** integrasi API keuangan resmi,
  saldo tersinkronisasi, transfer bila didukung legal dan teknis.

Fitur V2/V3 **belum tersedia**. Lihat [roadmap publik](/roadmap).

---

## Development

### Prasyarat

- Node.js ≥ 18 + npm (workspaces)
- Flutter 3.24+ / Dart 3.5+ (untuk mobile)

### Web

```bash
npm install          # dari root — memasang workspaces
npm run dev          # dev server (apps/web)
npm run lint         # eslint
npm run typecheck    # tsc --noEmit
npm run test         # vitest
npm run build        # next build
```

### Mobile

```bash
cd apps/mobile
flutter pub get
cp lib/core/config/app_config.example.dart lib/core/config/app_config.dart
# isi SUPABASE_URL dan SUPABASE_ANON_KEY
flutter run
```

Kunci **anon** aman untuk klien. Jangan pernah menaruh `service_role`,
kata sandi database, atau kunci penandatangan di kode klien.

### Supabase

1. Buat project Supabase (atau `supabase start`).
2. Jalankan migrasi berurutan:
   `supabase/migrations/001_initial_schema.sql`
   `supabase/migrations/002_row_level_security.sql`
   `supabase/migrations/003_ledger_transfer_rls.sql`
   `supabase/migrations/004_account_deletion.sql`
   `supabase/migrations/005_future_foundation.sql`
   `supabase/migrations/006_future_foundation_rls.sql`
   `supabase/migrations/007_account_deletion_extended.sql`
   `supabase/migrations/008_future_foundation_harden.sql`
   (atau sekali dengan `supabase db push`)
3. Verifikasi RLS dengan dua akun — lihat [docs/RLS_TESTING.md](docs/RLS_TESTING.md).

### Environment (web)

Salin `apps/web/.env.example` → `apps/web/.env.local`. Hanya nilai publik
yang boleh dirender. `NEXT_PUBLIC_SITE_URL` diisi saat domain final.

---

## Testing

| Area        | Perintah                          |
| ----------- | --------------------------------- |
| Web lint    | `npm run lint`                    |
| Web type    | `npm run typecheck`               |
| Web tests   | `npm test`                        |
| Web build   | `npm run build`                   |
| Mobile fmt  | `dart format lib test`            |
| Mobile ana  | `flutter analyze`                 |
| Mobile test | `flutter test`                    |

Rilis apa pun wajib **PASS** untuk semua yang di atas.

## Release process

### Build debug

```bash
cd apps/mobile
flutter pub get
flutter build apk --debug
# hasil: build/app/outputs/flutter-apk/app-debug.apk
```

Artifact debug **bukan** untuk distribusi — hanya untuk pengujian lokal.

### Build release (butuh keystore produksi)

```bash
cd apps/mobile
flutter build apk --release       # → NUSARTA.apk
flutter build appbundle --release # → app-release.aab (Play Store)
```

Tanpa `android/key.properties` build tetap jalan tetapi **ditandatangani
dengan debug key** — jangan pernah distribusikan build tersebut.

### Signing setup

1. Buat keystore:
   `cd apps/mobile/android && keytool -genkeypair -v -keystore keystore-release.jks -alias nusarta -keyalg RSA -keysize 2048 -validity 10000`.
2. `cp key.properties.example key.properties` dan isi password/alias/storeFile.
3. **Jangan pernah commit** `key.properties`, `*.jks`, `*.keystore` (sudah di `.gitignore`).
4. Simpan backup keystore + password di luar repo.

### Environment (mobile build)

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...
```

`app_config.dart` tidak di-track; nilai datang dari `--dart-define` saat build.
Hanya anon key yang boleh di-bundle — `service_role`/password DB tidak pernah
(di kode klien maupun APK).

### Version bump

1. Bump `version:` di `apps/mobile/pubspec.yaml` (satu-satunya sumber kebenaran).
2. Build berikutnya menurunkan `flutter.versionCode/versionName` ke `android/local.properties`.
3. Sinkronkan `packages/config/src/release.ts` (versi, build, tanggal).
4. Isi checklist: [docs/RELEASE_CHECKLIST.md](docs/RELEASE_CHECKLIST.md).

### Publish artifact (website)

1. Siapkan APK final bertanda tangan rilis di `apps/mobile/build/app/outputs/flutter-apk/NUSARTA.apk`.
2. Copy ke `apps/web/public/downloads/NUSARTA.apk`; jangan pindahkan sumber.
3. Jalankan `node scripts/generate-apk-metadata.mjs` dan `npm run build`.
4. Sertakan APK sebagai deployment artifact pada path `/downloads/NUSARTA.apk`. Binary tidak disimpan di Git.

Detail: [docs/RELEASE.md](docs/RELEASE.md) ·
Checklist: [docs/RELEASE_CHECKLIST.md](docs/RELEASE_CHECKLIST.md) ·
Status: [docs/NUSARTA_RELEASE_STATUS.md](docs/NUSARTA_RELEASE_STATUS.md).

## Security notes

- RLS wajib aktif di semua tabel (lihat migrasi RLS).
- PIN disimpan sebagai hash dengan salt, bukan plaintext.
- Klien hanya memegang anon key.
- Jangan mengklaim keamanan "100%".

Detail: [docs/SECURITY.md](docs/SECURITY.md).

## Domain masa depan

Arsitektur disiapkan untuk `nusarta.com`, `www`, `app`, `api`, `status`,
`docs` — tetapi V1 tidak membuat layanan kosong untuk memenuhi subdomain.
Website resmi (V1) diarahkan ke `www.nusarta.com` saat domain final.

---

© NUSARTA
