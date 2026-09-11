import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/account_deletion_service.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/lock_provider.dart';

enum _DeletionStep { verify, confirm }

class DeleteAccountPage extends ConsumerStatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  ConsumerState<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends ConsumerState<DeleteAccountPage> {
  _DeletionStep _step = _DeletionStep.verify;
  bool _busy = false;
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  String _email = '';
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _email = ref.read(accountDeletionServiceProvider).signedInUserEmail ?? '';
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  bool get _passwordReady =>
      _email.trim().isNotEmpty && _passwordController.text.isNotEmpty;

  bool get _confirmationReady {
    final typed = _confirmationController.text.trim().toUpperCase();
    return typed == 'HAPUS' && _confirmationController.text.trim() == typed;
  }

  Future<void> _confirmAndDelete() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref.read(accountDeletionServiceProvider).deleteAccount(
          email: _email.trim(),
          password: _passwordController.text,
          confirmation: _confirmationController.text.trim(),
        );
    if (!mounted) return;

    if (result.ok) {
      await ref.read(lockControllerProvider).logout();
      if (!mounted) return;
      context.go('/');
      return;
    }

    setState(() {
      _busy = false;
      _error = _messageFor(result);
    });
  }

  String _messageFor(DeleteAccountResult result) {
    switch (result.error) {
      case DeleteAccountError.unauthenticated:
        return 'Sesi kamu telah berakhir. Masuk kembali untuk melanjutkan.';
      case DeleteAccountError.reauthenticationFailed:
        return 'Kata sandi salah. Periksa kembali kata sandimu.';
      case DeleteAccountError.network:
        return 'Tidak ada koneksi internet. Periksa jaringanmu.';
      case DeleteAccountError.server:
        return 'Layanan penghapusan akun sedang tidak tersedia. Coba lagi nanti.';
      case DeleteAccountError.confirmation:
      case DeleteAccountError.none:
        return 'Konfirmasi belum valid.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final canLeave = !_busy;
    return PopScope(
      canPop: canLeave,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Hapus Akun'),
          automaticallyImplyLeading: canLeave,
        ),
        body: _busy
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Menghapus akun dan data keuangan...'),
                  ],
                ),
              )
            : _step == _DeletionStep.verify
                ? _buildVerify()
                : _buildConfirm(),
      ),
    );
  }

  Widget _buildVerify() {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Hapus akun NUSARTA?',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Card(
          color: AppColors.expense.withAlpha(15),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Data akun dan catatan keuangan yang terkait akan dihapus '
              'secara permanen. Tindakan ini tidak dapat dibatalkan.',
              style: TextStyle(color: Color(0xFF7E2419)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Yang akan dihapus permanen:',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const _Bullet(text: 'Akun dan email NUSARTA'),
        const _Bullet(text: 'Semua akun keuangan, transaksi, dan pindah saldo'),
        const _Bullet(text: 'Kategori, budget, dan tujuan keuangan'),
        const _Bullet(text: 'Pengaturan aplikasi di server'),
        const _Bullet(text: 'Sesi login di semua perangkat'),
        const SizedBox(height: 16),
        Text(
          'Untuk keamanan, masukkan kembali kata sandi akunmu '
          'sebagai verifikasi.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: _email,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          obscureText: true,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Kata sandi',
            border: OutlineInputBorder(),
            helperText: 'Diperlukan untuk verifikasi ulang',
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _passwordReady
              ? () => setState(() => _step = _DeletionStep.confirm)
              : null,
          child: const Text('Lanjut'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.expense)),
        ],
      ],
    );
  }

  Widget _buildConfirm() {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Hapus akun secara permanen?',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Card(
          color: AppColors.expense.withAlpha(15),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Akun $_email dan semua data terkait akan dihapuskan dari '
              'server. Tidak ada cara untuk mengembalikannya.',
              style: const TextStyle(color: Color(0xFF7E2419)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Ketik HAPUS untuk konfirmasi terakhir.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _confirmationController,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Ketik: HAPUS',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.expense,
            foregroundColor: Colors.white,
          ),
          onPressed: _confirmationReady ? _confirmAndDelete : null,
          child: const Text('Hapus Akun'),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _step = _DeletionStep.verify;
              _error = null;
            });
          },
          child: const Text('Batal'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.expense)),
        ],
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          const Icon(Icons.remove_circle_outline,
              size: 18, color: AppColors.expense),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
