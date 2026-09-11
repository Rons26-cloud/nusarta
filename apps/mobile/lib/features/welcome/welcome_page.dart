import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/nusarta_brand.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepEmerald,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const NusartaBrandHeader(dark: true),
                  const SizedBox(height: 20),
                  const SizedBox(height: 16),
                  Text(
                    'Catat pemasukan, pengeluaran, dan transfer antar akun '
                    'dalam satu aplikasi yang sederhana dan aman.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: 32),
                  NusartaPrimaryButton(
                      label: 'Mulai',
                      onPressed: () => context.push('/register')),
                  const SizedBox(height: 12),
                  NusartaSecondaryButton(
                      label: 'Masuk', onPressed: () => context.push('/login')),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shield_outlined,
                          size: 14, color: AppColors.accentLight),
                      const SizedBox(width: 6),
                      Text(
                        'PIN 6 digit & biometrik untuk melindungi datamu.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.neutral),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
