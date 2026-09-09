import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../constants/secure_keys.dart';
import 'secure_store.dart';

/// Result of a PIN verification attempt.
enum PinVerifyStatus { ok, wrong, locked }

class PinVerifyResult {
  const PinVerifyResult(this.status,
      {this.remainingAttempts, this.lockedUntil});

  final PinVerifyStatus status;
  final int? remainingAttempts;
  final DateTime? lockedUntil;

  bool get ok => status == PinVerifyStatus.ok;
}

/// Salted PIN hashing and failed-attempt lockout.
class PinService {
  PinService._();

  static const int _defaultIterations = 120000;
  static const int attemptLimit = 5;
  static const Duration lockoutDuration = Duration(minutes: 5);

  static Future<void> setPin(String pin) async {
    final salt = _randomSalt();
    final hash = _derive(pin, salt, _defaultIterations);
    await SecureStore.write(SecureKeys.pinSalt, salt);
    await SecureStore.write(SecureKeys.pinIterations, '$_defaultIterations');
    await SecureStore.write(SecureKeys.pinHash, base64Encode(hash));
    await _resetBruteForceState();
  }

  static Future<bool> verify(String pin) async {
    final result = await verifyStatus(pin);
    return result.ok;
  }

  /// Whether an active lockout cooldown is in effect.
  static Future<bool> get isLocked async {
    final until = await _activeLockedUntil();
    return until != null;
  }

  static Future<PinVerifyResult> verifyStatus(String pin) async {
    final lockedUntil = await _activeLockedUntil();
    if (lockedUntil != null) {
      return PinVerifyResult(PinVerifyStatus.locked, lockedUntil: lockedUntil);
    }

    final salt = await SecureStore.read(SecureKeys.pinSalt);
    final iterationsRaw = await SecureStore.read(SecureKeys.pinIterations);
    final stored = await SecureStore.read(SecureKeys.pinHash);
    if (salt == null || stored == null) {
      return const PinVerifyResult(PinVerifyStatus.wrong, remainingAttempts: 0);
    }
    final iterations = int.tryParse(iterationsRaw ?? '') ?? _defaultIterations;
    final hash = _derive(pin, salt, iterations);

    if (_constantTimeEquals(base64Encode(hash), stored)) {
      await _resetBruteForceState();
      return const PinVerifyResult(PinVerifyStatus.ok);
    }

    final attempts = (int.tryParse(
                await SecureStore.read(SecureKeys.pinFailedAttempts) ?? '') ??
            0) +
        1;
    if (attempts >= attemptLimit) {
      final until = DateTime.now().add(lockoutDuration);
      await SecureStore.write(
          SecureKeys.pinLockedUntil, until.toIso8601String());
      await SecureStore.delete(SecureKeys.pinFailedAttempts);
      return PinVerifyResult(PinVerifyStatus.locked, lockedUntil: until);
    }
    await SecureStore.write(SecureKeys.pinFailedAttempts, '$attempts');
    return PinVerifyResult(
      PinVerifyStatus.wrong,
      remainingAttempts: attemptLimit - attempts,
    );
  }

  static Future<bool> get isSet async => await AppSecureStore.hasPin;

  static Future<void> clearPin() async {
    await SecureStore.delete(SecureKeys.pinSalt);
    await SecureStore.delete(SecureKeys.pinIterations);
    await SecureStore.delete(SecureKeys.pinHash);
    await SecureStore.delete(SecureKeys.biometricEnabled);
    await _resetBruteForceState();
  }

  static Future<DateTime?> _activeLockedUntil() async {
    final raw = await SecureStore.read(SecureKeys.pinLockedUntil);
    if (raw == null) return null;
    final until = DateTime.tryParse(raw);
    if (until == null) return null;
    if (DateTime.now().isBefore(until)) return until;
    await _resetBruteForceState();
    return null;
  }

  static Future<void> _resetBruteForceState() async {
    await SecureStore.delete(SecureKeys.pinFailedAttempts);
    await SecureStore.delete(SecureKeys.pinLockedUntil);
  }

  static String _randomSalt() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    return base64Encode(bytes);
  }

  /// Iterated HMAC-SHA256; changes require migrating stored hashes.
  static List<int> _derive(String pin, String salt, int iterations) {
    var block = Hmac(sha256, utf8.encode(pin)).convert(utf8.encode(salt));
    for (var i = 1; i < iterations; i++) {
      block = Hmac(sha256, utf8.encode(pin)).convert(block.bytes);
    }
    return block.bytes;
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
