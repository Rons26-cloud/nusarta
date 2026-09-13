import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';

class AboutNusartaPage extends StatelessWidget {
  const AboutNusartaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOff,
      appBar: AppBar(title: const Text('Tentang NUSARTA')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.deepEmerald, AppColors.primaryDark]),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.gold.withAlpha(90)),
            ),
            child: Column(children: [
              Image.asset('assets/brand/logo.png',
                  width: 96, height: 56, fit: BoxFit.contain),
              const SizedBox(height: 12),
              const Text('NUSARTA',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2)),
              const SizedBox(height: 4),
              const Text(AppConfig.tagline,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.goldLight, fontWeight: FontWeight.w700)),
            ]),
          ),
          const SizedBox(height: 18),
          const _AboutSection(title: 'APA ITU NUSARTA', children: [
            'NUSARTA (Nusa + Arta) adalah aplikasi pencatatan keuangan pribadi '
                'untuk mencatat pemasukan dan pengeluaran, mengelola akun, '
                'mengatur budget, dan memantau tujuan keuangan.',
            'NUSARTA bukan bank: tidak menerima simpanan, tidak melakukan '
                'transfer uang asli, dan tidak terhubung langsung ke rekening '
                'bank pada V1.',
          ]),
          const _AboutSection(title: 'FITUR UTAMA', children: [
            'Transaksi pemasukan & pengeluaran dengan kategori.',
            'Akun Kas/Tunai, Bank, E-Wallet, dan kustom.',
            'Budget bulanan dan tujuan keuangan.',
            'Laporan dan grafik aliran kas.',
            'Keamanan perangkat: PIN dan biometrik.',
            'Sinkronisasi cloud antar perangkat (per akun).',
          ]),
          const _AboutSection(title: 'TEKNOLOGI', children: [
            'Aplikasi dibangun dengan Flutter. Autentikasi, database, dan '
                'penyimpanan file memakai Supabase dengan kebijakan akses per '
                'pengguna (Row Level Security).',
            'Nama, logo, dan konten NUSARTA dilindungi hak kekayaan '
                'intelektual.',
          ]),
          const SizedBox(height: 20),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.info_outline_rounded),
            label: const Text('Lihat Informasi Versi'),
            style:
                FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: () => context.push('/version'),
          ),
        ],
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.title, required this.children});
  final String title;
  final List<String> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 15)),
              const SizedBox(height: 10),
              for (final text in children)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(text,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.neutral, height: 1.5)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
