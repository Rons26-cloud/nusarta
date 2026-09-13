import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/email_validation.dart';
import '../../providers/password_recovery_provider.dart';
import '../../widgets/recovery_scaffold.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key, this.email = ''});
  final String email;
  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.email);
  bool _loading = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    if (kDebugMode) debugPrint('FORGOT_PASSWORD_PAGE_OPENED');
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_loading || !_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final email = _email.text.trim();
    try {
      await ref.read(passwordRecoveryProvider).request(email);
      if (mounted) context.push('/recovery-otp', extra: email);
    } catch (e) {
      if (mounted) setState(() => _error = recoveryError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => RecoveryScaffold(
        asset: 'assets/brand/lupa_kata_sandi.png',
        onBack: () => context.pop(),
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Lupa Kata Sandi',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  const Text(
                      'Masukkan email akun NUSARTA kamu. Jika akun dapat dipulihkan, kode verifikasi akan dikirim ke email tersebut.'),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _email,
                    enabled: !_loading,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) =>
                        isValidEmail(v ?? '') ? null : 'Masukkan email valid',
                    onFieldSubmitted: (_) => _send(),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(_error!),
                    ),
                  const SizedBox(height: 24),
                  FilledButton(
                      onPressed: _loading ? null : _send,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Kirim Kode')),
                ],
              )),
        ),
      );
}
