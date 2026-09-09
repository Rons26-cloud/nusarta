# NUSARTA V1 — Release Checklist

Checklists release candidate NUSARTA 1.0.0+1 (`com.nusarta.app`).

Gunakan untuk setiap rilis. Tandai `[x]` saat selesai.

## Code

- [x] `flutter analyze` → tidak ada issue
- [x] `flutter test` → semua lulus
- [x] `dart format --set-exit-if-changed lib test` (wajib dijalankan sebelum rilis)
- [x] Identitas Android: `applicationId`/`namespace` = `com.nusarta.app`, label `NUSARTA`
- [x] Version hanya 1 sumber (pubspec) → diturunkan ke `android/local.properties`

## Tests & Quality

- [x] Unit test PIN (hash, brute-force lockout) lulus
- [x] Unit test model (Account/Transaction) lulus
- [x] Web `lint` / `typecheck` / `test` / `build` lulus
- [ ] Smoke test di device nyata (Launch → Login → Unlock → Dashboard → Tambah transaksi → Laporan → Tutup/buka ulang)

## Security

- [x] RLS aktif di semua tabel (9 tabel)
- [x] PIN di-hash (PBKDF2-style), tidak pernah plaintext
- [x] Brute-force lockout: 5 percobaan → kunci 5 menit
- [x] Biometrik opt-in eksplisit, fallback PIN
- [x] `app_config.dart` untracked; `.env` hanya public anon key
- [x] Tidak ada `service_role`, DB password, atau private key di APK/source
- [x] `cleartextTraffic=false`; tidak ada `localhost` di produksi
- [x] Logging produksi tidak mencatat PIN/password/token (debug config log di-gate `kDebugMode`)
- [x] Tidak ada demo/seed data atau mock auth di alur pengguna normal
- [x] **BLOCKER**: Fitur "Hapus Akun" (account deletion) — diperlukan untuk kepatuhan Play Store; diimplementasikan dengan server-authoritative RPC

## Signing

- [ ] Buat keystore produksi (`keytool`, simpan + backup di luar repo)
- [ ] Isi `android/key.properties.example` → `android/key.properties` (tidak di-commit)
- [ ] `storeFile`/`storePassword`/`keyPassword`/`keyAlias` benar
- [ ] Pastikan `build.gradle` memakai `signingConfigs.release` (bukan debug)
- [ ] Pastikan `key.properties` + `*.jks` + `*.keystore` ada di `.gitignore`

## APK

- [ ] Debug APK build lulus (referensi ukuran/SHA saja — BUKAN untuk distribusi)
- [ ] `flutter build apk --release` → `NUSARTA.apk`
- [ ] APK release ditandatangani keystore produksi
- [ ] Catat ukuran nyata (`ls -lh`) dan SHA-256 (`sha256sum`)
- [ ] Verifikasi `aapt dump badging` → package, versionName, label benar

## AAB

- [ ] `flutter build appbundle --release` → `app-release.aab`
- [ ] AAB ditandatangani keystore produksi (upload key untuk Play)
- [ ] Catat `AAB_PATH` + ukuran + SHA-256

## Website

- [ ] `packages/config/src/release.ts` diisi dengan metadata nyata (version, date, size, sha256, apkFileName)
- [ ] APK final disalin ke `apps/web/public/downloads/<nama-file>` (jika dipublikasikan) atau tombol tetap "Segera tersedia"
- [ ] Halaman `/download` menampilkan: versi, tanggal rilis, min Android, ukuran, SHA-256, tombol unduh
- [ ] Halaman `/changelog` sinkron dengan rilis
- [ ] Tidak ada link mati / checksum dummy
- [ ] `NEXT_PUBLIC_CONTACT_EMAIL` diisi email dukungan resmi (jika sudah aktif)

## Privacy & Legal

- [x] `/privacy` jujur: akun, catatan manual, pengaturan, metadata keamanan
- [x] Tidak ada klaim bank/dompet elektronik/izin payment
- [x] Data Safety list disiapkan (lihat `docs/NUSARTA_RELEASE_STATUS.md`)
- [ ] Terms & privacy link di semua titik pengumpulan data
- [ ] **BLOCKER**: Alamat dukungan resmi belum aktif (placeholder dihapus, form menunggu config)

## Play Store

- [ ] App name: `NUSARTA`
- [ ] Short description (ID) — kandidat:
      “Catat pemasukan, pengeluaran, budget, dan tujuan keuanganmu dengan mudah dan aman.”
- [ ] Full description (ID) — draft di bawah
- [ ] App icon 512×512
- [ ] Feature graphic 1024×500 (emerald/gold/white, “NUSARTA — Keuanganmu, Dalam Kendalimu.”)
- [ ] Screenshot 8 buah: Dashboard, Tambah transaksi, Riwayat, Akun, Laporan, Budget, Tujuan, PIN & biometrik
- [ ] Privacy Policy URL, Support email, Website
- [ ] Category: Finance → Personal Finance
- [ ] Content rating questionnaire disiapkan
- [ ] Data Safety form: data yang benar-benar diproses
- [ ] Target audience & Ads declaration: Tidak ada iklan
- [ ] App access: Kebutuhan login akun

## Full description (ID) — draft

> NUSARTA adalah aplikasi keuangan pribadi dengan pencatatan manual yang
> rapi dan aman: “Keuanganmu, Dalam Kendalimu.”
>
> FITUR UTAMA:
> - Pencatatan pemasukan dan pengeluaran
> - Akun manual: Kas, Bank, E-wallet, Kustom
> - Pindah saldo antar akun NUSARTA (catatan internal)
> - Budget per kategori dengan peringatan saat mendekati batas
> - Tujuan keuangan (dana darurat, tabungan, dan lainnya)
> - Laporan harian, mingguan, bulanan, dan tahunan
> - Dashboard ringkas saldo dan arus kas
>
> KEAMANAN:
> - PIN 6 digit dengan pengunci otomatis aktivitas
> - Tersedia buka dengan biometrik (fingerprint / wajah)
> - Lockout otomatis setelah beberapa percobaan PIN yang salah
> - Isolasi data per pengguna (Row Level Security)
>
> Catatan V1: NUSARTA adalah pencatat keuangan manual. NUSARTA bukan bank,
> tidak menerima simpanan, dan V1 tidak terhubung otomatis ke rekening bank
> atau e-wallet. Pindah saldo hanya memindahkan catatan antar akun di dalam
> aplikasi.

## Artifacts & Checksum

- [ ] Backup artifact final (APK + AAB + keystore) ke storage aman
- [ ] SHA-256 dari build final (bukan build lama/debug)
- [ ] Catat semua jalur & hash di `docs/NUSARTA_RELEASE_STATUS.md`