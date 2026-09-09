# Release Process

## Sumber kebenaran versi

Versi Android berasal dari `apps/mobile/pubspec.yaml` dan diselaraskan ke `packages/config/src/release.ts`.
Ukuran dan SHA-256 berasal dari APK publik melalui `scripts/generate-apk-metadata.mjs`.

Situs web (`apps/web/src/app/download`, `sitemap`, dll.) membaca dari sana.
Jangan hardcode versi di tempat lain.

## Signing setup (Android)

Production releases must be signed with a real keystore. AGENT 5 wired
`apps/mobile/android/app/build.gradle` to read `apps/mobile/android/key.properties`
when present, and to **fall back to debug signing** otherwise (so development
keystores and CI stays buildable — never distribute a debug-signed build).

```bash
# 1. Generate a keystore (one-time, keep it SAFE and backed up)
cd apps/mobile/android
keytool -genkeypair -v -keystore keystore-release.jks \
  -alias nusarta -keyalg RSA -keysize 2048 -validity 10000

# 2. Create key.properties from the template (NEVER commit this file)
cp key.properties.example key.properties
# fill: storePassword=… keyPassword=… keyAlias=nusarta storeFile=keystore-release.jks
```

Security rules:

- `android/key.properties` and all `*.jks` / `*.keystore` are git-ignored.
- The template `android/key.properties.example` may be tracked (no secrets).
- Keep a backup of the keystore AND its password outside the repo.
- Signing config falls back to debug keys only when `key.properties` is absent —
  a debug-signed "release" APK must never be published.

## Version bump process

Satu sumber kebenaran: `apps/mobile/pubspec.yaml` (`version: X.Y.Z+N`).

1. Bump version di `pubspec.yaml`.
2. Build berikutnya menurunkan `flutter.versionCode` / `flutter.versionName`
   ke `android/local.properties` dari pubspec (bukan sumber versi tersendiri).
3. Sinkronkan `packages/config/src/release.ts` (`version`, `buildNumber`).
4. Ikuti checklist `docs/RELEASE_CHECKLIST.md`.

## Langkah

### 1. Build APK

```bash
cd apps/mobile
flutter build apk --release
```

### 2. Salin ke direktori publik website

```bash
APK=build/app/outputs/flutter-apk/NUSARTA.apk
cp "$APK" ../web/public/downloads/NUSARTA.apk
```

### 3. Generate metadata

Dari root project: `node scripts/generate-apk-metadata.mjs`.
Script membaca APK publik dan menghasilkan `packages/config/src/apk-metadata.ts`.
Prebuild dan predev menjalankannya kembali; file yang hilang atau kosong menghentikan proses.
Versi, build, tanggal, minimum Android, dan catatan rilis tetap dikelola di `packages/config/src/release.ts`.

### 4. Update changelog

Tambahkan entri baru di `apps/web/src/lib/data.ts` (list `changelog`).

### 5. Verifikasi

```bash
npm run lint && npm run typecheck && npm test && npm run build
cd apps/mobile && flutter analyze && flutter test
```

### 6. Checkpoint

Setelah testing, isi laporan phase (lihat README).

## Checksum

Website menampilkan SHA-256 **hanya jika** `checksumSha256` terisi.
Jangan menampilkan angka dummy.

## Nota keamanan

- Hanya APK dari build resmi.
- APK tidak boleh berisi `service_role` key, password DB, atau signing key.
- Jika domain belum final, biarkan `NEXT_PUBLIC_SITE_URL` kosong
  (download fallback ke path relatif).
## Deployment artifact

Copy hanya NUSARTA.apk ke public/downloads sebelum build web. Jangan menyalin folder signing atau environment.
URL publik tetap `/downloads/NUSARTA.apk`; file disertakan dalam artifact deployment, bukan Git.
Folder kerja saat ini tidak memiliki metadata .git, sehingga status tracking tidak dapat diperiksa.

## Validasi artifact yang diberikan

APK sumber saat pemeriksaan memiliki signature v2 valid tetapi sertifikat Android Debug.
Halaman dan unduhan dapat diuji lokal; untuk distribusi produksi gunakan NUSARTA.apk yang ditandatangani sertifikat rilis.
