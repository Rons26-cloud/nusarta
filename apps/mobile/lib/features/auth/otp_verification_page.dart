import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/nusarta_brand.dart';

enum OtpStatus {
  idle,
  typing,
  submitting,
  success,
  invalid,
  expired,
  rateLimited,
  networkError,
  resending
}

class OtpFlowException implements Exception {
  const OtpFlowException(this.status);
  final OtpStatus status;
}

typedef OtpVerifyCallback = Future<void> Function(String code);
typedef OtpResendCallback = Future<void> Function();

class OtpVerificationPage extends ConsumerStatefulWidget {
  const OtpVerificationPage(
      {super.key,
      required this.email,
      this.purpose = OtpPurpose.emailVerification,
      this.verifyCode,
      this.resendCode,
      this.cooldown = const Duration(seconds: 60),
      this.onVerified});
  final String email;
  final OtpPurpose purpose;
  final OtpVerifyCallback? verifyCode;
  final OtpResendCallback? resendCode;
  final Duration cooldown;
  final VoidCallback? onVerified;
  @override
  ConsumerState<OtpVerificationPage> createState() =>
      _OtpVerificationPageState();
}

class _OtpVerificationPageState extends ConsumerState<OtpVerificationPage> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  Timer? _timer;
  int _remaining = 0;
  OtpStatus _status = OtpStatus.idle;
  String? _error;
  bool _updating = false;
  String get _code => _controllers.map((c) => c.text).join();
  bool get _complete => _code.length == 6;
  String get _maskedEmail {
    final normalized = widget.email.trim();
    if (normalized.isEmpty) return 'email kamu';
    final parts = normalized.split('@');
    if (parts.length != 2) return widget.email;
    final name = parts.first;
    final visible = name.length <= 2 ? name : name.substring(0, 3);
    return visible + '***@' + parts.last;
  }

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _setStatus(OtpStatus status, [String? error]) {
    if (!mounted) return;
    setState(() {
      _status = status;
      _error = error;
    });
  }

  void _changed(int index, String raw) {
    if (_updating) return;
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 1) {
      _updating = true;
      final all = List<String>.filled(6, '');
      for (var i = 0; i < index && i < 6; i++) all[i] = _controllers[i].text;
      for (var i = 0; i < digits.length && index + i < 6; i++)
        all[index + i] = digits[i];
      for (var i = 0; i < 6; i++) {
        _controllers[i].value = TextEditingValue(
            text: all[i],
            selection: TextSelection.collapsed(offset: all[i].length));
      }
      _updating = false;
      _focusNodes[(index + digits.length).clamp(0, 5)].requestFocus();
    } else {
      if (raw != digits) {
        _updating = true;
        _controllers[index].value = TextEditingValue(
            text: digits,
            selection: TextSelection.collapsed(offset: digits.length));
        _updating = false;
      }
      if (digits.isNotEmpty && index < 5) _focusNodes[index + 1].requestFocus();
      if (digits.isEmpty && index > 0) {
        _focusNodes[index - 1].requestFocus();
        _controllers[index - 1].selection = TextSelection.collapsed(
            offset: _controllers[index - 1].text.length);
      }
    }
    if (_code.isNotEmpty) _setStatus(OtpStatus.typing);
    if (_complete) setState(() {});
  }

  String _messageFor(Object error) {
    if (error is OtpFlowException) {
      switch (error.status) {
        case OtpStatus.expired:
          return 'Kode verifikasi sudah kedaluwarsa.';
        case OtpStatus.rateLimited:
          return 'Terlalu banyak permintaan. Coba lagi sebentar.';
        case OtpStatus.networkError:
          return 'Koneksi bermasalah. Periksa internet dan coba lagi.';
        default:
          return 'Kode verifikasi tidak valid.';
      }
    }
    final text = error.toString().toLowerCase();
    final code = error is AuthException ? (error.code ?? '').toLowerCase() : '';
    final status = error is AuthException ? error.statusCode : null;
    if (code.contains('expired') ||
        code.contains('otp_expired') ||
        text.contains('expired')) return 'Kode verifikasi sudah kedaluwarsa.';
    if (code.contains('rate') ||
        code.contains('limit') ||
        status == '429' ||
        text.contains('rate') ||
        text.contains('429'))
      return 'Terlalu banyak permintaan. Coba lagi sebentar.';
    if (code.contains('network') ||
        text.contains('socket') ||
        text.contains('network') ||
        text.contains('timeout'))
      return 'Koneksi bermasalah. Periksa internet dan coba lagi.';
    return 'Verifikasi belum berhasil. Silakan coba lagi.';
  }

  Future<void> _verify() async {
    if (!_complete || _status == OtpStatus.submitting) return;
    _setStatus(OtpStatus.submitting);
    try {
      final callback = widget.verifyCode ??
          (code) => ref.read(authControllerProvider).verifyOtp(
              email: widget.email, token: code, purpose: widget.purpose);
      await callback(_code);
      if (!mounted) return;
      _setStatus(OtpStatus.success);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email berhasil diverifikasi')),
      );
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      if (widget.onVerified != null) {
        widget.onVerified!();
      } else {
        context.go('/');
      }
    } catch (error) {
      _setStatus(error is OtpFlowException ? error.status : OtpStatus.invalid,
          _messageFor(error));
    }
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _remaining = widget.cooldown.inSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      if (_remaining <= 1) {
        timer.cancel();
        setState(() => _remaining = 0);
      } else
        setState(() => _remaining--);
    });
  }

  Future<void> _resend() async {
    if (_remaining > 0 || _status == OtpStatus.resending) return;
    _setStatus(OtpStatus.resending);
    try {
      final callback = widget.resendCode ??
          () => ref
              .read(authControllerProvider)
              .resendOtp(email: widget.email, purpose: widget.purpose);
      await callback();
      if (!mounted) return;
      _startCooldown();
      _setStatus(OtpStatus.typing, 'Kode baru telah dikirim.');
    } catch (error) {
      _setStatus(
          error is OtpFlowException ? error.status : OtpStatus.rateLimited,
          _messageFor(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy =
        _status == OtpStatus.submitting || _status == OtpStatus.resending;
    return NusartaAuthScaffold(
        artworkAsset: 'assets/brand/otp.png',
        onBack: () => context.pop(),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Icon(Icons.mark_email_read_outlined,
              color: AppColors.gold, size: 34),
          const SizedBox(height: 10),
          Text('Verifikasi Email',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          const Text('Masukkan kode 6 digit yang kami kirim ke email kamu.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.neutral)),
          const SizedBox(height: 12),
          Text(_maskedEmail,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.primary)),
          const SizedBox(height: 24),
          Semantics(
              label: 'Kode verifikasi 6 digit',
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    final focused = _focusNodes[index].hasFocus;
                    final invalid = _status == OtpStatus.invalid ||
                        _status == OtpStatus.expired;
                    return SizedBox(
                        width: 45,
                        child: DecoratedBox(
                            decoration: BoxDecoration(
                                color: AppColors.cream,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: invalid
                                        ? AppColors.danger
                                        : focused
                                            ? AppColors.gold
                                            : AppColors.primary
                                                .withOpacity(.18),
                                    width: focused || invalid ? 2 : 1)),
                            child: TextField(
                                controller: _controllers[index],
                                focusNode: _focusNodes[index],
                                onChanged: (v) => _changed(index, v),
                                keyboardType: TextInputType.number,
                                textInputAction: index == 5
                                    ? TextInputAction.done
                                    : TextInputAction.next,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary),
                                decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    counterText: '',
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: 12)))));
                  }))),
          const SizedBox(height: 10),
          const Text('Kode berlaku dalam waktu terbatas.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.neutral)),
          if (_error != null)
            Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(_error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: _status == OtpStatus.typing
                            ? AppColors.primary
                            : AppColors.danger,
                        fontWeight: FontWeight.w600))),
          const SizedBox(height: 24),
          NusartaPrimaryButton(
              label:
                  _status == OtpStatus.success ? 'Terverifikasi' : 'Verifikasi',
              onPressed: !_complete || busy ? null : _verify,
              loading: _status == OtpStatus.submitting),
          const SizedBox(height: 18),
          const Text('Belum menerima kode?',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.neutral)),
          TextButton(
              onPressed: _remaining > 0 || busy ? null : _resend,
              child: Text(_status == OtpStatus.expired
                  ? 'Kirim Kode Baru'
                  : _remaining > 0
                      ? 'Kirim ulang dalam 00:' +
                          _remaining.toString().padLeft(2, '0')
                      : 'Kirim ulang kode')),
        ]));
  }
}
