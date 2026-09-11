import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/feature_flags.dart';
import '../../core/theme/app_colors.dart';

class TransferPage extends StatelessWidget {
  const TransferPage({super.key});

  @override
  Widget build(BuildContext context) {
    final enabled = FeatureFlags.isEnabled(FeatureFlag.transfers);

    return Scaffold(
      appBar: AppBar(title: const Text('Transfer')),
      body: enabled
          ? const Center(child: SizedBox.shrink())
          : const _ComingSoon(),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AppColors.deepEmerald, AppColors.primaryDark]),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.gold.withAlpha(80)),
          ),
          child: Column(children: [
            Image.asset('assets/brand/logo.png',
                width: 72, height: 72, fit: BoxFit.contain),
            const SizedBox(height: 24),
            const Icon(Icons.swap_horiz_rounded,
                size: 48, color: AppColors.goldLight),
            const SizedBox(height: 16),
            const Text('Transfer',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('Segera Hadir',
                style: TextStyle(
                    color: AppColors.goldLight, fontWeight: FontWeight.w700)),
            const SizedBox(height: 24),
            const Text(
                'Transfer melalui provider resmi akan tersedia di versi mendatang, setelah integrasi dan persetujuan pengguna siap.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.cream, height: 1.6)),
          ]),
        ),
        const SizedBox(height: 24),
        const Text(
            'Saat ini NUSARTA membantu mencatat keuangan secara manual. Pindah Saldo hanya memindahkan catatan antar akun, bukan mengirim uang.',
            textAlign: TextAlign.center),
        const SizedBox(height: 24),
        OutlinedButton(
            onPressed: () => context.pop(), child: const Text('Kembali')),
      ]),
    ));
  }
}

class TransferInfoBanner extends StatelessWidget {
  const TransferInfoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (FeatureFlags.isEnabled(FeatureFlag.transfers)) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accent.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.hourglass_top_rounded,
              size: 18, color: AppColors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Transfer ke bank/e-wallet segera hadir. Kamu tetap bisa '
              'memindahkan saldo antar akun NUSARTA melalui "Pindah Saldo".',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
