import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nusarta/data/models/account.dart';
import 'package:nusarta/features/dashboard/connected_accounts_section.dart';

Account linkedSynced() => const Account(
      id: 'linked-1',
      userId: 'u1',
      name: 'BCA',
      type: AccountType.bank,
      balance: 1250000,
      isLinked: true,
      maskedAccountNumber: '•••• 4821',
      institutionId: 'inst-bca',
      displayName: 'BCA',
      connectionType: ConnectionType.bankApi,
      connectionStatus: ConnectionStatus.active,
      lastSyncedAt: null,
    );

Widget wrap(List<Account> accounts) => MaterialApp(
      locale: const Locale('id'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('id')],
      home: Scaffold(
        body: SingleChildScrollView(
          child: ConnectedAccountsSection(
            accounts: accounts,
            institutions: const [],
            hidden: false,
          ),
        ),
      ),
    );

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });
  testWidgets('hidden entirely when nothing is linked', (tester) async {
    await tester.pumpWidget(wrap(const [
      Account(
        id: 'm1',
        userId: 'u1',
        name: 'Tabungan',
        type: AccountType.cash,
        balance: 1000,
      )
    ]));
    expect(find.text('Akun Terhubung'), findsNothing);
  });

  testWidgets('linked-but-never-synced shows Saldo tidak tersedia',
      (tester) async {
    await tester.pumpWidget(wrap([linkedSynced()]));
    await tester.pumpAndSettle();
    expect(find.text('Akun Terhubung'), findsOneWidget);
    expect(find.text('BCA'), findsOneWidget);
    expect(find.text('•••• 4821'), findsOneWidget);
    expect(find.text('Saldo tidak tersedia'), findsOneWidget);
    expect(find.text('Belum sinkron'), findsOneWidget);
    // Balance is only asserted when the provider actually allowed a read.
    expect(find.text('Rp 1.250.000'), findsNothing);
  });

  testWidgets('non-linked manual accounts are excluded from the carousel',
      (tester) async {
    await tester.pumpWidget(wrap([
      linkedSynced(),
      const Account(
        id: 'm2',
        userId: 'u1',
        name: 'Cash Harian',
        type: AccountType.cash,
        balance: 5000,
      ),
    ]));
    await tester.pumpAndSettle();
    expect(find.text('Cash Harian'), findsNothing);
    expect(find.byType(SizedBox), findsWidgets);
  });
}
