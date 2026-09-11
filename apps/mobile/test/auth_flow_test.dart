import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nusarta/core/utils/auth_error.dart';
import 'package:nusarta/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const user = {
  'id': '11111111-1111-1111-1111-111111111111',
  'aud': 'authenticated',
  'email': 'test@example.com',
  'created_at': '2026-01-01T00:00:00Z',
  'app_metadata': <String, dynamic>{},
  'user_metadata': <String, dynamic>{},
  'identities': [
    {
      'id': 'identity',
      'user_id': '11111111-1111-1111-1111-111111111111',
      'provider': 'email'
    }
  ],
};
Map<String, dynamic> session() => {
      'access_token': '${base64Url.encode(utf8.encode(jsonEncode({
            'alg': 'HS256'
          })))}.${base64Url.encode(utf8.encode(jsonEncode({
            'sub': user['id'],
            'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600
          })))}.test-signature',
      'refresh_token': 'test-only-refresh',
      'token_type': 'bearer',
      'expires_in': 3600,
      'user': user,
    };

class MemoryPkceStorage extends GotrueAsyncStorage {
  final values = <String, String>{};
  @override
  Future<String?> getItem({required String key}) async => values[key];
  @override
  Future<void> setItem({required String key, required String value}) async {
    values[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    values.remove(key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SupabaseClient backend(Future<http.Response> Function(http.Request) handler) {
    final client = SupabaseClient(
        'https://example.supabase.co', 'test-public-key',
        httpClient: MockClient(handler),
        authOptions: AuthClientOptions(
            autoRefreshToken: false, pkceAsyncStorage: MemoryPkceStorage()));
    addTearDown(client.dispose);
    return client;
  }

  test('signup with session obtains the trigger-created profile', () async {
    final paths = <String>[];
    final controller = AuthController(client: backend((request) async {
      paths.add(request.url.path);
      if (request.url.path.endsWith('/signup')) {
        expect(jsonDecode(request.body)['data']['display_name'], 'Nama');
        return http.Response(jsonEncode(session()), 200);
      }
      expect(request.url.queryParameters['id'], 'eq.${user['id']}');
      return http.Response(
          jsonEncode([
            {'id': user['id']}
          ]),
          200,
          request: request,
          headers: {'content-type': 'application/json'});
    }));
    expect(
        await controller.signUp(' test@example.com ', 'test-password',
            name: ' Nama '),
        RegistrationResult.authenticated);
    expect(paths, ['/auth/v1/signup', '/rest/v1/profiles']);
  });

  test('verification-required signup does not read profile without session',
      () async {
    var calls = 0;
    final controller = AuthController(client: backend((request) async {
      calls++;
      return http.Response(jsonEncode(user), 200);
    }));
    expect(await controller.signUp('test@example.com', 'test-password'),
        RegistrationResult.verificationRequired);
    expect(calls, 1);
  });

  test('obfuscated duplicate signup is handled safely', () async {
    final controller = AuthController(
        client: backend((_) async =>
            http.Response(jsonEncode({...user, 'identities': []}), 200)));
    await expectLater(
        controller.signUp('test@example.com', 'test-password'),
        throwsA(isA<AuthException>().having(authErrorMessage, 'safe message',
            'Email ini sudah terdaftar. Silakan masuk.')));
  });

  for (final scenario in [
    ('user_already_exists', 422, 'Email ini sudah terdaftar. Silakan masuk.'),
    (
      'over_email_send_rate_limit',
      429,
      'Terlalu banyak percobaan. Tunggu beberapa saat lalu coba lagi.'
    ),
    ('weak_password', 422, 'Kata sandi belum memenuhi persyaratan keamanan.'),
    (
      'email_address_invalid',
      422,
      'Alamat email tidak valid. Periksa kembali email Anda.'
    ),
    (
      'unexpected_failure',
      503,
      'Layanan akun sedang mengalami gangguan. Silakan coba lagi nanti.'
    ),
  ]) {
    test('signup ${scenario.$1}', () async {
      final controller = AuthController(
          client: backend((_) async => http.Response(
              jsonEncode(
                  {'error_code': scenario.$1, 'msg': 'private backend detail'}),
              scenario.$2)));
      await expectLater(
          controller.signUp('test@example.com', 'test-password'),
          throwsA(isA<AuthException>()
              .having(authErrorMessage, 'message', scenario.$3)));
    });
  }

  for (final signup in [true, false]) {
    test('${signup ? 'signup' : 'login'} network failure', () async {
      final controller = AuthController(
          client: backend((_) async =>
              throw const SocketException('private network detail')));
      await expectLater(
          signup
              ? controller.signUp('test@example.com', 'test-password')
              : controller.signInWithEmail('test@example.com', 'test-password'),
          throwsA(isA<Object>().having(authErrorMessage, 'safe network message',
              'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.')));
    });
    test('${signup ? 'signup' : 'login'} missing profile', () async {
      final controller = AuthController(
          client: backend((request) async => http.Response(
              jsonEncode(
                  request.url.path.contains('/auth/') ? session() : null),
              200,
              request: request,
              headers: {'content-type': 'application/json'})));
      await expectLater(
          signup
              ? controller.signUp('test@example.com', 'test-password')
              : controller.signInWithEmail('test@example.com', 'test-password'),
          throwsA(isA<AuthProfileException>()));
    });
  }
  test('login success requires session and profile', () async {
    final controller = AuthController(
        client: backend((request) async => http.Response(
            jsonEncode(request.url.path.contains('/auth/')
                ? session()
                : [
                    {'id': user['id']}
                  ]),
            200,
            request: request,
            headers: {'content-type': 'application/json'})));
    await controller.signInWithEmail('test@example.com', 'test-password');
    expect(controller.client.auth.currentSession, isNotNull);
  });
  for (final code in ['invalid_credentials', 'email_not_confirmed']) {
    test('login $code', () async {
      final controller = AuthController(
          client: backend((_) async => http.Response(
              jsonEncode({'error_code': code, 'msg': 'private detail'}), 400)));
      await expectLater(
          controller.signInWithEmail('test@example.com', 'test-password'),
          throwsA(isA<AuthException>().having((e) => e.code, 'code', code)));
    });
  }
  test('missing public configuration has a safe actionable error', () async {
    await expectLater(
        AuthController().signUp('test@example.com', 'test-password'),
        throwsA(isA<AuthConfigurationException>()));
  });
  test('unknown error never leaks backend text', () {
    expect(authErrorMessage(Exception('private backend detail')),
        'Autentikasi belum berhasil. Silakan coba lagi.');
  });
  test('401 client configuration failure is distinct from invalid credentials',
      () {
    expect(
        authErrorMessage(
            const AuthException('unauthorized', statusCode: '401')),
        'Konfigurasi layanan akun tidak cocok. Perbarui konfigurasi aplikasi.');
    expect(
        authErrorMessage(const AuthException('invalid login credentials',
            code: 'invalid_credentials', statusCode: '400')),
        'Email atau kata sandi salah.');
  });
}
