import 'dart:async';
import 'dart:io';

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:nusarta/data/models/transaction.dart';
import 'package:nusarta/features/dashboard/app_shell.dart';
import 'package:nusarta/features/dashboard/dashboard_page.dart';
import 'package:nusarta/features/reports/finance_view_data.dart';
import 'package:nusarta/features/reports/reports_page.dart';
import 'package:nusarta/providers/finance_providers.dart';
import 'package:nusarta/widgets/cash_flow_chart.dart';
import 'package:nusarta/widgets/finance_transaction_entry.dart';
import 'final_ui_test.dart' as fixtures;

Transaction tx(String id, DateTime date, double amount,
        {TransactionKind kind = TransactionKind.expense,
        String account = 'bank',
        String category = 'cat'}) =>
    Transaction(
        id: id,
        userId: 'u',
        accountId: account,
        categoryId: category,
        kind: kind,
        amount: amount,
        title: id,
        occurredAt: date);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
    const fontPath = String.fromEnvironment('CAPTURE_FONT');
    if (fontPath.isNotEmpty) {
      final loader = FontLoader('Roboto');
      loader.addFont(File(fontPath)
          .readAsBytes()
          .then((bytes) => ByteData.sublistView(bytes)));
      await loader.load();
    }
  });
  const secure = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  setUp(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(secure, (_) async => null));
  tearDown(() => TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger
      .setMockMethodCallHandler(secure, null));

  test(
      'month boundaries, combined filters, sorting, transfer exclusion and cache',
      () {
    final source = [
      tx('last', DateTime(2026, 9, 30, 23, 59), 30),
      tx('start', DateTime(2026, 9, 1), 100, kind: TransactionKind.income),
      tx('old', DateTime(2026, 8, 31, 23, 59), 500),
      tx('next', DateTime(2026, 10, 1), 500),
      tx('other', DateTime(2026, 9, 12), 20,
          account: 'cash', category: 'other'),
      tx('transfer', DateTime(2026, 9, 13), 900,
          kind: TransactionKind.transfer),
    ];
    final cache = FinanceViewCache();
    final data = cache.get(source, DateTime(2026, 9), DateTime(2026, 10));
    expect(data.income, 100);
    expect(data.expense, 50);
    expect(data.net, 50);
    expect(data.transactions.first.id, 'last');
    expect(data.cashCount, 3);
    expect(data.average, 50);
    expect(data.expenseCategories['cat']!.count, 1);
    expect(
        identical(
            data, cache.get(source, DateTime(2026, 9), DateTime(2026, 10))),
        isTrue);
    final filtered = cache.get(source, DateTime(2026, 9), DateTime(2026, 10),
        kind: TransactionKind.expense, accountId: 'bank', categoryId: 'cat');
    expect(filtered.transactions.map((t) => t.id), ['last']);
  });

  test(
      'daily leap-month and year buckets retain real timestamps, never fabricate aggregate time',
      () {
    final timestamp = DateTime(2024, 2, 29, 10, 42);
    final source = [
      tx('leap', timestamp, 20),
      tx('jan', DateTime(2024, 1, 1), 100, kind: TransactionKind.income)
    ];
    final month = cashFlowBuckets(source, DateTime(2024, 2), DateTime(2024, 3),
        yearly: false);
    expect(month.length, 29);
    expect(month.last.expense, 20);
    expect(month.last.singleTimestamp, timestamp);
    final year =
        cashFlowBuckets(source, DateTime(2024), DateTime(2025), yearly: true);
    expect(year.length, 12);
    expect(year.first.income, 100);
    expect(year[1].expense, 20);
    final multiple = cashFlowBuckets([
      ...source,
      tx('second', timestamp.add(const Duration(hours: 1)), 5)
    ], DateTime(2024, 2), DateTime(2024, 3), yearly: false);
    expect(multiple.last.singleTimestamp, isNull);
    expect(multiple.last.count, 2);
    final utc = DateTime.parse('2026-09-12T03:42:00Z');
    expect(localTransactionDateTime(utc),
        DateFormat('d MMM yyyy • HH:mm', 'id_ID').format(utc.toLocal()));
  });

  for (final width in [360.0, 375.0, 390.0, 412.0, 430.0]) {
    for (final dark in [false, true]) {
      testWidgets('home scroll reaches end above navigation $width dark=$dark',
          (tester) async {
        final router =
            await fixtures.mount(tester, const AppShell(), width, dark);
        final home = find.byType(DashboardPage);
        final scroll =
            find.descendant(of: home, matching: find.byType(Scrollable)).first;
        await tester.scrollUntilVisible(
            find.byKey(const ValueKey('home-end')), 500,
            scrollable: scroll, maxScrolls: 30);
        await tester.pumpAndSettle();
        final end = tester.getRect(find.byKey(const ValueKey('home-end')));
        final nav = tester.getRect(find.byType(NavigationBar));
        expect(end.bottom, lessThanOrEqualTo(nav.top));
        await tester.tap(find.descendant(
            of: find.byType(NavigationBar), matching: find.text('Laporan')));
        await tester.pumpAndSettle();
        expect(find.text('Bulan').hitTestable(), findsOneWidget,
            reason: 'Scrolling Home must not move the report tab.');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        router.dispose();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      testWidgets(
          'report chart tap, drag, year and full detail scroll $width dark=$dark',
          (tester) async {
        final captureBoundary = GlobalKey();
        final router = await fixtures.mount(
            tester, const ReportsPage(), width, dark,
            boundary: captureBoundary);
        final scroll = find.byType(Scrollable).first;
        await tester.scrollUntilVisible(
            find.byKey(const ValueKey('cashflow-plot')), 300,
            scrollable: scroll);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('cashflow-plot')));
        await tester.pumpAndSettle();
        expect(find.textContaining('Net:'), findsOneWidget);
        await captureChart(tester, captureBoundary, 'month--');
        final position = tester.state<ScrollableState>(scroll).position;
        final before = position.pixels;
        await tester.drag(
            find.byKey(const ValueKey('cashflow-plot')), const Offset(0, -160));
        await tester.pumpAndSettle();
        expect(position.pixels, greaterThan(before));
        await tester.scrollUntilVisible(
            find.byKey(const ValueKey('report-end')), 550,
            scrollable: scroll, maxScrolls: 40);
        await tester.pumpAndSettle();
        expect(tester.getRect(find.byKey(const ValueKey('report-end'))).bottom,
            lessThanOrEqualTo(820));
        expect(tester.takeException(), isNull);
        position.jumpTo(0);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tahun'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.byType(CashFlowChart), 300,
            scrollable: scroll);
        await captureChart(tester, captureBoundary, 'year--');
        expect(tester.widget<CashFlowChart>(find.byType(CashFlowChart)).yearly,
            isTrue);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        router.dispose();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }
  }

  testWidgets(
      'report filters affect amounts and transactions; transaction opens real detail',
      (tester) async {
    final router =
        await fixtures.mount(tester, const ReportsPage(), 390, false);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Pengeluaran'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dompet Tunai').last);
    await tester.pumpAndSettle();
    expect(find.text('Belum ada transaksi pada periode ini.'), findsOneWidget);
    await tester.tap(find.text('Reset filter'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(fixtures.categories.first.name).last);
    await tester.pumpAndSettle();
    final scroll = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(find.byType(FinanceTransactionEntry), 400,
        scrollable: scroll, maxScrolls: 30);
    await tester.pumpAndSettle();
    final entry = tester.widget<FinanceTransactionEntry>(
        find.byType(FinanceTransactionEntry).first);
    expect(entry.transaction.kind, TransactionKind.expense);
    await tester.tap(find.byType(FinanceTransactionEntry).first);
    await tester.pumpAndSettle();
    expect(find.text('Detail Transaksi'), findsOneWidget);
    expect(find.text('Jam transaksi'), findsOneWidget);
    expect(find.textContaining(localUtcOffset(entry.transaction.occurredAt)),
        findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets(
      'report distinguishes loading, error, retry and empty without loops',
      (tester) async {
    final pending = Completer<List<Transaction>>();
    var attempts = 0;
    await tester.pumpWidget(ProviderScope(overrides: [
      transactionsProvider.overrideWith((_) {
        attempts++;
        return attempts == 1 ? pending.future : Future.value(<Transaction>[]);
      }),
      accountsProvider.overrideWith((_) async => fixtures.accounts),
      allCategoriesProvider.overrideWith((_) async => fixtures.categories),
      budgetsProvider.overrideWith((_) async => []),
      goalsProvider.overrideWith((_) async => []),
    ], child: const MaterialApp(home: ReportsPage())));
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsWidgets);
    pending.completeError(Exception('test'));
    await tester.pumpAndSettle();
    expect(find.text('Coba lagi'), findsOneWidget);
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada transaksi pada periode ini.'), findsOneWidget);
    expect(find.text('Coba lagi'), findsNothing);
    expect(attempts, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}

Future<void> captureChart(
    WidgetTester tester, GlobalKey boundary, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_HOME_REPORTS')) return;
  await Scrollable.ensureVisible(tester.element(find.byType(CashFlowChart)),
      alignment: 0);
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final render =
        boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final picture = await render.toImage(pixelRatio: 1);
    final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
    final directory = Directory('build/home-reports-screenshots')
      ..createSync(recursive: true);
    File('${directory.path}/$name.png')
        .writeAsBytesSync(bytes!.buffer.asUint8List());
    picture.dispose();
  });
}
