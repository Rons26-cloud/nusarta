import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nusarta/core/security/auto_lock_service.dart';
import 'package:nusarta/core/security/secure_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final values = <String, String>{};
  setUp(() {
    values.clear();
    AutoLockService.lock();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      final args = Map<String, dynamic>.from(call.arguments as Map);
      if (call.method == 'read') return values[args['key']];
      if (call.method == 'write') {
        values[args['key'] as String] = args['value'] as String;
      }
      return null;
    });
  });
  tearDown(() => TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null));
  test('cold start remains locked even with recent persisted unlock', () async {
    await AppSecureStore.setLastUnlockAt(DateTime.now());
    expect(await AutoLockService.shouldLock(), isTrue);
  });
  test('PIN or biometric proof unlocks the current process', () async {
    await AutoLockService.recordActivity();
    expect(await AutoLockService.shouldLock(), isFalse);
  });
  test('expired timeout requires unlock', () async {
    await AutoLockService.recordActivity();
    await AppSecureStore.setLastUnlockAt(
        DateTime.now().subtract(const Duration(minutes: 6)));
    expect(await AutoLockService.shouldLock(), isTrue);
  });
  test('immediate mode allows successful unlock then locks on resume',
      () async {
    await AppSecureStore.setAutoLockMinutes(0);
    await AutoLockService.recordActivity();
    expect(await AutoLockService.shouldLock(), isFalse);
    AutoLockService.lock();
    expect(await AutoLockService.shouldLock(), isTrue);
  });
}
