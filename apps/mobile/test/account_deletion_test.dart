import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nusarta/core/services/account_deletion_service.dart';
import 'package:nusarta/features/profile/delete_account_page.dart';

void main() {
  testWidgets('delete account screen opens and shows initial step',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountDeletionServiceProvider.overrideWithValue(
            AccountDeletionService(
                gateway: _MockGateway(), onLocalStateCleared: () async {}),
          ),
        ],
        child: MaterialApp(
          home: const DeleteAccountPage(),
        ),
      ),
    );

    expect(find.text('Hapus akun NUSARTA?'), findsOneWidget);
    expect(find.text('Yang akan dihapus permanen:'), findsOneWidget);
    expect(find.text('Lanjut'), findsOneWidget);
  });

  testWidgets('password field validation - button disabled when empty',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountDeletionServiceProvider.overrideWithValue(
            AccountDeletionService(
                gateway: _MockGateway(), onLocalStateCleared: () async {}),
          ),
        ],
        child: MaterialApp(
          home: const DeleteAccountPage(),
        ),
      ),
    );

    final button = find.widgetWithText(FilledButton, 'Lanjut');
    expect(tester.widget<FilledButton>(button).enabled, isFalse);
  });

  testWidgets('password field enables continue button when filled',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountDeletionServiceProvider.overrideWithValue(
            AccountDeletionService(
              gateway: _MockGateway(),
              onLocalStateCleared: () async {},
            ),
          ),
        ],
        child: MaterialApp(
          home: const DeleteAccountPage(),
        ),
      ),
    );

    await tester.enterText(
        find.ancestor(
            of: find.text('Kata sandi'), matching: find.byType(TextField)),
        'password123');
    await tester.pump();

    final button = find.widgetWithText(FilledButton, 'Lanjut');
    expect(tester.widget<FilledButton>(button).enabled, isTrue);
  });

  testWidgets('tapping continue moves to confirmation step',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountDeletionServiceProvider.overrideWithValue(
            AccountDeletionService(
              gateway: _MockGateway(),
              onLocalStateCleared: () async {},
            ),
          ),
        ],
        child: MaterialApp(
          home: const DeleteAccountPage(),
        ),
      ),
    );

    await tester.enterText(
        find.ancestor(
            of: find.text('Kata sandi'), matching: find.byType(TextField)),
        'password123');
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Lanjut'));
    await tester.pumpAndSettle();

    expect(find.text('Hapus akun secara permanen?'), findsOneWidget);
    expect(find.text('Ketik HAPUS untuk konfirmasi terakhir.'), findsOneWidget);
  });

  testWidgets('confirmation step requires HAPUS text',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountDeletionServiceProvider.overrideWithValue(
            AccountDeletionService(
              gateway: _MockGateway(),
              onLocalStateCleared: () async {},
            ),
          ),
        ],
        child: MaterialApp(
          home: const DeleteAccountPage(),
        ),
      ),
    );

    // Move to confirmation step
    await tester.enterText(
        find.ancestor(
            of: find.text('Kata sandi'), matching: find.byType(TextField)),
        'password123');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Lanjut'));
    await tester.pumpAndSettle();

    // Try wrong confirmation
    await tester.enterText(
        find.ancestor(
            of: find.text('Ketik: HAPUS'), matching: find.byType(TextField)),
        'SALAH');
    await tester.pump();

    final deleteButton = find.widgetWithText(FilledButton, 'Hapus Akun');
    expect(tester.widget<FilledButton>(deleteButton).enabled, isFalse);

    // Try correct confirmation
    await tester.enterText(
        find.ancestor(
            of: find.text('Ketik: HAPUS'), matching: find.byType(TextField)),
        'HAPUS');
    await tester.pump();

    expect(tester.widget<FilledButton>(deleteButton).enabled, isTrue);
  });

  testWidgets('cancel button returns to verification step',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountDeletionServiceProvider.overrideWithValue(
            AccountDeletionService(
              gateway: _MockGateway(),
              onLocalStateCleared: () async {},
            ),
          ),
        ],
        child: MaterialApp(
          home: const DeleteAccountPage(),
        ),
      ),
    );

    // Move to confirmation step
    await tester.enterText(
        find.ancestor(
            of: find.text('Kata sandi'), matching: find.byType(TextField)),
        'password123');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Lanjut'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Batal'));
    await tester.pumpAndSettle();

    expect(find.text('Hapus akun NUSARTA?'), findsOneWidget);
  });

  testWidgets('unauthenticated deletion shows error',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountDeletionServiceProvider.overrideWithValue(
            AccountDeletionService(
              gateway: _MockUnauthenticatedGateway(),
              onLocalStateCleared: () async {},
            ),
          ),
        ],
        child: MaterialApp(
          home: const DeleteAccountPage(),
        ),
      ),
    );

    await tester.enterText(
        find.ancestor(
            of: find.text('Kata sandi'), matching: find.byType(TextField)),
        'password123');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Lanjut'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.ancestor(
            of: find.text('Ketik: HAPUS'), matching: find.byType(TextField)),
        'HAPUS');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Hapus Akun'));
    await tester.pumpAndSettle();

    expect(
        find.text('Sesi kamu telah berakhir. Masuk kembali untuk melanjutkan.'),
        findsOneWidget);
  });
}

class _MockGateway implements AccountDeletionGateway {
  @override
  bool get isSignedIn => true;

  @override
  String? get signedInUserEmail => 'test@example.com';

  @override
  Future<void> reauthenticate(
      {required String email, required String password}) async {
    // Mock successful reauthentication
  }

  @override
  Future<void> requestDeletion({required String confirmation}) async {
    // Mock successful deletion
  }

  @override
  Future<void> signOut() async {
    // Mock signout
  }
}

class _MockUnauthenticatedGateway implements AccountDeletionGateway {
  @override
  bool get isSignedIn => false;

  @override
  // Email cached by the screen before the session expired.
  String? get signedInUserEmail => 'test@example.com';

  @override
  Future<void> reauthenticate(
      {required String email, required String password}) async {
    throw Exception('Unauthenticated');
  }

  @override
  Future<void> requestDeletion({required String confirmation}) async {
    throw Exception('Unauthenticated');
  }

  @override
  Future<void> signOut() async {
    // Mock signout
  }
}
