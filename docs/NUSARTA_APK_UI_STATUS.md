# NUSARTA APK UI — Status

Status: **DALAM PROSES — menunggu verifikasi build di mesin dengan Flutter SDK**
Referensi visual: deep emerald + gold + cream/white, premium clean, rounded cards, mobile-first, logo NUSARTA emas, UI Bahasa Indonesia.

## SPLASH
- DONE. Splash APK sekarang menggunakan **`assets/brand/splash screen.png`** asli (887×1774, portrait) full-bleed (`BoxFit.cover`).
- File asli dengan spasi dibiarkan di `assets/brand/`; salinan bersih `apps/mobile/assets/brand/splash_screen.png` (nama tanpa spasi untuk build; ter-bundle otomatis via `pubspec.yaml` → `assets/brand/`).
- In-app splash (`splash_page.dart`): gambar penuh layar, `FadeTransition` 500ms `easeOut`, background `AppColors.deepEmerald`, navigasi `context.go('/')` setelah 1200ms.
- Native splash Android dirapikan: `drawable/launch_background.xml` + `drawable-v21/launch_background.xml` kini full-screen bitmap `@drawable/splash_full` (`android:gravity="fill"`), asset di `drawable-nodpi/splash_full.png`.
- Android 12/12L+: `values-v31/styles.xml` → `windowSplashScreenBackground #063B2C`, `windowSplashScreenAnimatedIcon @drawable/splash_logo`, `windowFullscreen false` (ikon logo tetap emerald/gold, bukan artwork full).
- Posisi: artwork menutupi seluruh layar → tidak ada cropping bergantung layout; gestur API SPLASH/BESIDE tetap sama.

## PIN_BIOMETRIC
- DONE. `pin_unlock_page.dart`: background `deepEmerald`, judul “Masukkan PIN Anda”, keypad bundar baru (`pin_keypad.dart`, tombol 68×68) dengan `keyFill: primary 28%` (efek gelap-emerald), tombol fingerprint emas `accentLight`, highlight `white24`, hint “atau gunakan biometrik” dan dialog **“Lupa PIN?”** (info: PIN tak bisa dipulihkan; keluar lalu masuk kembali akan membuat PIN baru).
- `pin_setup_page.dart`: keypad light dengan `keyFill: primary 8%`, highlight `primary 18%`, dot `primary`.
- Alur keamanan TIDAK berubah: PIN 6 digit, percobaan gagal → lockout + hitung mundur, biometrik hanya sebagai shortcut buka, `PinDots` sama.

## DASHBOARD
- DONE. Greeting dinamis **“Halo, {Nama} 👋”** (dari data user; huruf pertama dikapitalisasi, fallback “Halo 👋”), sapaan waktu `_timeGreeting()` (pagi<11 / siang<15 / sore<19 / malam), tagline “Keuangan yang baik, dimulai hari ini.” Tidak ada hardcode nama/email.
- Ringkasan saldo + ringkasan transaksi + budget/goals tetap (kartu rounded 16, tombol emerald, teks hijau/kuning-emas hijau/merah = pemasukan/pengeluaran).

## TRANSACTION_FORM
- KONSISTEN (sudah sesuai referensi). Form tambah transaksi sudah memakai field filled rounded, tombol primary emerald, opsi Pemasukan/Pengeluaran, pilih kategori & akun, keterangan opsional, tanggal. Tidak diubah agar tidak risiko.

## ACCOUNTS
- KONSISTEN. Halaman daftar akun (kartu rounded, label tipe akun, saldo hijau/merah) dan tombol “Tambah Akun”. Tidak diubah.

## ACCOUNT_DETAIL
- KONSISTEN. Detail akun + riwayat transaksi per akun; tombol edit/hapus akun tetap. Tidak diubah.

## REPORTS
- DONE (tambahan kecil). Halaman **Laporan** kini menjadi tab bottom nav ke-4 (sebelumnya hanya via link profil) → tetap bisa diakses cepat; seluruh fitur (range harian/mingguan/bulanan/tahunan, ringkasan, donut chart kategori dengan label “Lihat Detail”, alert over-budget) tidak diubah.

## BUDGET
- KONSISTEN. Kartu budget dengan progress bar emerald/gold, alert over-budget, tombol tambah budget. Tidak diubah.

## GOALS
- KONSISTEN. Tujuan keuangan dengan progress & pencapaian. Tidak diubah.

## TRANSFER
- KONSISTEN (placeholder). Screen transfer placeholder tetap (tanpa transfer palsu): menjelaskan transfer antar akun/uang baru akan tersedia; ramah brand.

## SECURITY
- DONE. Settings kini memuat **“Aktivitas Keamanan”** (kartu rounded): daftar 12 event terbaru dari tabel `security_events` (hanya baca) dengan ikon per kategori (auth/security/connection/transfer/account/system), warna sesuai severity (hijau=info, emas=peringatan, merah=kritis), label Indonesian readable, waktu relatif (Baru saja / N menit / N jam / tanggal `d MMM yyyy, HH:mm`), kosong → “Belum ada aktivitas keamanan yang tercatat.”, error → pesan ramah.
- Settings juga mendapat baris **“Tema”** (Ikuti Sistem / Terang / Gelap) tersimpan di secure storage (`theme_mode` → `nusarta.theme_mode`).
- PIN, Biometrik, Auto-lock, Perangkat Terdaftar tetap di tempatnya.

## PROFILE
- KONSISTEN. Profil (avatar inisial, nama + email dinamis dari DB, menu: Pengaturan, Notifikasi, Transfer, Tujuan Keuangan, Budget, Laporan, Pusat Bantuan, Tentang NUSARTA; aksi berbahaya Hapus Akun & Keluar dengan konfirmasi). Tidak diubah.

## BOTTOM_NAV
- DONE. Bottom nav kini **5 tab** sesuai referensi: **Beranda (dashboard) / Transaksi / Akun / Laporan / Lainnya (profil)**. `AppShell` menggunakan `IndexedStack` + `NavigationBar` M3 dengan `indicatorColor primaryLight 15%`, selected-state filled icon, background putih. Tab “Lainnya” merawat akses ke Settings (dan ikon profil default tidak hilang).
- Catatan: referensi menampilkan tab “Lainnya”; keamanan/PIN tetap di Settings yang terdapat dalam profil — tidak ada fungsi kehilangan tempat.

## DARK_LIGHT
- DONE (bug diperbaiki). Sebelumnya `app.dart` hanya `themeMode.system` tanpa `theme`/`darkTheme` → seluruh aplikasi memakai tema default Material. Sekarang: `theme: buildLightTheme()`, `darkTheme: buildDarkTheme()`, `themeMode` dibaca dari `AppSecureStore.themeMode` (system default) via provider `ThemeModeController`.
- Light: scaffold cream (`#F6F0E5`), kartu/appbar putih, primary emerald `#0B6E4F`, secondary gold `#C7A24A`, input filled rounded, FilledButton emerald rounded 12, `ColorScheme.fromSeed`.
- Dark: scaffold hijau sangat gelap `#0E1914`, kartu `#15231D`, input `#15231D` border emerald gelap, FilledButton `primaryLight`, secondary `accentLight`, teks cream.
- Token tambahan di `AppColors` (alias referensi): `deepEmerald`, `gold`, `goldLight`, `cream`, `surface`, `textPrimary`, `textSecondary`, `success`, `danger`, `warning`.

## RESPONSIVE
- Semua halaman memakai `ListView`/`GridView`/`Scaffold` standar Flutter → sudah responsive terhadap ukuran layar & rotasi; DP berbasis `MediaQuery`/Material. SPLASH/DASHBOARD/etc tidak menggunakan ukuran absolut piksel (hanya `double.infinity` untuk full-bleed).

## EXISTING_FUNCTIONALITY_PRESERVED
- DONE. Alur onboarding→PIN→biometrik→dashboard, transaksi CRUD, akun CRUD, report, budget, goals, notifikasi, perangkat, edit-profil, hapus akun, dan keluar **tidak diubah**. Tab “Lainnya” = profil yang sama, jadi semua link lama tetap ada.

## SECURITY_PRESERVED
- DONE. PIN/biometrik/auto-lock/RLS tetap. “Lupa PIN?” hanya menampilkan info (logika tetap: logout→login membuat PIN baru); PIN TIDAK pernah di-reset dari UI. `security_events` hanya dibaca klien (tidak ada penulisan dari APK; penulisan tetap terjadi di backend/auth). Preferensi tema disimpan di secure storage.

## FILES_CHANGED
- `assets/brand/splash screen.png` → `apps/mobile/assets/brand/splash_screen.png` (salinan bersih, ter-bundle via pubspec) & tetap berada di `assets/brand/`.
- `apps/mobile/android/app/src/main/res/drawable-nodpi/splash_full.png` (baru, salinan artwork).
- `apps/mobile/android/app/src/main/res/drawable/launch_background.xml`, `drawable-v21/launch_background.xml` (full-bleed `splash_full`).
- `apps/mobile/android/app/src/main/res/values-v31/styles.xml` (baru; Android 12+ splash).
- `apps/mobile/lib/features/splash/splash_page.dart` (full-bleed + fade).
- `apps/mobile/lib/app.dart` (theme + darkTheme + themeMode provider).
- `apps/mobile/lib/core/theme/app_colors.dart` (token + alias referensi).
- `apps/mobile/lib/core/theme/app_theme.dart` (light/dark lengkap) — (file ini sudah ada, diperluas).
- `apps/mobile/lib/providers/theme_provider.dart` (baru).
- `apps/mobile/lib/core/constants/secure_keys.dart` + `core/security/secure_store.dart` (`theme_mode`).
- `apps/mobile/lib/widgets/pin_keypad.dart` (`keyFill`, `biometricColor`, tombol 68×68).
- `apps/mobile/lib/features/lock/pin_unlock_page.dart` (+ “Lupa PIN?” dialog) dan `pin_setup_page.dart` (gaya).
- `apps/mobile/lib/data/models/security_event.dart` (baru), `data/repositories/security_repository.dart` (baru), `providers/finance_providers.dart` (+`securityEventsProvider`).
- `apps/mobile/lib/features/dashboard/app_shell.dart` (5 tab).
- `apps/mobile/lib/features/dashboard/dashboard_page.dart` (greeting + sapaan waktu).
- `apps/mobile/lib/features/settings/settings_page.dart` (baris Tema + Aktivitas Keamanan).
- `apps/web/public/hero_files/` — DIHAPUS (sampah hasil export chat; bukan dipakai runtime).
- `apps/web/src/components/Hero.tsx` — DIPULIHKAN ke versi asli (hero gambar `/hero.png` + CTA overlay CSS), sesuai konfirmasi user bahwa yang bermasalah hanya CSS, bukan hero-nya.
- `apps/web/src/components/Hero.module.css` — DIPULIHKAN ke versi asli (CTA fleksibel: tumpuk di mobile, absolut terkalibrasi clamp/cqw di desktop).
- `apps/web/public/hero.png` — DIPULIHKAN dari `assets/brand/hero.png` (file asli 1536×1024, 1.931.280 byte; unit identik).

## FLUTTER_ANALYZE
- **BLOCKED di environment ini** (Flutter SDK tidak terpasang). Perubahan belum diverifikasi analyzer resmi.
- Prosedur paksa di mesin developer:
  ```
  cd apps/mobile
  flutter pub get
  dart format .
  flutter analyze
  ```

## FLUTTER_TEST
- **BLOCKED di environment ini** (SDK tidak ada). Prosedur paksa:
  ```
  cd apps/mobile
  flutter test
  ```

## APK_BUILD
- **BLOCKED di environment ini** (SDK tidak ada). Prosedur paksa:
  ```
  cd apps/mobile
  flutter build apk --debug
  ```
  Setelah build, verifikasi visual: splash full-bleed, tab 5, Settings “Tema” & “Aktivitas Keamanan”.

## KNOWN_LIMITATIONS
- Verifikasi visual tidak dapat dilakukan dari environment ini (tidak ada input gambar); perlu review di perangkat/emulator.
- Web `npm run typecheck` & `npm run lint` PASS setelah perbaikan hero (lihat catatan web di laporan ini). Test/build (`vitest` di esbuild «write EPIPE», `next build` SIGBUS) tetap terblokir oleh environment.
- `ThemeModeController.themeMode` getter kini tak terpakai (wiring pindah ke `app.dart`) — tidak berbahaya, opsional dihapus nanti.
- Tab “Lainnya” menampilkan profil; jika diinginkan, bisa dijadikan menu Settings tapi itu mengubah alur (tidak dilakukan agar existing preserved).

## CATATAN WEB (lampiran)
- User mengonfirmasi: yang bermasalah HANYA CSS, bukan hero-nya. Hero versi gambar (`public/hero.png` + CTA overlay) tidak boleh diubah/redesain.
- **Keputusan final**: Hero dikembalikan 100% ke versi asli — `Hero.tsx` (gambar `/hero.png` full-width + dua CTA asli: gold pill “Download NUSARTA” dan outline cream “Lihat Cara Kerja”) dan `Hero.module.css` (mobile: tombol bertumpuk ≥48px; desktop ≥1024px: absolut `left 4% / top 63.5%` dengan ukuran `clamp`/`cqw` agar menyatu dengan artwork).
- `public/hero.png` dipulihkan dari `assets/brand/hero.png` (file sumber unit identik, 1536×1024).
- File sampah yang dihapus permanen (tidak termasuk bagian situs): `public/hero_files/`, dan file review di root web (`hero-fixed-*.jpg`, `hero-check.png`, `hero-original-backup.html`, dll).