import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nusarta/core/theme/app_colors.dart';
import 'package:nusarta/core/theme/app_theme.dart';
import 'package:nusarta/features/about/about_nusarta_page.dart';
import 'package:nusarta/features/auth/email_verification_success_page.dart';
import 'package:nusarta/features/auth/forgot_password_page.dart';
import 'package:nusarta/features/auth/login_page.dart';
import 'package:nusarta/features/auth/otp_verification_page.dart';
import 'package:nusarta/features/auth/register_page.dart';
import 'package:nusarta/features/help/help_center_page.dart';
import 'package:nusarta/features/lock/pin_setup_page.dart';
import 'package:nusarta/features/lock/pin_unlock_page.dart';
import 'package:nusarta/features/welcome/welcome_page.dart';
import 'package:nusarta/widgets/amount_text.dart';
import 'package:nusarta/widgets/finance_summary.dart';

double _relativeLuminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4) as double;
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double contrastRatio(Color a, Color b) {
  final l1 = _relativeLuminance(a);
  final l2 = _relativeLuminance(b);
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

void expectReadable(String label, Color fg, Color bg, double min) {
  expect(contrastRatio(fg, bg), greaterThanOrEqualTo(min),
      reason: '$label contrast ${contrastRatio(fg, bg).toStringAsFixed(2)} '
          'must be >= $min on ${bg.toARGB32().toRadixString(16)}');
}

Future<void> pumpWithTheme(
  WidgetTester tester,
  Widget page, {
  required bool dark,
  double width = 375,
}) async {
  AppColors.setBrightness(dark ? Brightness.dark : Brightness.light);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 820);
  await tester.pumpWidget(MaterialApp(
    theme: buildLightTheme(),
    darkTheme: buildDarkTheme(),
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    locale: const Locale('id'),
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate
    ],
    supportedLocales: const [Locale('id'), Locale('en')],
    home: ProviderScope(child: page),
  ));
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => AppColors.setBrightness(Brightness.light));

  group('semantic color contrast', () {
    for (final dark in [false, true]) {
      final mode = dark ? 'dark' : 'light';
      group(mode, () {
        setUp(() =>
            AppColors.setBrightness(dark ? Brightness.dark : Brightness.light));

        test('scaffold text is readable on the app background', () {
          final bg = AppColors.backgroundOff;
          expectReadable('textPrimary', AppColors.textPrimary, bg, 4.5);
          expectReadable('textSecondary', AppColors.textSecondary, bg, 4.5);
          expectReadable('heading', AppColors.heading, bg, 4.5);
          expectReadable('numberPrimary', AppColors.numberPrimary, bg, 4.5);
          expectReadable('brandEmerald', AppColors.brandEmerald, bg, 3.0);
        });

        test('card content is readable on elevated surfaces', () {
          final card = AppColors.surfaceElevated;
          expectReadable('textPrimary', AppColors.textPrimary, card, 4.5);
          expectReadable('textSecondary', AppColors.textSecondary, card, 4.5);
          expectReadable('numberPrimary', AppColors.numberPrimary, card, 4.5);
          expectReadable('income', AppColors.income, card, 3.0);
          expectReadable('expense', AppColors.expense, card, 3.0);
        });

        test('body text stays readable on status containers', () {
          expectReadable('textPrimary on successContainer',
              AppColors.textPrimary, AppColors.successContainer, 4.5);
          expectReadable('textSecondary on warningContainer',
              AppColors.textSecondary, AppColors.warningContainer, 4.5);
          expectReadable('textPrimary on errorContainer', AppColors.textPrimary,
              AppColors.errorContainer, 4.5);
          expectReadable('textPrimary on infoContainer', AppColors.textPrimary,
              AppColors.infoContainer, 4.5);
        });

        test('inverse text is readable on brand buttons and hero', () {
          expectReadable(
              'textInverse', AppColors.textInverse, AppColors.primary, 4.5);
          expectReadable(
              'textInverse', AppColors.textInverse, AppColors.primaryDark, 4.5);
        });
      });
    }
  });

  group('pages render in both themes without errors', () {
    final pageFactories = <String, Widget Function()>{
      'welcome': WelcomePage.new,
      'login': LoginPage.new,
      'register': RegisterPage.new,
      'forgot-password': ForgotPasswordPage.new,
      'otp': () => const OtpVerificationPage(email: 'pengujian@example.test'),
      'email-verified': EmailVerificationSuccessPage.new,
      'pin-setup': PinSetupPage.new,
      'pin-unlock': PinUnlockPage.new,
      'help': HelpCenterPage.new,
      'about': AboutNusartaPage.new,
    };

    for (final width in [360.0, 430.0]) {
      for (final dark in [false, true]) {
        for (final entry in pageFactories.entries) {
          testWidgets(
              '${entry.key} ${width.toInt()} ${dark ? 'dark' : 'light'} renders cleanly',
              (tester) async {
            await pumpWithTheme(tester, entry.value(),
                dark: dark, width: width);
            expect(tester.takeException(), isNull);
            await tester.pump(const Duration(milliseconds: 100));
          });
        }
      }
    }
  });

  group('money figures are readable on cards in both themes', () {
    for (final dark in [false, true]) {
      final mode = dark ? 'dark' : 'light';
      testWidgets('$mode balance & amount text use semantic colors',
          (tester) async {
        await pumpWithTheme(
            tester,
            Material(
              color: AppColors.backgroundOff,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  color: AppColors.surfaceElevated,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Saldo', style: TextStyle(fontSize: 18)),
                        MoneyValue(1234567890),
                        SizedBox(height: 12),
                        AmountText(125000, isIncome: false, showSign: true),
                        AmountText(4500000, isIncome: true, showSign: true),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            dark: dark);
        expect(tester.takeException(), isNull);

        final card = AppColors.surfaceElevated;
        expectReadable('numberPrimary', AppColors.numberPrimary, card, 4.5);
        expectReadable('income', AppColors.income, card, 3.0);
        expectReadable('expense', AppColors.expense, card, 3.0);
      });
    }
  });
}
