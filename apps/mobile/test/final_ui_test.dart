import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nusarta/core/theme/app_theme.dart';
import 'package:nusarta/data/models/account.dart';
import 'package:nusarta/data/models/category.dart';
import 'package:nusarta/data/models/finance.dart';
import 'package:nusarta/data/models/institution.dart';
import 'package:nusarta/data/models/transaction.dart';
import 'package:nusarta/features/accounts/accounts_page.dart';
import 'package:nusarta/features/accounts/add_account_sheet.dart';
import 'package:nusarta/features/budgets/budgets_page.dart';
import 'package:nusarta/features/dashboard/app_shell.dart';
import 'package:nusarta/features/dashboard/dashboard_page.dart';
import 'package:nusarta/features/goals/goals_page.dart';
import 'package:nusarta/features/lock/pin_unlock_page.dart';
import 'package:nusarta/features/profile/profile_page.dart';
import 'package:nusarta/features/reports/reports_page.dart';
import 'package:nusarta/features/settings/settings_page.dart';
import 'package:nusarta/features/splash/splash_page.dart';
import 'package:nusarta/features/transactions/add_transaction_sheet.dart';
import 'package:nusarta/features/transactions/transactions_page.dart';
import 'package:nusarta/features/transfers/transfer_page.dart';
import 'package:nusarta/providers/auth_provider.dart';
import 'package:nusarta/providers/finance_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

// Deliberately long names and large amounts are test fixtures, never production defaults.
const accounts = [
  Account(
      id: 'bank',
      userId: 'u',
      name: 'Rekening Kebutuhan Keluarga Bulanan',
      type: AccountType.bank,
      balance: 1234567890,
      institutionId: 'inst',
      maskedAccountNumber: '•••• 1234',
      isPrimary: true),
  Account(
      id: 'cash',
      userId: 'u',
      name: 'Dompet Tunai',
      type: AccountType.cash,
      balance: 250000),
  Account(
      id: 'wallet',
      userId: 'u',
      name: 'Dompet Digital',
      type: AccountType.ewallet,
      balance: 300000),
];
const categories = [
  Category(
      id: 'cat', userId: 'u', name: 'Kebutuhan rumah tangga dan transportasi')
];
final transactions = [
  Transaction(
      id: 'income',
      userId: 'u',
      accountId: 'bank',
      kind: TransactionKind.income,
      amount: 4500000,
      occurredAt: DateTime.now(),
      note: 'Pemasukan bulanan'),
  Transaction(
      id: 'expense',
      userId: 'u',
      accountId: 'bank',
      categoryId: 'cat',
      kind: TransactionKind.expense,
      amount: 125000,
      occurredAt: DateTime.now(),
      note: 'Belanja kebutuhan rumah tangga untuk satu minggu'),
];
const fixtureUser = User(
    id: 'u',
    appMetadata: {},
    userMetadata: {'display_name': 'Pengguna Pengujian'},
    aud: 'authenticated',
    createdAt: '2026-01-01T00:00:00Z',
    email: 'pengujian@example.test');

Future<GoRouter> mount(
    WidgetTester tester, Widget page, double width, bool dark,
    {GlobalKey? boundary}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 820);
  final router = GoRouter(initialLocation: '/preview', routes: [
    GoRoute(path: '/preview', builder: (_, __) => page),
    GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: Text('Gate berikutnya'))),
    GoRoute(
        path: '/settings',
        builder: (_, state) =>
            SettingsPage(section: state.uri.queryParameters['section'])),
    GoRoute(
        path: '/transactions', builder: (_, __) => const TransactionsPage()),
    GoRoute(path: '/budgets', builder: (_, __) => const BudgetsPage()),
    GoRoute(path: '/reports', builder: (_, __) => const ReportsPage()),
  ]);
  await tester.pumpWidget(ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(fixtureUser),
        accountsProvider.overrideWith((ref) async => accounts),
        transactionsProvider.overrideWith((ref) async => transactions),
        allCategoriesProvider.overrideWith((ref) async => categories),
        categoriesProvider.overrideWith((ref, kind) async => categories),
        institutionsProvider.overrideWith((ref) async => const [
              Institution(
                  id: 'inst',
                  code: 'test',
                  name: 'Institusi Pengujian',
                  institutionType: 'bank')
            ]),
        budgetsProvider.overrideWith((ref) async => const [
              Budget(
                  id: 'budget', userId: 'u', categoryId: 'cat', amount: 500000)
            ]),
        goalsProvider.overrideWith((ref) async => const [
              FinancialGoal(
                  id: 'goal',
                  userId: 'u',
                  name: 'Dana pendidikan dan kebutuhan masa depan',
                  target: 20000000,
                  current: 750000)
            ]),
        notificationsProvider.overrideWith((ref) async => []),
        devicesProvider.overrideWith((ref) async => []),
        securityEventsProvider.overrideWith((ref) async => []),
        currentDeviceIdProvider.overrideWith((ref) async => 'test-device'),
      ],
      child: RepaintBoundary(
          key: boundary,
          child: MaterialApp.router(
            routerConfig: router,
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
          ))));
  await tester.pumpAndSettle();
  return router;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);
  });
  tearDown(() => TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null));

  const pages = <String, Widget>{
    'splash': SplashPage(),
    'pin': PinUnlockPage(),
    'dashboard': DashboardPage(),
    'transactions': TransactionsPage(),
    'accounts': AccountsPage(),
    'reports': ReportsPage(),
    'budget': BudgetsPage(),
    'goals': GoalsPage(),
    'security': SettingsPage(),
    'profile': ProfilePage(),
    'transfer': TransferPage(),
    'navigation': AppShell(),
  };
  for (final width in [360.0, 375.0, 390.0, 412.0, 430.0]) {
    for (final dark in [false, true]) {
      for (final entry in pages.entries) {
        testWidgets(
            '${entry.key} ${width.toInt()} ${dark ? 'dark' : 'light'} has no overflow',
            (tester) async {
          final boundary = GlobalKey();
          final router =
              await mount(tester, entry.value, width, dark, boundary: boundary);
          expect(tester.takeException(), isNull);
          if (const bool.fromEnvironment('CAPTURE_UI')) {
            final render = boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
            final image = await render.toImage(pixelRatio: 1);
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            await tester.runAsync(() async {
              final dir = Directory('../../.ui-audit/apk-final/screenshots')
                ..createSync(recursive: true);
              File('${dir.path}/${entry.key}-${width.toInt()}-${dark ? 'dark' : 'light'}.png')
                  .writeAsBytesSync(bytes!.buffer.asUint8List());
            });
            image.dispose();
          }
          // Force off-screen content to build, including charts and lower financial cards.
          final scroll = find.byType(Scrollable).hitTestable();
          if (scroll.evaluate().isNotEmpty && entry.key != 'splash') {
            await tester.drag(scroll.first, const Offset(0, -600));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(seconds: 2));
          router.dispose();
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      }
      testWidgets('account detail and filters $width $dark', (tester) async {
        final router = await mount(tester, const AccountsPage(), width, dark);
        await tester.tap(find.widgetWithText(ChoiceChip, 'Tunai'));
        await tester.pumpAndSettle();
        expect(find.text('Dompet Tunai'), findsOneWidget);
        expect(find.text(accounts.first.name), findsNothing);
        await tester.tap(find.widgetWithText(ChoiceChip, 'Semua'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(accounts.first.name));
        await tester.pumpAndSettle();
        expect(find.text('Nomor Akun'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.drag(
            find.byType(Scrollable).hitTestable().last, const Offset(0, -700));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        router.dispose();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      for (final sheet in [
        const AddAccountSheet(),
        const AddTransactionSheet()
      ]) {
        testWidgets('keyboard ${sheet.runtimeType} $width $dark',
            (tester) async {
          final router = await mount(
              tester,
              Scaffold(
                  body: Builder(
                      builder: (context) => TextButton(
                          onPressed: () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (_) => sheet),
                          child: const Text('Ouvrir')))),
              width,
              dark);
          await tester.tap(find.text('Ouvrir'));
          await tester.pumpAndSettle();
          tester.view.viewInsets = const FakeViewPadding(bottom: 300);
          await tester.pumpAndSettle();
          final scroll = find.byType(Scrollable).hitTestable();
          await tester.drag(scroll.last, const Offset(0, -1200));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final save = find.widgetWithText(FilledButton,
              sheet is AddAccountSheet ? 'Simpan Akun' : 'Simpan');
          expect(save, findsOneWidget);
          expect(tester.getRect(save).bottom, lessThanOrEqualTo(520));
          await tester.pumpWidget(const SizedBox());
          router.dispose();
          tester.view.resetViewInsets();
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      }
    }
  }
}
