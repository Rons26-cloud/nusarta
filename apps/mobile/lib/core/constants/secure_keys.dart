/// Keys for Keystore/Keychain-backed storage.
class SecureKeys {
  SecureKeys._();

  static const String pinHash = 'nusarta.pin_hash';
  static const String pinSalt = 'nusarta.pin_salt';
  static const String pinIterations = 'nusarta.pin_iterations';
  static const String biometricEnabled = 'nusarta.biometric_enabled';
  static const String autoLockMinutes = 'nusarta.auto_lock_minutes';
  static const String lastUnlockAt = 'nusarta.last_unlock_at';
  static const String pinFailedAttempts = 'nusarta.pin_failed_attempts';
  static const String pinLockedUntil = 'nusarta.pin_locked_until';
  static const String onboarded = 'nusarta.onboarded';
  static const String hideBalance = 'nusarta.hide_balance';
  static const String session = 'nusarta.session';
  static const String deviceId = 'nusarta.device_id';
  static const String themeMode = 'nusarta.theme_mode';
}
