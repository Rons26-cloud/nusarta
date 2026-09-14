import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nusarta/core/security/pin_service.dart';
import 'package:nusarta/features/transfers/transfer_authorization.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final storage = <String, String>{};
  setUp(() {
    storage.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'read':
          return storage[call.arguments['key']];
        case 'write':
          storage[call.arguments['key']] = call.arguments['value'];
        case 'delete':
          storage.remove(call.arguments['key']);
      }
      return null;
    });
  });
  tearDown(() => TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null));
  Widget page(ValueChanged<bool> result) => MaterialApp(
      home: Scaffold(
          body: Builder(
              builder: (context) => TextButton(
                  onPressed: () async =>
                      result(await TransferAuthorization.request(context)),
                  child: const Text('Transfer')))));
  testWidgets('missing PIN cannot authorize transfer', (tester) async {
    bool? result;
    await tester.pumpWidget(page((v) => result = v));
    await tester.tap(find.text('Transfer'));
    await tester.pumpAndSettle();
    expect(result, false);
  });
  testWidgets('biometric unavailable falls back to NUSARTA PIN',
      (tester) async {
    await tester.runAsync(() => PinService.setPin('123456'));
    bool? result;
    await tester.pumpWidget(page((v) => result = v));
    await tester.tap(find.text('Transfer'));
    await tester.pumpAndSettle();
    expect(find.text('PIN NUSARTA'), findsWidgets);
    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('Otorisasi'));
    await tester.pumpAndSettle();
    expect(result, true);
    expect(storage.values.join(), isNot(contains('123456')));
  });
  testWidgets('wrong NUSARTA PIN does not authorize', (tester) async {
    await tester.runAsync(() => PinService.setPin('123456'));
    bool? result;
    await tester.pumpWidget(page((v) => result = v));
    await tester.tap(find.text('Transfer'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '000000');
    await tester.tap(find.text('Otorisasi'));
    await tester.pumpAndSettle();
    expect(result, isNull);
    expect(find.text('PIN NUSARTA tidak sesuai.'), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(result, false);
  });
  testWidgets('active lockout blocks transfer before biometric',
      (tester) async {
    await tester.runAsync(() async {
      await PinService.setPin('123456');
      for (var i = 0; i < 5; i++) {
        await PinService.verify('000000');
      }
    });
    bool? result;
    await tester.pumpWidget(page((v) => result = v));
    await tester.tap(find.text('Transfer'));
    await tester.pumpAndSettle();
    expect(result, false);
    expect(find.byType(TextField), findsNothing);
  });
}
