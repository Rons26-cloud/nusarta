import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/secure_keys.dart';

/// Secure storage; store salted PIN hashes only.
class SecureStore {
  SecureStore._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  static Future<String?> read(String key) => _storage.read(key: key);

  static Future<void> delete(String key) => _storage.delete(key: key);

  static Future<void> clear() => _storage.deleteAll();
}

class AppSecureStore {
  AppSecureStore._();

  static Future<bool> get hasPin async =>
      (await SecureStore.read(SecureKeys.pinHash)) != null;

  static Future<bool> get isBiometricEnabled async =>
      (await SecureStore.read(SecureKeys.biometricEnabled)) == 'true';

  static Future<void> setBiometricEnabled(bool value) =>
      SecureStore.write(SecureKeys.biometricEnabled, value.toString());

  static Future<int> get autoLockMinutes async =>
      int.tryParse(await SecureStore.read(SecureKeys.autoLockMinutes) ?? '') ??
      5;

  static Future<void> setAutoLockMinutes(int minutes) =>
      SecureStore.write(SecureKeys.autoLockMinutes, minutes.toString());

  static Future<DateTime?> get lastUnlockAt async {
    final raw = await SecureStore.read(SecureKeys.lastUnlockAt);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  static Future<void> setLastUnlockAt(DateTime t) =>
      SecureStore.write(SecureKeys.lastUnlockAt, t.toIso8601String());

  static Future<bool> get onboarded async =>
      (await SecureStore.read(SecureKeys.onboarded)) == 'true';

  static Future<void> setOnboarded() =>
      SecureStore.write(SecureKeys.onboarded, 'true');

  static Future<bool> get hideBalance async =>
      (await SecureStore.read(SecureKeys.hideBalance)) == 'true';

  static Future<void> setHideBalance(bool value) =>
      SecureStore.write(SecureKeys.hideBalance, value.toString());

  static Future<String> getOrCreateDeviceId() async {
    final existing = await SecureStore.read(SecureKeys.deviceId);
    if (existing != null && existing.isNotEmpty) return existing;
    final generated = _generateDeviceId();
    await SecureStore.write(SecureKeys.deviceId, generated);
    return generated;
  }

  static Future<String> get themeMode async =>
      await SecureStore.read(SecureKeys.themeMode) ?? 'system';

  static Future<void> setThemeMode(String value) =>
      SecureStore.write(SecureKeys.themeMode, value);

  static String _generateDeviceId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}
