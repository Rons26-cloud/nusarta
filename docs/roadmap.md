# Roadmap

Visibilitas ekonomi publik (route `/roadmap` di website) dan sumber kebenaran
pengembangan.

## NUSARTA V1 — Personal Finance (Sekarang)

- Pencatatan manual: akun (Kas, Bank, E-wallet, Kustom)
- Transaksi pemasukan / pengeluaran / pindah saldo internal
- Budget per kategori, goals, laporan
- PIN 6 digit + biometrik + auto-lock
- RLS penuh, sync cloud Supabase
- Website marketing + halaman keamanan

## NUSARTA V1.5 — Foundation Hardened (sedang dikerjakan)

- Model financial account multi, extended dengan `institution_id`,
  `connection_type`, `connection_status`, `masked_account_number`
- Katalog `institutions` (bank / e-wallet) — metadata, **bukan** claim integrasi
- Tabel `account_connections` (siklus hidup koneksi, consent, scopes)
- Tabel `devices` (manajemen perangkat: trusted, revoked, last seen)
- Tabel `security_events` + `audit_events` diperluas
- Tabel `notifications` (in-app; push via FCM saat diaktifkan) + RPC
  `create_user_notification` (jalur aman menulis, jenis V1 saja)
- Tabel `future_transfers` + `transfer_recipients` (fondasi transfer)
- Tabel `feature_flags` + gerbang kapabilitas di web & Flutter
- Boundary backend terdokumentasi (provider adapter, idempotency, webhook)

### Tren UI akun (sudah berjalan)

- Form akun: katalog lembaga (bank/e-wallet) + nama, saldo awal, 4 digit
  terakhir opsional, toggle akun utama — selalu `Manual` (tanpa claim koneksi)
- Daftar akun: badge status reusable (Manual / Terhubung / Menunggu /
  Perlu Perhatian / Dicabut) + detail akun (lembaga, nama, saldo, tipe,
  status koneksi, sinkron terakhir, transaksi, ubah, arsip)
- Perangkat: halaman `Perangkat` read-only + garis besar di Pengaturan;
  registrasi perangkat saat app dibuka
- Notifikasi: halaman notifikasi + lonceng dashboard dengan jumlah belum
  dibaca
- Transfer eksternal: halaman placeholder "segera hadir" (flag `transfers`
  tetap OFF, tanpa form tujuan palsu)

## NUSARTA V2 — Smart Finance (Planned)

- Provider integration resmi (tergantung legal & ketersediaan API)
- Hubungkan rekening bank & e-wallet yang didukung saat integrator aktif
- Sinkronisasi saldo (`provider_balance` + `balance_source = provider`)
- Sinkronisasi transaksi (`source = bank_api` / `wallet_api`)
- Consent / token lifecycle + webhook signature verification
- Kategorisasi otomatis, import transaksi

## NUSARTA V3 — Connected Finance (Future)

- Transfer bank / e-wallet melalui provider berizin
- Validasi penerima, biaya transfer, limit, resi
- Step-up authentication untuk aksi sensitif
- Rekonsiliasi + risk controls
- Settlement server + webhook (final status dari backend/provider,
  bukan dari client)

## Prinsip

- **Tidak ada fake integration.** Semua V2/V3 membutuhkan provider resmi.
- Feature flag default **OFF** hingga backend + provider siap.
- Transfer real **tidak** diaktifkan tanpa provider resmi.