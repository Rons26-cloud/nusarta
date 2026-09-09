import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/security/auto_lock_service.dart';
import '../core/security/biometric_service.dart';
import '../core/security/pin_service.dart';
import '../core/security/secure_store.dart';

enum AppLockState { locked, unlocked, biometrySetup }

/// Whether app should show the lock gate.
final lockGateProvider = FutureProvider<bool>((ref) async {
  final hasPin = await PinService.isSet;
  if (!hasPin) return false;
  final shouldLock = await AutoLockService.shouldLock();
  return shouldLock || (await AppSecureStore.lastUnlockAt) == null;
});

/// Core lock controller: PIN + biometric + auto-lock.
final lockControllerProvider = Provider<LockController>((ref) {
  return LockController();
});

class LockController {
  LockController();

  bool _unlocked = false;
  bool get unlocked => _unlocked;

  Future<bool> verifyPin(String pin) async {
    final result = await PinService.verifyStatus(pin);
    if (result.ok) {
      _unlocked = true;
      await RecordActivity.recordUnlock();
    }
    return result.ok;
  }

  Future<PinVerifyResult> verifyPinDetailed(String pin) async {
    final result = await PinService.verifyStatus(pin);
    if (result.ok) {
      _unlocked = true;
      await RecordActivity.recordUnlock();
    }
    return result;
  }

  Future<bool> tryBiometric() async {
    final ok = await BiometricService.unlock();
    if (ok) _unlocked = true;
    return ok;
  }

  Future<bool> setupPin(String pin) async {
    await PinService.setPin(pin);
    _unlocked = true;
    await RecordActivity.recordUnlock();
    return true;
  }

  Future<bool> enableBiometric() async {
    final supported = await BiometricService.isSupported();
    if (!supported) return false;
    final available = await BiometricService.canAuthenticate();
    if (!available) return false;
    await BiometricService.setEnabled(true);
    return true;
  }

  Future<bool> disableBiometric() async {
    await BiometricService.setEnabled(false);
    return true;
  }

  Future<bool> isBiometricEnabled() => BiometricService.isEnabled;

  Future<int> get autoLockMinutes => AppSecureStore.autoLockMinutes;
  Future<void> setAutoLockMinutes(int minutes) =>
      AppSecureStore.setAutoLockMinutes(minutes);

  Future<void> logout() async {
    _unlocked = false;
    await SecureStore.clear();
  }
}

/// Records the last successful unlock.
class RecordActivity {
  RecordActivity._();
  static Future<void> recordUnlock() => AutoLockService.recordActivity();
}
