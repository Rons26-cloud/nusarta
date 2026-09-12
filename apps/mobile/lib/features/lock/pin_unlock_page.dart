import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/security/biometric_service.dart';
import '../../core/security/pin_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/email_validation.dart';
import '../../features/auth/otp_verification_page.dart';
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
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lupa PIN?'),
        content: Text(
          email.isEmpty
              ? 'Reset PIN dilakukan dengan kode verifikasi yang dikirim ke '
                  'email terdaftar untuk memastikan akun ini milikmu.'
              : 'Reset PIN dilakukan dengan kode verifikasi yang kami kirim ke '
                  'email terdaftar:\n\n$email',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Lanjut'),
          ),
        ],
      ),
    );
    if (proceed != true || !mounted) return;
    await _startPinResetFlow();
  }

  Future<void> _startPinResetFlow() async {
    final user = ref.read(currentUserProvider);
    final textController = TextEditingController(text: user?.email ?? '');
    final target = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verifikasi Email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kami akan mengirim kode verifikasi 6 digit ke email ini. '
              'Kode dipakai untuk memastikan akun milikmu sebelum PIN '
              'dihapus dan dibuat baru.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email terdaftar',
                prefixIcon: Icon(Icons.mail_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, textController.text.trim()),
            child: const Text('Kirim Kode'),
          ),
        ],
      ),
    );
    textController.dispose();
    if (target == null || target.isEmpty) return;
    if (!isValidEmail(target)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Masukkan email yang valid.'),
        ));
      }
      return;
    }
    setState(() => _loading = true);
    try {
      await ref
          .read(authControllerProvider)
          .resendOtp(email: target, purpose: OtpPurpose.passwordRecovery);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Kode verifikasi gagal dikirim. Pastikan email terdaftar benar.'),
      ));
      return;
    }
    if (!mounted) return;
    setState(() => _loading = false);
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => OtpVerificationPage(
          email: target,
          purpose: OtpPurpose.passwordRecovery,
          onVerified: _applyPinReset,
        ),
      ),
    );
  }

  Future<void> _applyPinReset() async {
    // Email ownership was verified via recovery OTP. Clear the local PIN and
    // biometric references so a brand new PIN is required right away.
    await ref.read(lockControllerProvider).logout();
    if (!mounted) return;
    context.go('/pin-setup');
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
                    onPressed: _showForgotPin,
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
