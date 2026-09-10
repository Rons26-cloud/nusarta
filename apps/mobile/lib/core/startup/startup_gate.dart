import 'dart:async';

enum StartupDestination { welcome, pinSetup, lock, home, error }

const startupDependencyTimeout = Duration(seconds: 5);

Future<bool?> startupBool(Future<bool> future) async {
  try {
    return await future.timeout(startupDependencyTimeout);
  } catch (_) {
    return null;
  }
}

Future<StartupDestination> resolveStartup(
    {required bool configured,
    required bool loggedIn,
    required Future<bool> hasPin,
    required Future<bool> shouldLock}) async {
  if (!loggedIn) return StartupDestination.welcome;
  if (!configured) return StartupDestination.error;
  final pin = await startupBool(hasPin);
  if (pin == null) return StartupDestination.error;
  if (!pin) return StartupDestination.pinSetup;
  final lock = await startupBool(shouldLock);
  if (lock == null) return StartupDestination.error;
  return lock ? StartupDestination.lock : StartupDestination.home;
}
