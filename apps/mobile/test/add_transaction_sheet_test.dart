import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nusarta/data/models/account.dart';
import 'package:nusarta/data/models/transaction.dart';
import 'package:nusarta/features/transactions/add_transaction_sheet.dart';
import 'package:nusarta/providers/auth_provider.dart';
import 'package:nusarta/providers/finance_providers.dart';

const retryMessage =
    'Transaksi belum berhasil disimpan. Periksa koneksi dan coba lagi.';
const account = Account(
  id: 'account-1',
  userId: 'test-user',
  name: 'Dompet Tunai',
  type: AccountType.cash,
  balance: 100000,
);

class ControlledTransactionsController extends TransactionsController {
  ControlledTransactionsController(super.ref);

  final writes = <Completer<void>>[];
  final payloads = <Transaction>[];

  @override
  Future<void> addIncomeExpense(Transaction transaction) {
    payloads.add(transaction);
    final write = Completer<void>();
    writes.add(write);
    return write.future;
  }
}

Finder field(String label) => find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.labelText == label,
    );

Future<ControlledTransactionsController> openSheet(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1000, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  ControlledTransactionsController? controller;
  await tester.pumpWidget(ProviderScope(
    overrides: [
      accountsProvider.overrideWith((ref) async => [account]),
      categoriesProvider.overrideWith((ref, kind) async => []),
      currentUserProvider.overrideWithValue(null),
      transactionsControllerProvider.overrideWith(
          (ref) => controller ??= ControlledTransactionsController(ref)),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Builder(builder: (context) {
          return TextButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => const AddTransactionSheet(),
            ),
            child: const Text('Open transaction sheet'),
          );
        }),
      ),
    ),
  ));
  await tester.tap(find.text('Open transaction sheet'));
  await tester.pumpAndSettle();
  await tester.tap(find.byType(DropdownButtonFormField<String>).first);
  await tester.pumpAndSettle();
  await tester.tap(find.textContaining('Dompet Tunai').last);
  await tester.pumpAndSettle();
  await tester.enterText(field('Nominal (Rp)'), '25000');
  await tester.enterText(field('Catatan (opsional)'), 'Belanja mingguan');
  await tester.pump();
  final element = tester.element(find.byType(AddTransactionSheet));
  ProviderScope.containerOf(element, listen: false)
      .read(transactionsControllerProvider);
  return controller!;
}

Future<void> failSave(
    WidgetTester tester, ControlledTransactionsController controller) async {
  await tester.tap(find.text('Simpan'));
  await tester.pump();
  controller.writes.last.completeError(const SocketException('offline'));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));
  testWidgets('successful save closes only after confirmed write',
      (tester) async {
    final controller = await openSheet(tester);
    await tester.tap(find.text('Simpan'));
    await tester.pump();
    expect(controller.writes, hasLength(1));
    expect(find.byType(AddTransactionSheet), findsOneWidget);
    expect(find.text('Transaksi berhasil dicatat.'), findsNothing);
    controller.writes.single.complete();
    await tester.pumpAndSettle();
    expect(find.byType(AddTransactionSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed save keeps sheet open and shows visible retry feedback',
      (tester) async {
    final controller = await openSheet(tester);
    await failSave(tester, controller);
    expect(find.byType(AddTransactionSheet), findsOneWidget);
    expect(find.text(retryMessage), findsOneWidget);
    expect(find.text('Transaksi berhasil dicatat.'), findsNothing);
  });

  testWidgets('failed save preserves transaction fields', (tester) async {
    final controller = await openSheet(tester);
    await failSave(tester, controller);
    expect(tester.widget<TextField>(field('Nominal (Rp)')).controller!.text,
        '25.000');
    expect(
        tester.widget<TextField>(field('Catatan (opsional)')).controller!.text,
        'Belanja mingguan');
    expect(controller.payloads.single.accountId, 'account-1');
    expect(controller.payloads.single.amount, 25000);
  });

  testWidgets('duplicate submission is blocked while saving', (tester) async {
    final controller = await openSheet(tester);
    final save = tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, 'Simpan'))
        .onPressed!;
    save();
    save();
    await tester.pump();
    expect(controller.writes, hasLength(1));
    expect(find.text('Transaksi berhasil dicatat.'), findsNothing);
    controller.writes.single.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('retry after failure succeeds without false success',
      (tester) async {
    final controller = await openSheet(tester);
    await failSave(tester, controller);
    expect(find.byType(AddTransactionSheet), findsOneWidget);
    await tester.tap(find.text('Simpan'));
    await tester.pump();
    expect(controller.writes, hasLength(2));
    expect(find.text(retryMessage), findsNothing);
    expect(find.byType(AddTransactionSheet), findsOneWidget);
    controller.writes.last.complete();
    await tester.pumpAndSettle();
    expect(find.byType(AddTransactionSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
