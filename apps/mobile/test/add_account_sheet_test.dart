import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nusarta/data/models/account.dart';
import 'package:nusarta/features/accounts/add_account_sheet.dart';
import 'package:nusarta/providers/finance_providers.dart';

const retryMessage =
    'Akun belum berhasil disimpan. Periksa koneksi dan coba lagi.';
const savedAccount = Account(
  id: 'test-account',
  userId: 'test-user',
  name: 'Tabungan',
  type: AccountType.cash,
  balance: 125000,
);

class ControlledAccountsController extends AccountsController {
  ControlledAccountsController(super.ref);

  final writes = <Completer<Account>>[];
  final payloads = <Map<String, Object?>>[];

  @override
  Future<Account> createAccount({
    required String name,
    required AccountType type,
    double balance = 0,
    String? institutionId,
    String? lastFour,
    String? maskedAccountNumber,
    String? displayName,
    bool isPrimary = false,
  }) {
    payloads.add({
      'name': name,
      'type': type,
      'balance': balance,
      'institutionId': institutionId,
      'lastFour': lastFour,
      'maskedAccountNumber': maskedAccountNumber,
      'displayName': displayName,
      'isPrimary': isPrimary,
    });
    final write = Completer<Account>();
    writes.add(write);
    return write.future;
  }
}

Finder field(String label) => find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.labelText == label,
    );

Future<ControlledAccountsController> openSheet(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1000, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  late ControlledAccountsController controller;
  await tester.pumpWidget(ProviderScope(
    overrides: [
      institutionsProvider.overrideWith((ref) async => []),
      accountsControllerProvider.overrideWith(
          (ref) => controller = ControlledAccountsController(ref)),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Builder(builder: (context) {
          return TextButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => const AddAccountSheet(),
            ),
            child: const Text('Open account sheet'),
          );
        }),
      ),
    ),
  ));
  await tester.tap(find.text('Open account sheet'));
  await tester.pumpAndSettle();
  await tester.tap(find.byType(DropdownButtonFormField<Object?>));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Kas / Tunai').last);
  await tester.pumpAndSettle();
  await tester.enterText(field('Nama Akun'), 'Tabungan');
  await tester.enterText(field('4 Digit Terakhir (opsional)'), '1234');
  await tester.enterText(field('Saldo Awal (opsional)'), '125000');
  await tester.tap(find.byType(SwitchListTile));
  await tester.pump();
  // The controller is lazily constructed on the first save.
  final element = tester.element(find.byType(AddAccountSheet));
  ProviderScope.containerOf(element, listen: false)
      .read(accountsControllerProvider);
  return controller;
}

Future<void> failSave(
    WidgetTester tester, ControlledAccountsController controller) async {
  await tester.tap(find.text('Simpan Akun'));
  await tester.pump();
  controller.writes.last
      .completeError(const SocketException('Injected offline failure'));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('successful save closes sheet only after confirmed write',
      (tester) async {
    final controller = await openSheet(tester);
    await tester.tap(find.text('Simpan Akun'));
    await tester.pump();
    expect(controller.writes, hasLength(1));
    expect(find.byType(AddAccountSheet), findsOneWidget);
    expect(find.text('Menyimpan...'), findsOneWidget);
    controller.writes.single.complete(savedAccount);
    await tester.pumpAndSettle();
    expect(find.byType(AddAccountSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed save keeps sheet open and shows retry feedback',
      (tester) async {
    final controller = await openSheet(tester);
    await failSave(tester, controller);
    expect(find.byType(AddAccountSheet), findsOneWidget);
    expect(find.text(retryMessage), findsOneWidget);
    expect(find.text('Injected offline failure'), findsNothing);
  });

  testWidgets('failed save preserves every entered form value', (tester) async {
    final controller = await openSheet(tester);
    await failSave(tester, controller);
    expect(tester.widget<TextField>(field('Nama Akun')).controller!.text,
        'Tabungan');
    expect(
        tester
            .widget<TextField>(field('4 Digit Terakhir (opsional)'))
            .controller!
            .text,
        '1234');
    expect(
        tester
            .widget<TextField>(field('Saldo Awal (opsional)'))
            .controller!
            .text,
        '125000');
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isTrue);
    expect(find.text('Kas / Tunai'), findsOneWidget);
    await tester.tap(find.text('Simpan Akun'));
    await tester.pump();
    expect(controller.payloads.last, equals(controller.payloads.first));
    controller.writes.last.complete(savedAccount);
    await tester.pumpAndSettle();
  });

  testWidgets('duplicate submission blocked before rebuild and while saving',
      (tester) async {
    final controller = await openSheet(tester);
    final save = tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, 'Simpan Akun'))
        .onPressed!;
    save();
    save();
    await tester.pump();
    expect(controller.writes, hasLength(1));
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    await tester.tap(find.text('Menyimpan...'));
    await tester.pump();
    expect(controller.writes, hasLength(1));
    controller.writes.single.complete(savedAccount);
    await tester.pumpAndSettle();
  });

  testWidgets('failure has no false success and retry waits for confirmation',
      (tester) async {
    final controller = await openSheet(tester);
    await failSave(tester, controller);
    expect(find.text('Menyimpan...'), findsNothing);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull);
    expect(find.byType(AddAccountSheet), findsOneWidget);
    await tester.tap(find.text('Simpan Akun'));
    await tester.pump();
    expect(controller.writes, hasLength(2));
    expect(find.text(retryMessage), findsNothing);
    expect(find.byType(AddAccountSheet), findsOneWidget);
    controller.writes.last.complete(savedAccount);
    await tester.pumpAndSettle();
    expect(find.byType(AddAccountSheet), findsNothing);
  });

  testWidgets('empty name and invalid last four retain existing validation',
      (tester) async {
    final controller = await openSheet(tester);
    await tester.enterText(field('Nama Akun'), '   ');
    await tester.pump();
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    await tester.enterText(field('Nama Akun'), 'Tabungan');
    await tester.enterText(field('4 Digit Terakhir (opsional)'), '123');
    await tester.pump();
    await tester.tap(find.text('Simpan Akun'));
    await tester.pump();
    expect(
        find.text('Masukkan 4 digit terakhir nomor rekening.'), findsOneWidget);
    expect(controller.writes, isEmpty);
    expect(find.text('Menyimpan...'), findsNothing);
  });

  testWidgets('write failure after sheet dismissal is safely handled',
      (tester) async {
    final controller = await openSheet(tester);
    await tester.tap(find.text('Simpan Akun'));
    await tester.pump();
    Navigator.of(tester.element(find.byType(AddAccountSheet))).pop();
    await tester.pumpAndSettle();
    controller.writes.single
        .completeError(const SocketException('Injected offline failure'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(AddAccountSheet), findsNothing);
  });
}
