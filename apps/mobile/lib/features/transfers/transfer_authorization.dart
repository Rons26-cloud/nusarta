import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/security/biometric_service.dart';
import '../../core/security/pin_service.dart';

class TransferAuthorization {
  static Future<bool> request(BuildContext context) async {
    if (!await PinService.isSet || await PinService.isLocked) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Atur PIN NUSARTA atau tunggu masa penguncian berakhir.')));
      }
      return false;
    }
    if (await BiometricService.unlock()) return true;
    if (!context.mounted) return false;
    return await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (_) => const _PinAuthorizationDialog()) ??
        false;
  }
}

class _PinAuthorizationDialog extends StatefulWidget {
  const _PinAuthorizationDialog();
  @override
  State<_PinAuthorizationDialog> createState() =>
      _PinAuthorizationDialogState();
}

class _PinAuthorizationDialogState extends State<_PinAuthorizationDialog> {
  final _pin = TextEditingController();
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _pin.clear();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await PinService.verifyStatus(_pin.text);
      _pin.clear();
      if (!mounted) return;
      if (result.ok) {
        Navigator.pop(context, true);
        return;
      }
      setState(() => _error = result.status == PinVerifyStatus.locked
          ? 'PIN terkunci. Coba lagi setelah 5 menit.'
          : 'PIN NUSARTA tidak sesuai.');
    } catch (_) {
      if (mounted) setState(() => _error = 'Verifikasi tidak tersedia.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('PIN NUSARTA'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text(
              'Otorisasi transfer di NUSARTA. Jangan masukkan PIN bank atau e-wallet.'),
          TextField(
              controller: _pin,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration:
                  InputDecoration(labelText: 'PIN NUSARTA', errorText: _error)),
        ]),
        actions: [
          TextButton(
              onPressed: _busy ? null : () => Navigator.pop(context, false),
              child: const Text('Batal')),
          FilledButton(
              onPressed: _busy ? null : _verify, child: const Text('Otorisasi'))
        ],
      );
}
