import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nusarta/core/router/app_router.dart' as production;
import 'package:nusarta/features/auth/reset_password_page.dart';
import 'package:nusarta/providers/password_recovery_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_flow_test.dart' as fixtures;

class FakeRecovery extends PasswordRecoveryController {
  String? requestedEmail;
  int verifications = 0;
  @override
  Future<void> verify(String email, String code) async {
    verifications++;
  }

  int updates = 0;
  int finishes = 0;
  Object? failure;
  @override
  Future<void> request(String email) async {
    requestedEmail = email;
  }

  @override
  Future<void> updatePassword(String password) async {
    if (failure != null) throw failure!;
    updates++;
  }

  @override
  Future<void> finish() async {
    finishes++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'forgot opens with both Login fields empty without validating Login',
      (tester) async {
    production.router.go('/login');
    await tester.pumpWidget(ProviderScope(
        child: MaterialApp.router(routerConfig: production.router)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Lupa kata sandi?'));
    await tester.tap(find.text('Lupa kata sandi?'));
    await tester.pumpAndSettle();
    expect(
        production
            .router.routerDelegate.currentConfiguration.last.matchedLocation,
        '/forgot-password');
    production.router.pop();
    await tester.pumpAndSettle();
    expect(find.text('Masukkan email valid'), findsNothing);
    expect(find.text('Minimal 6 karakter'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('unverified reset route returns to forgot password',
      (tester) async {
    production.router.go('/reset-password');
    await tester.pumpWidget(ProviderScope(
        child: MaterialApp.router(routerConfig: production.router)));
    await tester.pumpAndSettle();
    expect(
        production
            .router.routerDelegate.currentConfiguration.last.matchedLocation,
        '/forgot-password');
    expect(find.byType(ResetPasswordPage), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  for (final code in [
    'otp_expired',
    'over_request_rate_limit',
    'weak_password'
  ]) {
    test('recovery propagates $code without creating verified session',
        () async {
      final backend = SupabaseClient(
          'https://example.supabase.co', 'test-public',
          authOptions: AuthClientOptions(
              autoRefreshToken: false,
              pkceAsyncStorage: fixtures.MemoryPkceStorage()),
          httpClient: MockClient((request) async => http.Response(
              jsonEncode({'error_code': code, 'msg': 'private backend detail'}),
              code == 'over_request_rate_limit' ? 429 : 422)));
      addTearDown(backend.dispose);
      final recovery = PasswordRecoveryController(client: backend);
      await expectLater(recovery.verify('test@example.com', '000000'),
          throwsA(isA<AuthException>().having((e) => e.code, 'code', code)));
      expect(recovery.verified, isFalse);
    });
  }

  testWidgets('recovery OTP automatically opens production Reset Password page',
      (tester) async {
    final recovery = FakeRecovery();
    final router = GoRouter(
      initialLocation: '/forgot-password',
      routes: production.router.configuration.routes,
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [passwordRecoveryProvider.overrideWithValue(recovery)],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'test@example.com');
    await tester.ensureVisible(find.text('Kirim Kode'));
    await tester.tap(find.text('Kirim Kode'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '000000');
    await tester.pump();
    await tester.ensureVisible(find.text('Verifikasi'));
    await tester.tap(find.text('Verifikasi'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(recovery.verifications, 1);
    expect(find.byType(ResetPasswordPage), findsOneWidget);
    expect(router.routerDelegate.currentConfiguration.last.matchedLocation,
        '/reset-password');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'Login opens editable forgot email and request opens recovery OTP',
      (tester) async {
    final recovery = FakeRecovery();
    production.router.go('/login');
    await tester.pumpWidget(ProviderScope(
      overrides: [passwordRecoveryProvider.overrideWithValue(recovery)],
      child: MaterialApp.router(routerConfig: production.router),
    ));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextFormField).first, 'first@example.com');
    await tester.ensureVisible(find.text('Lupa kata sandi?'));
    await tester.tap(find.text('Lupa kata sandi?'));
    await tester.pumpAndSettle();
    expect(
        production
            .router.routerDelegate.currentConfiguration.last.matchedLocation,
        '/forgot-password');
    expect(find.text('first@example.com'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'invalid');
    await tester.ensureVisible(find.text('Kirim Kode'));
    await tester.tap(find.text('Kirim Kode'));
    await tester.pumpAndSettle();
    expect(recovery.requestedEmail, isNull);
    expect(find.text('Masukkan email valid'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'edited@example.com');
    await tester.ensureVisible(find.text('Kirim Kode'));
    await tester.tap(find.text('Kirim Kode'));
    await tester.pumpAndSettle();
    expect(recovery.requestedEmail, 'edited@example.com');
    expect(
        production
            .router.routerDelegate.currentConfiguration.last.matchedLocation,
        '/recovery-otp');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'reset validation, obscuring, backend error and success Login route',
      (tester) async {
    final recovery = FakeRecovery();
    final router = GoRouter(initialLocation: '/reset-password', routes: [
      GoRoute(
          path: '/reset-password',
          builder: (_, __) => const ResetPasswordPage()),
      GoRoute(
          path: '/login',
          builder: (_, __) => const Scaffold(body: Text('Login destination'))),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [passwordRecoveryProvider.overrideWithValue(recovery)],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    expect(tester.widget<TextField>(find.byType(TextField).first).obscureText,
        isTrue);
    await tester.enterText(fields.first, 'short');
    await tester.enterText(fields.last, 'different');
    await tester.tap(find.text('Simpan Kata Sandi'));
    await tester.pumpAndSettle();
    expect(find.text('Minimal 6 karakter'), findsOneWidget);
    expect(find.text('Kata sandi tidak sama'), findsOneWidget);
    expect(recovery.updates, 0);
    await tester.enterText(fields.first, 'test-only-password');
    await tester.enterText(fields.last, 'test-only-password');
    recovery.failure = const AuthException('private', code: 'weak_password');
    await tester.tap(find.text('Simpan Kata Sandi'));
    await tester.pumpAndSettle();
    expect(find.text('Kata sandi belum memenuhi persyaratan keamanan.'),
        findsOneWidget);
    recovery.failure = null;
    await tester.tap(find.text('Simpan Kata Sandi'));
    await tester.pumpAndSettle();
    expect(recovery.updates, 1);
    expect(recovery.finishes, 1);
    expect(find.text('Login destination'), findsOneWidget);
    expect(
        find.text(
            'Kata sandi berhasil diperbarui. Silakan masuk dengan kata sandi baru.'),
        findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  test(
      'recovery uses recover, recovery verify, Auth user update, local signout only',
      () async {
    final paths = <String>[];
    final backend = SupabaseClient('https://example.supabase.co', 'test-public',
        authOptions: AuthClientOptions(
            autoRefreshToken: false,
            pkceAsyncStorage: fixtures.MemoryPkceStorage()),
        httpClient: MockClient((request) async {
      paths.add(request.url.path);
      final body = request.body.isEmpty ? {} : jsonDecode(request.body);
      if (request.url.path.endsWith('/recover')) {
        expect(body['email'], 'test@example.com');
        return http.Response('{}', 200);
      }
      if (request.url.path.endsWith('/verify')) {
        expect(body['type'], 'recovery');
        return http.Response(jsonEncode(fixtures.session()), 200);
      }
      if (request.url.path.endsWith('/user')) {
        expect(request.method, 'PUT');
        expect(body['password'], 'test-only-password');
        return http.Response(jsonEncode(fixtures.user), 200);
      }
      expect(request.url.queryParameters['scope'], 'local');
      return http.Response('{}', 200);
    }));
    addTearDown(backend.dispose);
    final recovery = PasswordRecoveryController(client: backend);
    await expectLater(recovery.updatePassword('test-only-password'),
        throwsA(isA<AuthException>()));
    await recovery.request(' test@example.com ');
    await recovery.verify('test@example.com', '000000');
    expect(recovery.verified, isTrue);
    await recovery.updatePassword('test-only-password');
    await recovery.finish();
    expect(recovery.verified, isFalse);
    expect(backend.auth.currentSession, isNull);
    expect(paths, [
      '/auth/v1/recover',
      '/auth/v1/verify',
      '/auth/v1/user',
      '/auth/v1/logout'
    ]);
  });
}
