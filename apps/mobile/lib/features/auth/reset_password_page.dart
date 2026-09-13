import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/password_recovery_provider.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});
  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _hidden = true,
      _confirmationHidden = true,
      _loading = false,
      _saved = false;
  String? _error;
  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _restart() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(passwordRecoveryProvider).finish();
      if (mounted) context.go('/forgot-password');
    } catch (e) {
      if (mounted) setState(() => _error = recoveryError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_loading || (!_saved && !_form.currentState!.validate())) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final recovery = ref.read(passwordRecoveryProvider);
      if (!_saved) {
        await recovery.updatePassword(_password.text);
        _saved = true;
        _password.clear();
        _confirmation.clear();
      }
      await recovery.finish();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Kata sandi berhasil diperbarui. Silakan masuk dengan kata sandi baru.'),
      ));
      context.go('/login');
    } catch (e) {
      if (mounted) {
        setState(() => _error = _saved
            ? 'Kata sandi sudah diperbarui. Tekan Kembali ke Login untuk menyelesaikan sesi.'
            : recoveryError(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        child: Scaffold(
          appBar: AppBar(
              automaticallyImplyLeading: false,
              title: const Text('Reset Kata Sandi')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Buat kata sandi baru untuk akun NUSARTA kamu.'),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _password,
                      obscureText: _hidden,
                      enabled: !_loading && !_saved,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                          labelText: 'Kata Sandi Baru',
                          suffixIcon: IconButton(
                              tooltip: _hidden
                                  ? 'Tampilkan kata sandi'
                                  : 'Sembunyikan kata sandi',
                              onPressed: () =>
                                  setState(() => _hidden = !_hidden),
                              icon: Icon(_hidden
                                  ? Icons.visibility_off
                                  : Icons.visibility))),
                      validator: (v) =>
                          (v?.length ?? 0) >= 6 ? null : 'Minimal 6 karakter',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmation,
                      obscureText: _confirmationHidden,
                      enabled: !_loading && !_saved,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                          labelText: 'Konfirmasi Kata Sandi Baru',
                          suffixIcon: IconButton(
                              tooltip: _confirmationHidden
                                  ? 'Tampilkan konfirmasi'
                                  : 'Sembunyikan konfirmasi',
                              onPressed: () => setState(() =>
                                  _confirmationHidden = !_confirmationHidden),
                              icon: Icon(_confirmationHidden
                                  ? Icons.visibility_off
                                  : Icons.visibility))),
                      validator: (v) =>
                          v == _password.text ? null : 'Kata sandi tidak sama',
                      onFieldSubmitted: (_) => _save(),
                    ),
                    if (_error != null)
                      Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(_error!)),
                    if (!_saved)
                      TextButton(
                          onPressed: _loading ? null : _restart,
                          child: const Text('Minta kode pemulihan baru')),
                    const SizedBox(height: 24),
                    FilledButton(
                        onPressed: _loading ? null : _save,
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : Text(_saved
                                ? 'Kembali ke Login'
                                : 'Simpan Kata Sandi')),
                  ],
                )),
          ),
        ),
      );
}
