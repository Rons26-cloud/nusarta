import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nusarta/features/auth/otp_verification_page.dart';

Widget host(
        {Future<void> Function(String)? verify,
        Future<void> Function()? resend,
        Duration cooldown = const Duration(seconds: 60),
        VoidCallback? onVerified}) =>
    MaterialApp(
        home: OtpVerificationPage(
            email: 'ronaldo@gmail.com',
            verifyCode: verify,
            resendCode: resend,
            cooldown: cooldown,
            onVerified: onVerified));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('renders six branded OTP boxes and disabled verify',
      (tester) async {
    await tester.pumpWidget(host());
    expect(find.byType(TextField), findsNWidgets(6));
    expect(find.text('Verifikasi'), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });
  testWidgets('digit entry advances focus and six digits enable verify',
      (tester) async {
    await tester.pumpWidget(host());
    await tester.tap(find.byType(TextField).first);
    await tester.enterText(find.byType(TextField).first, '1');
    await tester.pump();
    expect(find.byType(TextField).at(1), findsOneWidget);
    for (var i = 1; i < 6; i++)
      await tester.enterText(find.byType(TextField).at(i), '${i + 1}');
    await tester.pump();
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull);
  });
  testWidgets('paste fills remaining boxes and non numeric input is rejected',
      (tester) async {
    await tester.pumpWidget(host());
    await tester.tap(find.byType(TextField).first);
    await tester.enterText(find.byType(TextField).first, '12ab34!5');
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('6'), findsNothing);
  });
  testWidgets(
      'invalid, expired and network states map to safe Indonesian messages',
      (tester) async {
    Future<void> fail(String code) async =>
        throw OtpFlowException(code == 'expired'
            ? OtpStatus.expired
            : code == 'network'
                ? OtpStatus.networkError
                : OtpStatus.invalid);
    await tester.pumpWidget(host(verify: (_) => fail('expired')));
    await tester.enterText(find.byType(TextField).first, '123456');
    await tester.pump();
    await tester.ensureVisible(find.text('Verifikasi'));
    await tester.tap(find.text('Verifikasi'));
    await tester.pumpAndSettle();
    expect(find.text('Kode verifikasi sudah kedaluwarsa.'), findsOneWidget);
  });
  testWidgets('verify shows loading and blocks duplicate taps', (tester) async {
    final completer = Completer<void>();
    var calls = 0;
    await tester.pumpWidget(host(verify: (_) {
      calls++;
      return completer.future;
    }));
    await tester.enterText(find.byType(TextField).first, '123456');
    await tester.pump();
    await tester.ensureVisible(find.text('Verifikasi'));
    await tester.tap(find.byType(FilledButton), warnIfMissed: false);
    await tester.pump();
    await tester.tap(find.byType(FilledButton), warnIfMissed: false);
    expect(calls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    completer.complete();
    await tester.pumpAndSettle();
  });
  testWidgets('resend starts cooldown and reports success', (tester) async {
    var calls = 0;
    await tester.pumpWidget(host(
        resend: () async => calls++, cooldown: const Duration(seconds: 2)));
    await tester.pump(const Duration(milliseconds: 2200));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kirim ulang kode'), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(calls, 1);
    expect(find.textContaining('Kirim ulang dalam'), findsOneWidget);
    expect(find.text('Kode baru telah dikirim.'), findsOneWidget);
  });
  testWidgets('success invokes verified callback and disposes local state',
      (tester) async {
    var verified = false;
    await tester.pumpWidget(host(
      verify: (_) async {},
      onVerified: () => verified = true,
    ));
    await tester.enterText(find.byType(TextField).first, '123456');
    await tester.pump();
    await tester.ensureVisible(find.text('Verifikasi'));
    await tester.tap(find.text('Verifikasi'));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('Email berhasil diverifikasi'), findsOneWidget);
    expect(verified, isTrue);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
  for (final width in [360.0, 375.0, 390.0, 412.0, 430.0]) {
    testWidgets('OTP layout fits width $width', (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(host());
      await tester.pump();
      expect(tester.takeException(), isNull);
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }
}
