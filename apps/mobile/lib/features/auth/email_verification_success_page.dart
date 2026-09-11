import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/nusarta_brand.dart';

class EmailVerificationSuccessPage extends StatelessWidget {
  final VoidCallback? onContinue;
  const EmailVerificationSuccessPage({super.key, this.onContinue});

  @override
  Widget build(BuildContext context) {
    return NusartaAuthScaffold(
      artworkAsset: 'assets/brand/email_verifikasi.png',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.verified_rounded, color: AppColors.gold, size: 48),
          const SizedBox(height: 14),
          Text(
            'Email Berhasil Diverifikasi!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Akun kamu sekarang aktif. Lanjutkan untuk membuat PIN keamanan.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.neutral, height: 1.4),
          ),
          const SizedBox(height: 26),
          NusartaPrimaryButton(
            label: 'Lanjutkan',
            onPressed: onContinue ?? () => context.go('/pin-setup'),
          ),
          const SizedBox(height: 20),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _TrustItem(icon: Icons.shield_outlined, label: 'Aman'),
              _TrustItem(icon: Icons.touch_app_outlined, label: 'Mudah'),
              _TrustItem(icon: Icons.verified_outlined, label: 'Terpercaya'),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppColors.neutral)),
      ],
    );
  }
}
