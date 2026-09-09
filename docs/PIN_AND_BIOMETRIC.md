# PIN & Biometric — Alur Kunci Aplikasi

## Flow membuka aplikasi

```
Buka aplikasi
   │
   ├─ Biometric tersedia & diaktifkan
   │     → Biometric → Dashboard
   │
   └─ Biometric gagal / tidak tersedia
         → PIN 6 digit → Dashboard
```

Setelah terbuka, pengguna dapat memakai aplikasi tanpa autentikasi ulang
sampai **auto-lock** berlaku (bawaan 5 menit, dapat diatur).

## Aturan penting

- PIN **tidak** diminta setiap kali mencatat transaksi.
- PIN 6 digit, disimpan sebagai hash (bukan plaintext).
- Biometric perangkat: fingerprint / face, hanya saat membuka aplikasi.
- **Anti brute-force:** setelah 5 percobaan PIN salah berturut-turut, PIN
  terkunci selama 5 menit. Percobaan yang benar me-reset penghitung.
- Lupa PIN? PIN bersifat lokal per perangkat. Keluar (logout) dari akun
  menghapus file secure storage lokal (termasuk PIN), lalu masuk kembali dan
  buat PIN baru.

## Implementasi (Dart)

- `lib/core/security/pin_service.dart` — set/verify PIN (hash + salt).
- `lib/core/security/biometric_service.dart` — unlock via local_auth.
- `lib/core/security/auto_lock_service.dart` — penentuan kunci ulang.
- `lib/core/router/app_router.dart` — gate terpusat (session → PIN →
  lock → aplikasi).

## Implementasi (website)

Halaman `/how-it-works` menjelaskan alur ke pengguna non-teknis.