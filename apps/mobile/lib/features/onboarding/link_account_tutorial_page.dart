import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Step-by-step visual guide for connecting a bank/e-wallet account.
/// Providers that are not live yet are clearly labeled "Segera Hadir" —
/// no fake active flow is ever shown.
class LinkAccountTutorialPage extends StatelessWidget {
  const LinkAccountTutorialPage({super.key});

  static const _steps = <(String, String)>[
    ('Buka Akun', 'Masuk ke tab Beranda, lalu buka halaman "Akun keuangan".'),
    (
      'Pilih Tambah / Hubungkan Akun',
      'Tekan tombol "Hubungkan Akun" atau tambahkan lewat daftar akun.'
    ),
    (
      'Pilih Bank atau E-Wallet',
      'Pilih kategori bank atau e-wallet dari katalog institusi.'
    ),
    (
      'Pilih institusi',
      'Ketuk kartu institusi, contohnya BCA, Mandiri, GoPay, atau DANA.'
    ),
    (
      'Lanjutkan ke authorization resmi',
      'NUSARTA akan mengarahkanmu ke halaman otorisasi resmi provider.'
    ),
    (
      'Berikan consent',
      'Setujui akses yang diminta. NUSARTA tidak pernah meminta PIN, '
          'kata sandi, atau OTP bank.'
    ),
    (
      'Kembali ke NUSARTA',
      'Setelah otorisasi, kamu akan diarahkan kembali ke aplikasi.'
    ),
    (
      'Akun berhasil terhubung',
      'Akun muncul di daftar dengan nomor yang disamarkan dan status sinkron.'
    ),
    (
      'Sinkron transaksi',
      'Transaksi tersinkron otomatis dan tidak pernah diduplikasi.'
    ),
    (
      'Lihat dashboard & laporan',
      'Saldo, pengeluaran, dan laporan diperbarui dari data provider.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOff,
      appBar: AppBar(title: const Text('Panduan Menghubungkan Akun')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.deepEmerald, AppColors.primaryDark]),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.gold.withAlpha(90)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.timeline_rounded, color: AppColors.goldLight),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Cara kerja penyambungan akun sangat bergantung pada '
                    'provider resmi. Selama provider belum aktif, setiap '
                    'institusi diberi label "Segera Hadir".',
                    style: TextStyle(
                        color: AppColors.cream, height: 1.5, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < _steps.length; i++)
            _StepCard(index: i + 1, title: _steps[i].$1, body: _steps[i].$2),
          const SizedBox(height: 10),
          Text(
            'NUSARTA menggunakan hanya OAuth resmi, API resmi, atau provider '
            'open-finance berizin. Tidak ada koneksi palsu yang ditampilkan.',
            textAlign: TextAlign.center,
            style:
                TextStyle(color: AppColors.neutral, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.index,
    required this.title,
    required this.body,
  });

  final int index;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withAlpha(20),
                child: Text('$index',
                    style: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14.5)),
                    const SizedBox(height: 4),
                    Text(body,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.neutral, height: 1.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
