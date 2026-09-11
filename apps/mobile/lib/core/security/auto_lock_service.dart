import 'secure_store.dart';

/// Auto-lock timeout; zero locks on resume through the app lifecycle handler.
class AutoLockService {
  AutoLockService._();

  static bool _unlockedThisProcess = false;
  static void lock() => _unlockedThisProcess = false;

  static Future<bool> shouldLock() async {
    if (!_unlockedThisProcess) return true;
    final minutes = await AppSecureStore.autoLockMinutes;
    final lastUnlock = await AppSecureStore.lastUnlockAt;
    if (lastUnlock == null) return true;
    if (minutes <= 0) return false;
    return DateTime.now().difference(lastUnlock).inMinutes >= minutes;
  }

  static Future<void> recordActivity() async {
    await AppSecureStore.setLastUnlockAt(DateTime.now());
    _unlockedThisProcess = true;
  }
}
