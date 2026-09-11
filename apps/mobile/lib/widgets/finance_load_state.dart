import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FinanceLoadError extends StatelessWidget {
  const FinanceLoadError(
      {super.key, required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  static String messageFor(Object error) {
    if (error is SocketException ||
        error is TimeoutException ||
        error is HandshakeException) {
      return 'Koneksi terputus. Periksa internet lalu coba lagi.';
    }
    if (error is AuthException ||
        (error is PostgrestException &&
            ['PGRST301', 'PGRST302', 'PGRST303', '42501']
                .contains(error.code))) {
      return 'Akses akun belum tersedia. Periksa sesi masuk Anda.';
    }
    if (error is PostgrestException) {
      return 'Data belum dapat dimuat dari server. Silakan coba lagi.';
    }
    return 'Data belum dapat ditampilkan. Silakan coba lagi.';
  }

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.cloud_off_outlined,
                size: 36, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text('Belum dapat memuat data',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(messageFor(error), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi')),
          ]),
        ),
      );
}
