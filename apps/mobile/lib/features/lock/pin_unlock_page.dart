import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/security/biometric_service.dart';
import '../../core/security/pin_service.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/lock_provider.dart';
import '../../widgets/pin_keypad.dart';

/// Unlock gate: attempts biometric first, falls back to PIN.
class PinUnlockPage extends ConsumerStatefulWidget {
  const PinUnlockPage({super.key});

  @override
  ConsumerState<PinUnlockPage> createState() => _PinUnlockPageState();
}

class _PinUnlockPageState extends ConsumerState<PinUnlockPage> {
  String _pin = '';
  bool _loading = false;
  bool _locked = false;
  bool _biometricRequested = false;
  String? _error;

  Timer? _countdownTimer;
  DateTime? _lockedUntil;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _syncLockout();
      _tryBiometric();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _syncLockout() async {
    final isLocked = await PinService.isLocked;
    if (isLocked) {
      final until = DateTime.now().add(PinService.lockoutDuration);
      _startCountdown(until);
    }
  }

  void _startCountdown(DateTime until) {
    if (!mounted) return;
    setState(() {
      _lockedUntil = until;
      _locked = true;
    });
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _countdownTimer?.cancel();
        return;
      }
      final remaining = until.difference(DateTime.now());
      if (remaining.inSeconds <= 0) {
        _countdownTimer?.cancel();
        setState(() {
          _lockedUntil = null;
          _locked = false;
          _error = null;
        });
        _tryBiometric();
        return;
      }
      setState(() {});
    });
  }

  String get _countdownLabel {
    final until = _lockedUntil;
    if (until == null) return '';
    final seconds = until.difference(DateTime.now()).inSeconds.clamp(0, 36000);
    final mm = (seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (seconds % 60).toString().padLeft(2, '0');
    return 'Coba lagi dalam $mm:$ss.';
  }

  Future<void> _tryBiometric() async {
    if (_biometricRequested || _locked || !mounted) return;
    _biometricRequested = true;
    final controller = ref.read(lockControllerProvider);
    final enabled = await controller.isBiometricEnabled();
    if (!enabled || !mounted) {
      _biometricRequested = false;
      return;
    }
    final ok = await controller.tryBiometric();
    if (ok && mounted) context.go('/');
    _biometricRequested = false;
  }

  void _onDigit(String d) {
    if (_locked || _loading) return;
    setState(() {
      _pin += d;
      _error = null;
    });
    if (_pin.length == 6) {
      _submit();
    }
  }

  Future<void> _showForgotPin() async {
    final user = ref.read(currentUserProvider);
    final email = user?.email?.trim() ?? '';
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lupa PIN?'),
        content: Text(
          email.isEmpty
              ? 'PIN hanya disimpan di perangkat ini dan tidak dapat '
                  'dipulihkan. Reset PIN akan mengeluarkan Anda dari akun '
                  'agar dapat masuk kembali dan membuat PIN baru.'
              : 'PIN hanya disimpan di perangkat ini dan tidak dapat '
                  'dipulihkan. Reset PIN akan mengeluarkan Anda dari akun '
                  'agar dapat masuk kembali dengan email terdaftar:\n\n'
                  '$email\n\n'
                  'dan membuat PIN baru.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _resetPin();
            },
            child: const Text('Reset PIN'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetPin() async {
    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider).signOut();
    } catch (_) {
      // Proceed with a local reset even if the remote session cannot sign out.
    }
    await ref.read(lockControllerProvider).logout();
    if (!mounted) return;
    context.go('/login');
  }

  void _onDelete() {
    if (_locked || _loading) return;
    setState(() {
      if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_locked || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final controller = ref.read(lockControllerProvider);
    final result = await controller.verifyPinDetailed(_pin);
    if (!mounted) return;
    setState(() => _loading = false);
    if (result.ok) {
      context.go('/');
      return;
    }
    setState(() => _pin = '');
    if (result.status == PinVerifyStatus.wrong) {
      final remaining = result.remainingAttempts;
      setState(() {
        _error = remaining != null && remaining > 0
            ? 'PIN salah. Sisa $remaining percobaan.'
            : 'PIN salah. Coba lagi.';
      });
      return;
    }
    if (result.status == PinVerifyStatus.locked) {
      final until =
          result.lockedUntil ?? DateTime.now().add(PinService.lockoutDuration);
      _startCountdown(until);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showBiometricShortcut = _pin.isEmpty && !_loading;
    return Scaffold(
      backgroundColor: AppColors.deepEmerald,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    'assets/brand/logo.png',
                    width: 72,
                    height: 72,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'NUSARTA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _locked ? 'Uji coba melebihi batas' : 'Masukkan PIN Anda',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withAlpha(179)),
                  ),
                  const SizedBox(height: 28),
                  PinDots(count: _pin.length, dotColor: Colors.white),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(_error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: _locked
                                ? const Color(0xFFF2B8B5)
                                : Colors.white)),
                  ],
                  if (_locked) ...[
                    const SizedBox(height: 4),
                    Text(
                      _countdownLabel,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white.withAlpha(204),
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                  const SizedBox(height: 24),
                  PinKeypad(
                    enabled: !_locked && !_loading,
                    buttonColor: Colors.white,
                    highlightColor: Colors.white24,
                    keyFill: AppColors.primary.withAlpha(71),
                    biometricColor: AppColors.accentLight,
                    onDigit: _onDigit,
                    onDelete: _onDelete,
                    onBiometric: showBiometricShortcut ? _tryBiometric : null,
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<bool>(
                    future: BiometricService.isEnabled,
                    builder: (context, snapshot) {
                      final enabled = snapshot.data ?? false;
                      return Text(
                        enabled ? 'atau gunakan biometrik' : '',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.accentLight.withAlpha(230),
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _locked ? null : _showForgotPin,
                    icon: const Icon(Icons.help_outline,
                        size: 16, color: Colors.white70),
                    label: const Text('Lupa PIN?',
                        style: TextStyle(color: Colors.white70)),
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
