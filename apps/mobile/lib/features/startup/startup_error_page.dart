import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/supabase_client.dart';

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
                  onPressed: () async {
                    try {
                      await SupabaseConfig.initialize();
                    } catch (_) {
                      // Keep the page recoverable; the next retry starts from
                      // the same clean state without exposing credentials.
                    }
                    if (context.mounted) context.go('/');
                  },
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
      );
}
