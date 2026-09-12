import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/feature_flags.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/auth_error.dart';
import '../../core/utils/email_validation.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/nusarta_brand.dart';
import '../../widgets/nusarta_entry_scaffold.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});
  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _message;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _message = null;
      _error = null;
    });
    try {
      final result = await ref
          .read(authControllerProvider)
          .signUp(_email.text.trim(), _password.text, name: _name.text.trim());
      if (!mounted) return;
      if (result == RegistrationResult.authenticated) {
        context.go('/');
        return;
      }
      if (FeatureFlags.isEnabled(FeatureFlag.emailOtpVerification)) {
        context.go('/otp', extra: _email.text.trim());
        return;
      }
      setState(
        () => _message =
            'Akun berhasil dibuat. Periksa email Anda dan buka tautan verifikasi.',
      );
    } catch (e) {
      if (mounted)
        setState(
          () => _error = authErrorMessage(
            e,
            fallback: 'Pendaftaran belum berhasil. Silakan coba lagi.',
          ),
        );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => NusartaEntryScaffold(
        artworkAsset: 'assets/brand/rigister.png',
        title: 'Buat Akun NUSARTA',
        subtitle:
            'Mulai kelola keuanganmu dengan lebih mudah, aman, dan terarah.',
        onBack: () => context.go('/welcome'),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NusartaTextField(
                controller: _name,
                label: 'Nama Lengkap',
                icon: Icons.person_outline,
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Masukkan nama kamu'
                    : null,
              ),
              const SizedBox(height: 14),
              NusartaTextField(
                controller: _email,
                label: 'Email',
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (v) => v != null && isValidEmail(v)
                    ? null
                    : 'Masukkan email valid',
              ),
              const SizedBox(height: 14),
              NusartaTextField(
                controller: _password,
                label: 'Kata Sandi (min. 6 karakter)',
                icon: Icons.lock_outline,
                obscureText: _obscure,
                textInputAction: TextInputAction.next,
                suffixIcon: IconButton(
                  icon:
                      Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                validator: (v) =>
                    v != null && v.length >= 6 ? null : 'Minimal 6 karakter',
              ),
              const SizedBox(height: 14),
              NusartaTextField(
                controller: _confirm,
                label: 'Konfirmasi Kata Sandi',
                icon: Icons.lock_outline,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                validator: (v) =>
                    v == _password.text ? null : 'Kata sandi tidak sama',
              ),
              if (_message != null)
                Container(
                  margin: const EdgeInsets.only(top: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _message!,
                    style: const TextStyle(color: AppColors.primary),
                  ),
                ),
              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(top: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.expense.withOpacity(.08),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: AppColors.expense.withOpacity(.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.expense,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: AppColors.expense),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 22),
              NusartaPrimaryButton(
                label: 'Daftar',
                onPressed: _loading ? null : _submit,
                loading: _loading,
              ),
              const SizedBox(height: 14),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('Sudah punya akun? '),
                    TextButton(
                      onPressed: _loading ? null : () => context.go('/login'),
                      child: const Text('Masuk Sekarang'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
