import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nusarta/data/models/account.dart';
import 'package:nusarta/data/models/institution.dart';
import 'package:nusarta/data/models/transaction.dart';
import 'package:nusarta/features/accounts/account_detail_page.dart';
import 'package:nusarta/providers/finance_providers.dart';

void main() {
  Account linked(String id,
          {bool synced = false, bool transferSupported = false}) =>
      Account(
        id: id,
        userId: 'u1',
        name: 'BCA',
        type: AccountType.bank,
        balance: 4000000,
        isLinked: true,
        maskedAccountNumber: '•••• 4821',
        institutionId: 'inst-bca',
        displayName: 'BCA',
        connectionType: ConnectionType.bankApi,
        connectionStatus: ConnectionStatus.active,
        lastSyncedAt: synced ? DateTime(2026, 9, 12) : null,
      );

  Institution inst({bool transferSupported = false}) => Institution(
        id: 'inst-bca',
        code: 'BCA',
        name: 'BCA',
        institutionType: 'bank',
        providerSupport: {
          'integration_status': 'coming_soon',
          'link_supported': false,
          'sync_supported': false,
          'transfer_supported': transferSupported,
        },
      );

  Widget wrap(
          {required Account account,
          Institution? institution,
          bool withInst = true}) =>
      ProviderScope(
        overrides: [
          accountsProvider.overrideWith((ref) => Future.value([account])),
          institutionsProvider.overrideWith((ref) => Future.value(
              withInst ? [institution ?? inst()] : const <Institution>[])),
          transactionsProvider
              .overrideWith((ref) => Future.value(const <Transaction>[])),
        ],
        child: MaterialApp(
          locale: const Locale('id'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('id')],
          home: AccountDetailPage(accountId: account.id),
        ),
      );

  setUpAll(() {
    initializeDateFormatting('id_ID');
  });

  testWidgets('renders connected account header and masked number',
      (tester) async {
    final account = linked('acc1');
    await tester.pumpWidget(wrap(account: account));
    await tester.pumpAndSettle();
    expect(find.text('Detail Akun'), findsOneWidget);
    expect(find.text('BCA'), findsWidgets);
    expect(find.text('•••• 4821'), findsOneWidget);
    expect(find.text('Terhubung'), findsOneWidget);
    expect(find.text('Belum pernah'), findsOneWidget);
  });

  testWidgets('balance hidden until a real sync happened', (tester) async {
    await tester.pumpWidget(wrap(account: linked('acc1')));
    await tester.pumpAndSettle();
    expect(find.text('Saldo tidak tersedia'), findsOneWidget);
    expect(find.text('Rp4.000.000'), findsNothing);
  });

  testWidgets('balance shown only after the provider allowed a sync',
      (tester) async {
    await tester.pumpWidget(wrap(account: linked('acc1', synced: true)));
    await tester.pumpAndSettle();
    expect(find.text('Rp4.000.000'), findsOneWidget);
    expect(find.text('Saldo tidak tersedia'), findsNothing);
  });

  testWidgets('transfer action gated by real transfer capability',
      (tester) async {
    await tester.pumpWidget(wrap(account: linked('acc1')));
    await tester.pumpAndSettle();
    final transfer = tester.widget<FilledButton>(find.ancestor(
        of: find.text('Transfer'),
        matching: find.byWidgetPredicate((w) => w is FilledButton)));
    expect(transfer.onPressed, isNull);
    expect(
        find.text('Transfer belum didukung untuk akun ini.'), findsOneWidget);
  });

  testWidgets('unknown account shows not-found state', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        accountsProvider.overrideWith((ref) => Future.value(const [])),
      ],
      child: const MaterialApp(home: AccountDetailPage(accountId: 'zzz')),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Akun tidak ditemukan.'), findsOneWidget);
  });
}
