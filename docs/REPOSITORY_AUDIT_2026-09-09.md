# Audit repository - 9 September 2026

## Struktur

- `apps/web`: website Next.js.
- `apps/mobile`: aplikasi Flutter.
- `packages/config`, `ui`, `types`, `utils`: workspace bersama.
- `supabase`: migrasi dan seed database.
- `scripts`: pembuatan metadata APK.
- `docs`: arsitektur, prosedur pengujian, dan rilis.
- `.github/workflows`: CI web dan mobile.

Folder eksperimen `.mini-test` dan cadangan `.ui-audit` dikeluarkan dari
pelacakan Git, tetapi salinan lokal dipertahankan. Konfigurasi alat lokal
yang tidak diperlukan dihapus. Nama proyek tetap `nusarta`, dengan maintainer
`Rons26-cloud` dan remote `https://github.com/Rons26-cloud/nusarta.git`.

## Verifikasi

| Pemeriksaan | Hasil |
| --- | --- |
| Web lint | Lulus, tanpa warning/error |
| Web TypeScript | Lulus |
| Web unit tests | 16 tes lulus |
| Web production build | Lulus, 17 halaman statis |
| Flutter analyze/test | Belum diulang; executable tidak tersedia di PATH sesi audit |

## Temuan yang masih terbuka

- `apps/mobile/android/app/build.gradle` memakai debug signing jika keystore
  rilis tidak tersedia. Artefak demikian tidak layak dipublikasikan sebagai rilis.
- CI mobile menggunakan Flutter 3.24.3, sementara laporan lokal sebelumnya
  mencatat Flutter 3.47.2. Kompatibilitas versi CI perlu diverifikasi tersendiri.
- Audit ini mencakup struktur, metadata repository, dan pemeriksaan web.
  Pengujian keamanan database, alur aplikasi mobile, dan integrasi GitHub yang
  terpasang belum diverifikasi.
