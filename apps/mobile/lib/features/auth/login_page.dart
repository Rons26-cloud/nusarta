import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/auth_error.dart';
import '../../core/utils/email_validation.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/nusarta_brand.dart';
import '../../widgets/nusarta_entry_scaffold.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider)
          .signInWithEmail(_email.text.trim(), _password.text);
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final textController = TextEditingController(text: _email.text.trim());
    final target = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Lupa Kata Sandi'),
        content: TextField(
            controller: textController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
                labelText: 'Email', prefixIcon: Icon(Icons.mail_outline))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, textController.text.trim()),
              child: const Text('Kirim Tautan Reset')),
        ],
      ),
    );
    textController.dispose();
    if (target == null || target.isEmpty || !mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider).resetPassword(target);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Tautan reset kata sandi telah dikirim ke email kamu.')));
    } catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showGooglePlaceholder() {
    showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('Masuk dengan Google'),
                content: const Text(
                    'Mohon maaf, fitur masuk dengan Google saat ini sedang dalam pengembangan.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Mengerti'))
                ]));
  }

  @override
  Widget build(BuildContext context) => NusartaEntryScaffold(
        artworkAsset: 'assets/brand/login_defoult.png',
        title: 'Selamat Datang Kembali',
        subtitle: 'Masuk untuk melanjutkan mengelola keuanganmu.',
        footerFraction: .17,
        onBack: () => context.go('/welcome'),
        child: Form(
          key: _formKey,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            NusartaTextField(
                controller: _email,
                label: 'Email',
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (v) => v != null && isValidEmail(v)
                    ? null
                    : 'Masukkan email valid'),
            const SizedBox(height: 14),
            NusartaTextField(
                controller: _password,
                label: 'Kata Sandi',
                icon: Icons.lock_outline,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                suffixIcon: IconButton(
                    icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure)),
                validator: (v) =>
                    v != null && v.length >= 6 ? null : 'Minimal 6 karakter'),
            Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                    onPressed: _loading ? null : _forgotPassword,
                    child: const Text('Lupa kata sandi?'))),
            if (_error != null)
              Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: AppColors.expense.withOpacity(.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.expense.withOpacity(.25))),
                  child: Row(children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.expense, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_error!,
                            style: const TextStyle(color: AppColors.expense)))
                  ])),
            NusartaPrimaryButton(
                label: 'Masuk',
                onPressed: _loading ? null : _submit,
                loading: _loading),
            const SizedBox(height: 14),
            NusartaSecondaryButton(
                label: 'Masuk dengan Google',
                onPressed: _loading ? null : _showGooglePlaceholder),
            const SizedBox(height: 14),
            Center(
                child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                  const Text('Belum punya akun? '),
                  TextButton(
                      onPressed:
                          _loading ? null : () => context.push('/register'),
                      child: const Text('Daftar'))
                ])),
          ]),
        ),
      );
}
