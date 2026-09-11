import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/security/biometric_service.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/lock_provider.dart';
import '../../widgets/pin_keypad.dart';

/// Setup 6-digit PIN. Called after first sign-in.
class PinSetupPage extends ConsumerStatefulWidget {
  const PinSetupPage({super.key});

  @override
  ConsumerState<PinSetupPage> createState() => _PinSetupPageState();
}

class _PinSetupPageState extends ConsumerState<PinSetupPage> {
  String _pin = '';
  String _confirm = '';
  bool _stepConfirm = false;
  bool _saving = false;
  String? _error;

  void _onDigit(String d) {
    if (_saving) return;
    String target;
    if (!_stepConfirm) {
      _pin += d;
      target = _pin;
    } else {
      _confirm += d;
      target = _confirm;
    }
    setState(() => _error = null);
    if (target.length == 6) {
      _submit();
    } else {
      setState(() {});
    }
  }

  void _onDelete() {
    if (_saving) return;
    setState(() {
      if (!_stepConfirm) {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else {
        if (_confirm.isNotEmpty) {
          _confirm = _confirm.substring(0, _confirm.length - 1);
        }
      }
      _error = null;
    });
  }

  void _restart() {
    setState(() {
      _stepConfirm = false;
      _pin = '';
      _confirm = '';
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (!_stepConfirm) {
      setState(() {
        _stepConfirm = true;
        _error = null;
      });
      return;
    }
    if (_pin != _confirm) {
      setState(() {
        _error = 'PIN tidak sama. Coba lagi.';
        _confirm = '';
      });
      return;
    }
    setState(() => _saving = true);
    final controller = ref.read(lockControllerProvider);
    try {
      await controller.setupPin(_pin);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'PIN belum dapat disimpan. Silakan coba lagi.';
          _confirm = '';
        });
      }
      return;
    }
    if (!mounted) return;

    // Ask explicitly before enabling biometric — never silently.
    await _offerBiometric();
    if (!mounted) return;
    context.go('/');
  }

  Future<void> _offerBiometric() async {
    final alreadyEnabled = await BiometricService.isEnabled;
    if (alreadyEnabled) return;
    final canUse = await BiometricService.canAuthenticate();
    if (!canUse || !mounted) return;

    final body = await BiometricService.isSupported();
    if (!body || !mounted) return;

    final enable = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aktifkan biometrik?'),
        content: const Text(
          'Buka NUSARTA dengan sidik jari atau pengenalan wajah '
          'tanpa perlu memasukkan PIN setiap saat.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Nanti Saja'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Aktifkan'),
          ),
        ],
      ),
    );
    if (enable != true || !mounted) return;
    final ok = await ref.read(lockControllerProvider).enableBiometric();
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biometrik tidak tersedia di perangkat ini.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _stepConfirm ? _confirm : _pin;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.lock_outline,
                      size: 56, color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    _stepConfirm ? 'Konfirmasi PIN' : 'Buat PIN NUSARTA',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _stepConfirm
                        ? 'Masukkan PIN yang sama sekali lagi.'
                        : '6 digit untuk membuka NUSARTA. '
                            'Tidak disimpan dalam bentuk asli.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.neutral),
                  ),
                  const SizedBox(height: 24),
                  PinDots(count: current.length, dotColor: AppColors.primary),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.expense)),
                  ],
                  const SizedBox(height: 24),
                  PinKeypad(
                    enabled: !_saving,
                    buttonColor: AppColors.primaryDark,
                    highlightColor: AppColors.primary.withAlpha(46),
                    keyFill: AppColors.primary.withAlpha(20),
                    onDigit: _onDigit,
                    onDelete: _onDelete,
                  ),
                  if (_stepConfirm) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _saving ? null : _restart,
                      child: const Text('Mulai ulang'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
