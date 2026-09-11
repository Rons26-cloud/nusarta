import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nusarta/features/auth/login_page.dart';
import 'package:nusarta/features/auth/register_page.dart';
import 'package:nusarta/features/splash/splash_page.dart';

import 'final_ui_test.dart' as preview;

void main() {
  for (final width in [360.0, 375.0, 390.0, 412.0, 430.0]) {
    for (final page in [const LoginPage(), const RegisterPage()]) {
      testWidgets('${page.runtimeType} keyboard $width', (tester) async {
        final router = await preview.mount(tester, page, width, false);
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();
        await tester.drag(find.byType(Scrollable).last, const Offset(0, -1500));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final button = find.widgetWithText(
            FilledButton, page is LoginPage ? 'Masuk' : 'Daftar');
        expect(tester.getRect(button).bottom, lessThanOrEqualTo(520));
        await tester.pumpWidget(const SizedBox());
        router.dispose();
        tester.view.resetViewInsets();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }
    testWidgets('splash artwork remains present at $width', (tester) async {
      final router = await preview.mount(
          tester, const SplashPage(autoContinue: false), width, false);
      expect(find.byType(Image), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }
}

