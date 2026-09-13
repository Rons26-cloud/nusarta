import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nusarta/data/models/account.dart';
import 'package:nusarta/data/models/institution.dart';
import 'package:nusarta/features/connections/financial_provider_adapter.dart';
import 'package:nusarta/features/transfers/transfer_page.dart';
import 'package:nusarta/providers/finance_providers.dart';

class FakeTransferActions implements TransferActions {
  FakeTransferActions({
    this.recipientValidationAvailable = false,
    this.failStart = false,
    this.pending,
    this.directResult = const TransferReferenceResult(
        reference: 'ref-test-1', status: TransferStepStatus.success),
  });

  @override
  final bool recipientValidationAvailable;
  final bool failStart;
  final Future<void>? pending;
  final TransferReferenceResult directResult;

  @override
  Future<RecipientValidation> validateRecipient(
          {required Institution target,
          required String accountIdentifier}) async =>
      const RecipientValidation(valid: true, displayName: 'ALICE');

  @override
  Future<TransferQuote> getQuote(
          {required Institution target,
          required TransferRequest request}) async =>
      const TransferQuote(fee: 2500);

  @override
  Future<TransferReferenceResult> startTransfer(
      {required Institution target, required TransferRequest request}) async {
    if (pending != null) await pending;
    if (failStart) {
      throw UnsupportedError('Provider keuangan resmi belum tersedia.');
    }
    return directResult;
  }
}

Account sourceAccount() => const Account(
      id: 'acc1',
      userId: 'u1',
      name: 'BCA',
      type: AccountType.bank,
      balance: 5000000,
      isLinked: true,
      maskedAccountNumber: '•••• 4821',
      institutionId: 'inst-1',
      displayName: 'BCA',
      connectionType: ConnectionType.bankApi,
      connectionStatus: ConnectionStatus.active,
    );

List<Institution> catalog() => const [
      Institution(
        id: 'inst-1',
        code: 'BCA',
        name: 'BCA',
        institutionType: 'bank',
        providerSupport: {
          'integration_status': 'coming_soon',
          'link_supported': false,
          'sync_supported': false,
          'transfer_supported': false,
        },
      ),
      Institution(
        id: 'inst-2',
        code: 'GOPAY',
        name: 'GoPay',
        institutionType: 'ewallet',
      ),
    ];

Widget flow(TransferActions actions) => MaterialApp(
      locale: const Locale('id'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('id')],
      home: Scaffold(
        body: TransferFlow(
          sources: [sourceAccount()],
          institutions: catalog(),
          actions: actions,
        ),
      ),
    );

Future<void> driveToRecipient(WidgetTester tester) async {
  await tester.pumpAndSettle();
  expect(find.text('Pilih Sumber Dana'), findsOneWidget);
  expect(find.text('BCA •••• 4821'), findsNothing); // masked is separate Text
  await tester.tap(find.text('Lanjut'));
  await tester.pumpAndSettle();
  expect(find.text('Pilih Tujuan'), findsOneWidget);
}

Future<void> fillTargetAndAmount(WidgetTester tester) async {
  await tester.tap(find.text('BCA'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).first, '1234567890');
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilledButton, 'Lanjut'));
  await tester.pumpAndSettle();
  expect(find.text('Nominal Transfer'), findsOneWidget);
  await tester.enterText(find.byType(TextField).first, '100000');
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilledButton, 'Lanjutkan'));
  await tester.pumpAndSettle();
  expect(find.text('Konfirmasi Transfer'), findsWidgets);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('transfer page (flag off) shows honest Segera Hadir',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        accountsProvider
            .overrideWith((ref) => Future.value(<Account>[sourceAccount()])),
        institutionsProvider.overrideWith((ref) => Future.value(catalog())),
      ],
      child: const MaterialApp(
        locale: Locale('id'),
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('id')],
        home: TransferPage(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Transfer'), findsWidgets);
    expect(find.text('Segera Hadir'), findsOneWidget);
    expect(find.textContaining('provider resmi'), findsWidgets);
  });

  testWidgets('successful flow ends on NUSARTA receipt, no PIN anywhere',
      (tester) async {
    await tester.pumpWidget(flow(FakeTransferActions()));
    await driveToRecipient(tester);
    await fillTargetAndAmount(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Konfirmasi Transfer'));
    await tester.pumpAndSettle();
    expect(find.text('Transfer Berhasil'), findsWidgets);
    expect(find.text('ref-test-1'), findsOneWidget);
    // The bank PIN is never collected by NUSARTA.
    expect(find.textContaining('Masukkan PIN'), findsNothing);
    expect(find.textContaining('PIN BCA'), findsNothing);
    expect(find.textContaining('diproses melalui penyedia'), findsWidgets);
  });

  testWidgets('no live provider -> honest failed receipt', (tester) async {
    await tester.pumpWidget(flow(FakeTransferActions(failStart: true)));
    await driveToRecipient(tester);
    await fillTargetAndAmount(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Konfirmasi Transfer'));
    await tester.pumpAndSettle();
    expect(find.text('Transfer tidak berhasil'), findsWidgets);
    expect(find.textContaining('Provider keuangan resmi belum tersedia.'),
        findsOneWidget);
    expect(find.text('Transfer Berhasil'), findsNothing);
  });

  testWidgets('authorization state is intermediate, not a fake PIN pad',
      (tester) async {
    final gate = Completer<void>();
    await tester.pumpWidget(flow(FakeTransferActions(pending: gate.future)));
    await driveToRecipient(tester);
    await fillTargetAndAmount(tester);
    // Confirm while the authorization is still running (gated).
    await tester.tap(find.widgetWithText(FilledButton, 'Konfirmasi Transfer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Menunggu Otorisasi'), findsOneWidget);
    // No PIN field exists during authorization — never a fake keypad.
    expect(find.byType(TextField), findsNothing);
    expect(find.textContaining('Masukkan PIN'), findsNothing);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('Transfer Berhasil'), findsWidgets);
  });

  testWidgets('recipient validation comes from provider, not user input',
      (tester) async {
    await tester.pumpWidget(
        flow(FakeTransferActions(recipientValidationAvailable: true)));
    await driveToRecipient(tester);
    await tester.tap(find.text('BCA'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '1234567890');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Validasi Penerima'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Nama penerima: ALICE'), findsOneWidget);
    // No free-text recipient-name field exists anywhere in the flow.
    expect(find.widgetWithText(TextField, 'Nama penerima'), findsNothing);
  });
}
