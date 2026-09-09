import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nusarta/core/security/pin_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methodChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final storage = <String, String>{};

  setUp(() {
    storage.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, (call) async {
      switch (call.method) {
        case 'read':
          return storage[call.arguments['key']];
        case 'write':
          storage[call.arguments['key']] = call.arguments['value'];
          return null;
        case 'delete':
          storage.remove(call.arguments['key']);
          return null;
        case 'deleteAll':
          storage.clear();
          return null;
      }
      return null;
    });
  });

  tearDown(() => TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger
      .setMockMethodCallHandler(methodChannel, null));

  test('PIN is stored as hash, not plaintext', () async {
    await PinService.setPin('123456');
    final stored = storage.values.join(',');
    expect(stored, isNot(contains('123456')));
  });

  test('correct PIN verifies', () async {
    await PinService.setPin('123456');
    expect(await PinService.verify('123456'), isTrue);
  });

  test('wrong PIN does not verify', () async {
    await PinService.setPin('123456');
    expect(await PinService.verify('000000'), isFalse);
  });

  test('changing the PIN invalidates the old one', () async {
    await PinService.setPin('111111');
    await PinService.setPin('222222');
    expect(await PinService.verify('111111'), isFalse);
    expect(await PinService.verify('222222'), isTrue);
  });

  test('clearPin removes the stored PIN', () async {
    await PinService.setPin('123456');
    await PinService.clearPin();
    expect(await PinService.isSet, isFalse);
  });

  group('brute-force lockout', () {
    test('reports remaining attempts on wrong PIN', () async {
      await PinService.setPin('123456');
      final first = await PinService.verifyStatus('000000');
      expect(first.status, PinVerifyStatus.wrong);
      expect(first.remainingAttempts, 4);

      final second = await PinService.verifyStatus('000000');
      expect(second.status, PinVerifyStatus.wrong);
      expect(second.remainingAttempts, 3);
    });

    test('locks after the attempt limit and rejects the correct PIN', () async {
      await PinService.setPin('123456');
      for (var i = 0; i < PinService.attemptLimit; i++) {
        await PinService.verifyStatus('000000');
      }
      expect(await PinService.isLocked, isTrue);

      final duringLock = await PinService.verifyStatus('123456');
      expect(duringLock.status, PinVerifyStatus.locked);
      expect(await PinService.verify('123456'), isFalse);
    });

    test('a correct PIN resets the failed-attempt counter', () async {
      await PinService.setPin('123456');
      await PinService.verifyStatus('000000');
      await PinService.verifyStatus('000000');

      expect(
          (await PinService.verifyStatus('123456')).status, PinVerifyStatus.ok);

      final afterReset = await PinService.verifyStatus('000000');
      expect(afterReset.status, PinVerifyStatus.wrong);
      expect(afterReset.remainingAttempts, 4);
    });

    test('changing the PIN clears pending lockout state', () async {
      await PinService.setPin('123456');
      await PinService.verifyStatus('000000');
      await PinService.verifyStatus('000000');
      await PinService.setPin('654321');
      final result = await PinService.verifyStatus('000000');
      expect(result.status, PinVerifyStatus.wrong);
      expect(result.remainingAttempts, 4);
    });
  });
}
