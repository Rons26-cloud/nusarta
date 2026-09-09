import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StartupErrorPage extends StatelessWidget {
  const StartupErrorPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 16),
                const Text('NUSARTA belum siap dimulai.'),
                const SizedBox(height: 8),
                const Text('Periksa konfigurasi atau coba lagi.'),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.go('/splash'),
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
      );
}
