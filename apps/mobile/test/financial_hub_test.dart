import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nusarta/data/models/account.dart';
import 'package:nusarta/data/repositories/balance_repository.dart';
import 'package:nusarta/features/transfers/transfer_page.dart';
import 'transfer_flow_test.dart' as fixture;

Account account(String id, double value,
        {String owner = 'u1',
        bool linked = true,
        bool archived = false,
        bool primary = false,
        String source = 'simulated',
        String currency = 'IDR',
        AccountType type = AccountType.bank,
        ConnectionStatus status = ConnectionStatus.active}) =>
    Account(
        id: id,
        userId: owner,
        name: id,
        type: type,
        balance: value,
        isLinked: linked,
        isArchived: archived,
        isPrimary: primary,
        connectionStatus: status,
        balanceSource: source,
        lastSyncedAt: DateTime(2026),
        currencyCode: currency,
        maskedAccountNumber: '•••• 1234',
        provider: 'nusarta_simulator',
        institutionId: 'inst-1',
        externalId: '990000123456');

void main() {
  const balances = BalanceRepository();
  setUpAll(() => initializeDateFormatting('id_ID'));
  test('aggregate 4 connected accounts is 4800000', () {
    expect(
        balances.total([
          account('BCA', 2500000),
          account('SeaBank', 1500000),
          account('DANA', 500000, type: AccountType.ewallet),
          account('GoPay', 300000, type: AccountType.ewallet)
        ]),
        4800000);
  });
  test('individual source balance never equals aggregate', () {
    final a = account('BCA', 2500000);
    expect(balances.read(a).amount, 2500000);
    expect(balances.total([a, account('SeaBank', 1500000)]), 4000000);
  });
  test(
      'manual balances excluded',
      () => expect(
          balances.total([account('Manual', 9000000, linked: false)]), 0));
  test(
      'archived excluded',
      () =>
          expect(balances.total([account('BCA', 9000000, archived: true)]), 0));
  test(
      'expired connection excluded',
      () => expect(
          balances.total(
              [account('BCA', 9000000, status: ConnectionStatus.expired)]),
          0));
  test('different currencies not added',
      () => expect(balances.total([account('BCA', 10, currency: 'USD')]), 0));
  test(
      'unknown source is unavailable',
      () => expect(balances.read(account('BCA', 100, source: 'unknown')).amount,
          isNull));
  test('NaN cannot poison total',
      () => expect(balances.total([account('BCA', double.nan)]), 0));
  test(
      'ownership scoped total',
      () => expect(
          balances.total([account('A', 100), account('B', 900, owner: 'u2')],
              userId: 'u1'),
          100));
  test(
      'live balance is authoritative',
      () => expect(
          balances.read(account('A', 100, source: 'live')).authoritative,
          isTrue));
  test('simulation is not authoritative bank balance',
      () => expect(balances.read(account('A', 100)).authoritative, isFalse));
  test('mask account identifier',
      () => expect(maskAccountIdentifier('1234567890'), '•••• 7890'));
  test('mask short identifier never reveals it',
      () => expect(maskAccountIdentifier('1234'), '••••'));
  test('mask wallet identifier',
      () => expect(maskAccountIdentifier('081234567890'), '•••• 7890'));

  Widget flow(List<Account> accounts, fixture.FakeTransferActions actions,
          {Future<bool> Function(BuildContext)? authorize}) =>
      MaterialApp(
          home: Scaffold(
              body: TransferFlow(
                  sources: accounts,
                  institutions: fixture.catalog(),
                  actions: actions,
                  authorize: authorize ?? (_) async => true)));
  testWidgets('default source and individual balance', (tester) async {
    await tester.pumpWidget(flow(
        [account('BCA', 2500000), account('SeaBank', 1500000, primary: true)],
        fixture.FakeTransferActions()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(find.text('Saldo Rp 1.500.000'), findsOneWidget);
    expect(find.text('Saldo Rp 2.500.000'), findsNothing);
    await tester.tap(find.text('Saldo Rp 1.500.000'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih Akun Sumber'), findsOneWidget);
    await tester.tap(find.text('Saldo Rp 2.500.000'));
    await tester.pumpAndSettle();
    expect(find.text('Saldo Rp 2.500.000'), findsOneWidget);
  });
  testWidgets('bank and wallet destination grouping', (tester) async {
    await tester.pumpWidget(
        flow([account('Source', 1000000)], fixture.FakeTransferActions()));
    await fixture.driveToRecipient(tester);
    expect(find.text('GoPay'), findsNothing);
    await tester.tap(find.widgetWithText(ChoiceChip, 'E-Wallet'));
    await tester.pumpAndSettle();
    expect(find.text('GoPay'), findsOneWidget);
    expect(find.text('BCA'), findsNothing);
  });
  testWidgets('insufficient source balance blocks review', (tester) async {
    await tester.pumpWidget(
        flow([account('Source', 100)], fixture.FakeTransferActions()));
    await fixture.driveToRecipient(tester);
    await tester.tap(find.text('BCA'));
    await tester.enterText(
        find.byKey(const Key('transfer-recipient')), '1234567890');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Lanjut'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '200');
    await tester.tap(find.text('Lanjutkan'));
    await tester.pumpAndSettle();
    expect(find.text('Saldo tidak mencukupi.'), findsOneWidget);
  });
  testWidgets('cancelled NUSARTA authorization never submits', (tester) async {
    final actions = fixture.FakeTransferActions();
    await tester.pumpWidget(flow([fixture.sourceAccount()], actions,
        authorize: (_) async => false));
    await fixture.driveToRecipient(tester);
    await fixture.fillTargetAndAmount(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Konfirmasi Transfer'));
    await tester.pumpAndSettle();
    expect(actions.requests, isEmpty);
  });
  testWidgets('duplicate tap submits once', (tester) async {
    final pending = Completer<void>();
    final actions = fixture.FakeTransferActions(pending: pending.future);
    await tester.pumpWidget(flow([fixture.sourceAccount()], actions));
    await fixture.driveToRecipient(tester);
    await fixture.fillTargetAndAmount(tester);
    final button = find.widgetWithText(FilledButton, 'Konfirmasi Transfer');
    await tester.tap(button);
    await tester.tap(button, warnIfMissed: false);
    await tester.pump();
    expect(actions.requests.length, 1);
    pending.complete();
    await tester.pumpAndSettle();
  });
}
