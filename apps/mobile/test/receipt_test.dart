import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nusarta/data/models/transfer_record.dart';
import 'package:nusarta/features/connections/financial_provider_adapter.dart';
import 'package:nusarta/features/transfers/transfer_receipt_page.dart';

TransferRecord recordWith(TransferStepStatus status) => TransferRecord(
      reference: 'ref-abc-123',
      provider: 'open_finance',
      sourceAccountName: 'BCA',
      sourceMasked: '•••• 4821',
      sourceInstitutionName: 'BCA',
      recipientInstitutionName: 'GoPay',
      recipientInstitutionCode: 'GOPAY',
      recipientMasked: '•••• 8221',
      recipientName: 'ALICE',
      amount: 100000,
      fee: 2500,
      status: status,
      occurredAt: DateTime(2026, 9, 13, 10, 30),
    );

Widget wrap(TransferRecord record) => MaterialApp(
      locale: const Locale('id'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('id')],
      home: ReceiptDetailPage(record: record),
    );

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });
  testWidgets('success receipt renders NUSARTA branding and verified amounts',
      (tester) async {
    await tester.pumpWidget(wrap(recordWith(TransferStepStatus.success)));
    await tester.pumpAndSettle();
    expect(find.text('Struk NUSARTA'), findsOneWidget);
    expect(find.text('Keuanganmu, Dalam Kendalimu.'), findsOneWidget);
    expect(find.text('Transfer Berhasil'), findsWidgets);
    expect(find.text('Rp 100.000'), findsOneWidget);
    expect(find.text('Rp 2.500'), findsOneWidget);
    expect(find.text('ref-abc-123'), findsOneWidget);
    expect(find.textContaining('penyedia jasa resmi'), findsOneWidget);
  });

  testWidgets('failed receipt never claims success', (tester) async {
    await tester.pumpWidget(wrap(recordWith(TransferStepStatus.failed)));
    await tester.pumpAndSettle();
    expect(find.text('Transfer tidak berhasil'), findsWidgets);
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
  });

  testWidgets('processing and cancelled states render honestly',
      (tester) async {
    await tester.pumpWidget(wrap(recordWith(TransferStepStatus.processing)));
    await tester.pumpAndSettle();
    expect(find.text('Transfer sedang diproses'), findsWidgets);

    await tester.pumpWidget(wrap(recordWith(TransferStepStatus.cancelled)));
    await tester.pumpAndSettle();
    expect(find.text('Otorisasi dibatalkan'), findsWidgets);
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
  });

  testWidgets('bagikan copies the receipt summary', (tester) async {
    String? captured;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('id'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('id')],
      home: ReceiptDetailPage(
        record: recordWith(TransferStepStatus.success),
        onShare: (text) async => captured = text,
      ),
    ));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Bagikan Struk'), 120,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Bagikan Struk'));
    await tester.pumpAndSettle();
    expect(captured, isNotNull);
    expect(captured, contains('NUSARTA'));
    expect(captured, contains('ref-abc-123'));
    expect(captured, contains('Transfer Berhasil'));
  });
}
