import 'package:flutter/services.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';

import 'auto_lock_service.dart';
import 'secure_store.dart';

/// Biometric app unlock.
class BiometricService {
  BiometricService._();

  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> isSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  static Future<bool> canAuthenticate() async {
    try {
      final available = await _auth.getAvailableBiometrics();
      return available.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> get isEnabled async =>
      await AppSecureStore.isBiometricEnabled;

  /// Prompts the OS biometric dialog.
  static Future<bool> unlock() async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Buka NUSARTA untuk melihat keuanganmu',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      if (ok) await AutoLockService.recordActivity();
      return ok;
    } catch (e) {
      // User cancelled, device no longer enrolled, etc.
      if (e is PlatformException &&
          (e.code == auth_error.notAvailable ||
              e.code == auth_error.passcodeNotSet)) {
        return false;
      }
      return false;
    }
  }

  static Future<void> setEnabled(bool value) async {
    await AppSecureStore.setBiometricEnabled(value);
  }
}
