import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/data/supabase_client.dart';
import '../core/utils/auth_error.dart';

final passwordRecoveryProvider = Provider<PasswordRecoveryController>(
  (ref) => PasswordRecoveryController(),
);

/// Only password recovery owns this state; signup and PIN recovery never set it.
class PasswordRecoveryController {
  PasswordRecoveryController({SupabaseClient? client}) : _client = client;
  final SupabaseClient? _client;
  static String? _verifiedToken;
  SupabaseClient get client {
    if (_client != null) return _client;
    if (!SupabaseConfig.isInitialized) throw AuthConfigurationException();
    return SupabaseConfig.client;
  }

  static bool get active =>
      SupabaseConfig.isInitialized &&
      _verifiedToken != null &&
      _verifiedToken == SupabaseConfig.client.auth.currentSession?.refreshToken;

  bool get verified =>
      _verifiedToken != null &&
      _verifiedToken == client.auth.currentSession?.refreshToken;

  Future<void> request(String email) async {
    _verifiedToken = null;
    try {
      await client.auth.resetPasswordForEmail(email.trim());
    } on AuthException catch (e) {
      if (e.code != 'user_not_found') rethrow;
    }
  }

  Future<void> verify(String email, String code) async {
    _verifiedToken = null;
    final response = await client.auth.verifyOTP(
      email: email.trim(),
      token: code,
      type: OtpType.recovery,
    );
    if (response.session == null || response.user == null) {
      throw const AuthException('Recovery session missing',
          code: 'session_missing');
    }
    _verifiedToken = response.session!.refreshToken;
  }

  Future<void> updatePassword(String password) async {
    if (!verified) {
      throw const AuthException('Recovery session missing',
          code: 'session_missing');
    }
    await client.auth.updateUser(UserAttributes(password: password));
    // Keep the route gated until local sign-out has completed.
    _verifiedToken = client.auth.currentSession?.refreshToken;
  }

  Future<void> finish() async {
    await client.auth.signOut(scope: SignOutScope.local);
    _verifiedToken = null;
  }
}

String recoveryError(Object error) {
  if (error is AuthException) {
    if (error.code == 'session_missing' ||
        error.code == 'session_not_found' ||
        error.code == 'refresh_token_not_found' ||
        error.statusCode == '401') {
      return 'Sesi pemulihan tidak valid. Minta kode baru melalui Lupa kata sandi.';
    }
    if (error.code == 'same_password') {
      return 'Gunakan kata sandi baru yang berbeda dari kata sandi sebelumnya.';
    }
  }
  return authErrorMessage(error,
      fallback: 'Pemulihan kata sandi belum berhasil. Silakan coba lagi.');
}
