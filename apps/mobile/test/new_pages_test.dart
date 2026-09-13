import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nusarta/features/about/about_nusarta_page.dart';
import 'package:nusarta/features/fun/claim_free_balance_page.dart';
import 'package:nusarta/features/help/help_center_page.dart';
import 'package:nusarta/features/legal/privacy_page.dart';
import 'package:nusarta/features/legal/terms_page.dart';
import 'package:nusarta/features/version/version_page.dart';

void main() {
  Widget wrap(Widget child) => ProviderScope(
        child: MaterialApp(home: child),
      );

  group('Claim Saldo Gratis', () {
    testWidgets('shows pre-reveal then reveals the prank', (tester) async {
      await tester.pumpWidget(wrap(const ClaimFreeBalancePage()));
      expect(find.text('Saldo gratis untukmu!'), findsOneWidget);
      expect(find.text('Mengecek kelayakan akun (pura-pura)…'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Mana ada saldo gratis, tolol.'), findsOneWidget);
      expect(find.text('Klaim gacha GGL/Salim itu scam. Balik kerja.'),
          findsOneWidget);
      expect(find.text('Kembali ke NUSARTA'), findsOneWidget);
    });
  });

  group('Pusat Bantuan', () {
    testWidgets('renders FAQ sections and answer after expand', (tester) async {
      await tester.pumpWidget(wrap(const HelpCenterPage()));
      await tester.scrollUntilVisible(find.text('PENCATATAN'), 150);
      expect(find.text('MEMULAI DENGAN NUSARTA'), findsOneWidget);
      expect(find.text('PENCATATAN'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('KEAMANAN & PRIVASI'), 150);
      expect(find.text('KEAMANAN & PRIVASI'), findsOneWidget);
      await tester.scrollUntilVisible(
          find.text('Bagaimana cara menambah transaksi?'), -100);
      expect(find.text('Bagaimana cara menambah transaksi?'), findsOneWidget);

      await tester
          .ensureVisible(find.text('Bagaimana cara menambah transaksi?'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bagaimana cara menambah transaksi?'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Buka tab Beranda atau Transaksi'),
          findsOneWidget);
    });
  });

  group('Tentang NUSARTA', () {
    testWidgets('renders branding and facts', (tester) async {
      await tester.pumpWidget(wrap(const AboutNusartaPage()));
      expect(find.text('APA ITU NUSARTA'), findsOneWidget);
      expect(find.textContaining('Nusa + Arta'), findsOneWidget);
      expect(find.textContaining('bukan bank'), findsWidgets);
    });
  });

  group('Kebijakan Privasi', () {
    testWidgets('renders sections from the web policy', (tester) async {
      await tester.pumpWidget(wrap(const PrivacyPage()));
      expect(find.text('1. Pendahuluan'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('4. Keamanan data'), 150);
      expect(find.text('4. Keamanan data'), findsOneWidget);
      expect(find.textContaining('Row Level Security'), findsOneWidget);
    });
  });

  group('Syarat & Ketentuan', () {
    testWidgets('renders sections from the web terms', (tester) async {
      await tester.pumpWidget(wrap(const TermsPage()));
      expect(find.text('2. Layanan'), findsOneWidget);
      expect(find.textContaining('bukan layanan perbankan'), findsWidgets);
    });
  });

  group('Versi Aplikasi', () {
    testWidgets('renders without crashing (dynamic info optional)',
        (tester) async {
      await tester.pumpWidget(wrap(const VersionPage()));
      await tester.pump();
      expect(find.text('PEMBARUAN APLIKASI'), findsOneWidget);
      expect(find.text('Cek Sekarang'), findsOneWidget);
    });
  });
}
