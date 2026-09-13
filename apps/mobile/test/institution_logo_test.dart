import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nusarta/core/branding/institution_logo_registry.dart';
import 'package:nusarta/core/theme/app_colors.dart';
import 'package:nusarta/core/theme/app_theme.dart';
import 'package:nusarta/data/models/account_connection.dart';
import 'package:nusarta/data/models/institution.dart';
import 'package:nusarta/features/connections/link_accounts_page.dart';
import 'package:nusarta/providers/finance_providers.dart';
import 'package:nusarta/widgets/institution_logo.dart';

const coveredCodes = [
  'bca',
  'mandiri',
  'seabank',
  'hsbc',
  'maybank',
  'gopay',
  'ovo',
  'linkaja',
  'doku',
  'astrapay'
];

class _MissingLogoBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) {
    if (key == InstitutionLogoRegistry.assetPathFor('bca')) {
      return Future.error(StateError('Missing test asset'));
    }
    return rootBundle.load(key);
  }
}

List<Institution> seedCatalog() {
  final seed = File('../../supabase/migrations/010_institutions_seed.sql')
      .readAsStringSync();
  return RegExp(r"\('([^']+)'\s*,\s*'([^']+)'\s*,\s*'(bank|ewallet)'")
      .allMatches(seed)
      .map((m) => Institution(
              id: 'test-${m[1]}',
              code: m[1]!,
              name: m[2]!,
              institutionType: m[3]!,
              providerSupport: const {
                'integration_status': 'coming_soon',
                'link_supported': false,
                'sync_supported': false,
                'transfer_supported': false
              }))
      .toList();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => AppColors.setBrightness(Brightness.light));

  test('registered codes exist in actual seed and assets decode', () async {
    final catalog = seedCatalog();
    expect(catalog, hasLength(24));
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    for (final code in coveredCodes) {
      expect(catalog.any((i) => i.code == code), isTrue);
      final path = InstitutionLogoRegistry.assetPathFor(code)!;
      expect(manifest.listAssets(), contains(path));
      final data = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
      final frame = await codec.getNextFrame();
      expect(frame.image.width, greaterThan(0));
      expect(frame.image.height, greaterThan(0));
      frame.image.dispose();
      codec.dispose();
    }
    expect(InstitutionLogoRegistry.assetPathFor(' BcA '),
        InstitutionLogoRegistry.assetPathFor('bca'));
    expect(InstitutionLogoRegistry.assetPathFor('unknown'), isNull);
    expect(InstitutionLogoRegistry.missing(['bca', 'bni']), ['BNI']);
  });

  testWidgets('unregistered institution keeps honest neutral fallback',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: InstitutionLogo(code: 'bni', name: 'BNI'))));
    expect(find.text('B'), findsOneWidget);
    expect(find.byTooltip('Logo resmi belum tersedia'), findsOneWidget);
  });

  testWidgets(
      'missing registered file falls back without an uncaught exception',
      (tester) async {
    await tester.pumpWidget(DefaultAssetBundle(
        bundle: _MissingLogoBundle(),
        child: const MaterialApp(
            home: Scaffold(body: InstitutionLogo(code: 'bca', name: 'BCA')))));
    await tester.pumpAndSettle();
    expect(find.text('B'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missingMarker can be hidden', (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: InstitutionLogo(
                code: 'unknown', name: 'Unknown', missingMarker: false))));
    expect(find.byTooltip('Logo resmi belum tersedia'), findsNothing);
    expect(find.text('U'), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    for (final width in [360.0, 375.0, 390.0, 412.0, 430.0]) {
      testWidgets(
          'catalog logos preserve status at $width in ${brightness.name}',
          (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 900);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        AppColors.setBrightness(brightness);
        final catalog = seedCatalog();
        await tester.pumpWidget(ProviderScope(
            overrides: [
              institutionsProvider.overrideWith((ref) async => catalog),
              accountConnectionsProvider
                  .overrideWith((ref) async => const <AccountConnection>[]),
            ],
            child: MaterialApp(
                theme: brightness == Brightness.dark
                    ? buildDarkTheme()
                    : buildLightTheme(),
                home: const LinkAccountsPage())));
        await tester.pumpAndSettle();
        for (final institution in catalog) {
          await tester.enterText(find.byType(TextField), institution.code);
          await tester.pumpAndSettle();
          expect(find.text(institution.name), findsOneWidget);
          expect(find.text('Segera Hadir'), findsWidgets);
          expect(find.text('Terhubung'), findsNothing);
          expect(
              institution.linkSupported ||
                  institution.syncSupported ||
                  institution.transferSupported,
              isFalse);
          final logos =
              tester.widgetList<InstitutionLogo>(find.byType(InstitutionLogo));
          expect(logos.any((logo) => logo.code == institution.code), isTrue);
          for (final image in tester.widgetList<Image>(find.byType(Image))) {
            expect(image.fit, BoxFit.contain);
            expect(image.color, isNull);
          }
          expect(tester.takeException(), isNull);
        }
        await tester.enterText(find.byType(TextField), 'bca');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Bank Central Asia (BCA)'));
        await tester.pumpAndSettle();
        expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
            isNull);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
