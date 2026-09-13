import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nusarta/data/models/account_connection.dart';
import 'package:nusarta/data/models/institution.dart';
import 'package:nusarta/features/connections/link_accounts_page.dart';
import 'package:nusarta/features/onboarding/link_account_tutorial_page.dart';
import 'package:nusarta/features/onboarding/onboarding_tutorial_page.dart';
import 'package:nusarta/providers/finance_providers.dart';

void main() {
  Widget wrapOnboarding() => const ProviderScope(
        child: MaterialApp(home: OnboardingTutorialPage()),
      );

  Widget wrapLinkTutorial() => const ProviderScope(
        child: MaterialApp(home: LinkAccountTutorialPage()),
      );

  Widget wrapLinkAccounts({bool withCatalog = false}) {
    final institutions = withCatalog
        ? <Institution>[
            const Institution(
              id: 'i1',
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
            const Institution(
              id: 'i2',
              code: 'GOPAY',
              name: 'GoPay',
              institutionType: 'ewallet',
            ),
          ]
        : <Institution>[];
    return ProviderScope(
      overrides: [
        institutionsProvider.overrideWith(
            (ref) => Future<List<Institution>>.value(institutions)),
        accountConnectionsProvider.overrideWith(
            (ref) => Future<List<AccountConnection>>.value(const [])),
      ],
      child: const MaterialApp(home: LinkAccountsPage()),
    );
  }

  testWidgets('onboarding tutorial walks all steps to Selesai', (tester) async {
    await tester.pumpWidget(wrapOnboarding());
    expect(find.text('Lewati'), findsOneWidget);
    expect(find.text('Selamat Datang di NUSARTA'), findsOneWidget);

    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(find.text('Tambahkan Transaksi'), findsOneWidget);

    // Walk to the final step.
    while (find.text('Selesai').evaluate().isEmpty) {
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Selesai'), findsOneWidget);
  });

  testWidgets('link-account tutorial renders steps and honesty banner',
      (tester) async {
    await tester.pumpWidget(wrapLinkTutorial());
    expect(find.text('Panduan Menghubungkan Akun'), findsOneWidget);
    expect(find.text('Buka Akun'), findsOneWidget);
    expect(find.textContaining('provider resmi'), findsWidgets);
    expect(find.textContaining('Segera Hadir'), findsOneWidget);

    await tester.scrollUntilVisible(
        find.text('Lihat dashboard & laporan'), 150);
    expect(find.text('Lihat dashboard & laporan'), findsOneWidget);
  });

  testWidgets('link accounts shows bank and e-wallet catalog when present',
      (tester) async {
    await tester.pumpWidget(wrapLinkAccounts(withCatalog: true));
    await tester.pump();
    expect(find.text('Hubungkan Akun'), findsOneWidget);
    expect(find.text('BANK'), findsNWidgets(2)); // chip + section header
    expect(find.text('E-WALLET'), findsNWidgets(2)); // chip + section header
    expect(find.text('BCA'), findsOneWidget);
    expect(find.text('GoPay'), findsOneWidget);
    expect(find.text('Segera Hadir'), findsNWidgets(2));
    expect(
        find.text(
            'NUSARTA tidak pernah meminta PIN, kata sandi, kode OTP, atau '
            'credential bank. Koneksi hanya dibuat melalui provider resmi '
            'dengan persetujuan (consent) dari kamu.'),
        findsOneWidget);
  });

  testWidgets('link accounts shows empty-catalog fallback', (tester) async {
    await tester.pumpWidget(wrapLinkAccounts(withCatalog: false));
    await tester.pump();
    expect(find.text('Katalog institusi belum tersedia.\nCoba lagi nanti.'),
        findsOneWidget);
  });

  testWidgets('catalog filter tabs isolate banks and e-wallets',
      (tester) async {
    await tester.pumpWidget(wrapLinkAccounts(withCatalog: true));
    await tester.pump();
    expect(find.text('SEMUA'), findsOneWidget);
    expect(find.text('BANK'), findsNWidgets(2)); // chip + section header
    expect(find.text('E-WALLET'), findsNWidgets(2)); // chip + section header
    expect(find.text('BCA'), findsOneWidget);
    expect(find.text('GoPay'), findsOneWidget);

    await tester.tap(find.text('E-WALLET').first);
    await tester.pumpAndSettle();
    expect(find.text('GoPay'), findsOneWidget);
    expect(find.text('BCA'), findsNothing);
    expect(find.text('BANK'), findsNWidgets(1));

    await tester.tap(find.text('BANK'));
    await tester.pumpAndSettle();
    expect(find.text('BCA'), findsOneWidget);
    expect(find.text('GoPay'), findsNothing);

    await tester.tap(find.text('SEMUA'));
    await tester.pumpAndSettle();
    expect(find.text('BCA'), findsOneWidget);
    expect(find.text('GoPay'), findsOneWidget);
  });

  testWidgets('link accounts never implies a live connection', (tester) async {
    await tester.pumpWidget(wrapLinkAccounts(withCatalog: true));
    await tester.pump();
    expect(
        find.textContaining('Belum ada akun yang terhubung'), findsOneWidget);
    expect(find.text('Terhubung'), findsNothing);
    expect(find.text('Lanjutkan ke Penyambungan'), findsNothing);
  });
}
