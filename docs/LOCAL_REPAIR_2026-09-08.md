# Perbaikan lokal - 8 September 2026

## Struktur
- apps/web: website Next.js; jalankan npm run dev dari root.
- apps/mobile: aplikasi Flutter; localhost website tidak menjalankan APK.
- packages: konfigurasi, UI, types, dan utils bersama.
- supabase: migrasi dan seed backend.
- Saat pemeriksaan 8 September, folder kerja belum memiliki .git. Repository kini terhubung ke Rons26-cloud/nusarta. Cadangan UI lokal tersedia di .ui-audit/before dan tidak disertakan dalam source proyek.

## Perbaikan
- Hapus dependensi langsung Rollup khusus Linux yang membuat npm install gagal dengan EBADPLATFORM pada Windows; perbarui package-lock.json.
- Pisahkan cache Next.js development (.next-dev) dan production (.next). Sebelum perbaikan, build sambil dev berjalan dapat membuat halaman localhost kehilangan CSS. TypeScript mencakup types kedua output; Vitest mengabaikan keduanya.
- Flutter: longgarkan rentang intl agar mengikuti flutter_localizations SDK, perbaiki konstruktor const FeatureFlags, gunakan base.cardTheme.copyWith agar cocok dengan API tema SDK, dan teruskan BuildContext ke tile perangkat.
- Navigasi bawah dan panel info perangkat mengikuti tema, termasuk mode gelap.
- Akun manual dengan status active tidak lagi ditampilkan sebagai Terhubung.
- Perbaiki fixture layanan, viewport, dan teks usang pada tes penghapusan akun. Tidak ada penghapusan akun nyata yang dijalankan.
- Hapus referensi SDK Android Linux yang tidak tersedia dari local.properties; file lokal tersebut sekarang diabaikan Git.

## Verifikasi
- Web: npm install --ignore-scripts berhasil; lint, typecheck, 15 tes, dan build 17 halaman lulus.
- Browser: beranda dan download terbuka, CSS pulih, layout 390 px tidak overflow. Build ulang selama dev aktif tidak lagi merusak CSS.
- Flutter lokal: C:/Users/Asus/flutter, versi 3.47.2 / Dart 3.13.2.
- Flutter: 34 tes lulus; flutter build bundle --debug --no-pub berhasil.
- Analyzer: tidak ada error/warning; masih ada 52 info lint/deprecation. Pemeriksaan memakai --no-fatal-infos; lint penuh belum bersih.
- Android SDK tidak ditemukan oleh flutter doctor. APK baru dan visual di perangkat Android belum diverifikasi. Bundle debug bukan APK.

## Menjalankan di Windows
Dari root:

```powershell
npm install
npm run dev
# Buka http://localhost:3000
```

Flutter sudah ada tetapi belum masuk PATH. Untuk terminal saat ini:

```powershell
$env:Path = "$env:USERPROFILE\flutter\bin;$env:Path"
cd apps/mobile
flutter pub get
flutter test
flutter doctor -v
```

Setelah Android SDK terpasang dan terdeteksi oleh flutter doctor, jalankan flutter build apk --debug. Pertahankan konfigurasi aplikasi lokal yang sudah ada; jangan menimpanya dengan file contoh.
