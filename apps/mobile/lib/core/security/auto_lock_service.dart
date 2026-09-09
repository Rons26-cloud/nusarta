import 'secure_store.dart';

/// Auto-lock timeout; zero locks on resume through the app lifecycle handler.
class AutoLockService {
  AutoLockService._();

  static Future<bool> shouldLock() async {
    final minutes = await AppSecureStore.autoLockMinutes;
    final lastUnlock = await AppSecureStore.lastUnlockAt;
    if (minutes <= 0 || lastUnlock == null) return false;
    return DateTime.now().difference(lastUnlock).inMinutes >= minutes;
  }

  static Future<void> recordActivity() =>
      AppSecureStore.setLastUnlockAt(DateTime.now());
}
