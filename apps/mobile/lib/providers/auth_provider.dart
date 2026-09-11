import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/data/supabase_client.dart';
import '../core/security/auto_lock_service.dart';
import '../core/utils/auth_error.dart';

final authStateProvider = StreamProvider<AuthState>((ref) =>
    SupabaseConfig.isInitialized
        ? SupabaseConfig.client.auth.onAuthStateChange
        : const Stream.empty());

final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateProvider);
  return SupabaseConfig.isInitialized
      ? SupabaseConfig.client.auth.currentUser
      : null;
});

final authControllerProvider =
    Provider<AuthController>((ref) => AuthController());

enum RegistrationResult { verificationRequired, authenticated }

class AuthController {
  AuthController({SupabaseClient? client}) : _client = client;
  final SupabaseClient? _client;

  SupabaseClient get client {
    if (_client != null) return _client;
    if (!SupabaseConfig.isInitialized) throw AuthConfigurationException();
    return SupabaseConfig.client;
  }

  // Log only operation, stage and HTTP status. No exception strings, identity,
  // credentials, response bodies or session data are ever logged here.
  void _diagnostic(String operation, String stage, [Object? error]) {
    if (!kDebugMode) return;
    final status =
        error is AuthException ? int.tryParse(error.statusCode ?? '') : null;
    debugPrint('AUTH: operation=$operation stage=$stage status=${status ?? 0}');
  }

  Future<void> _requireProfile(SupabaseClient backend, String userId) async {
    // The auth trigger creates the profile; retry briefly for REST visibility.
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final profile = await backend
            .from('profiles')
            .select('id')
            .eq('id', userId)
            .maybeSingle()
            .timeout(const Duration(seconds: 10));
        if (profile != null) return;
      } catch (_) {
        // Retry transient visibility or network failures.
      }
      if (attempt < 2) {
        await Future<void>.delayed(Duration(milliseconds: 250 * (attempt + 1)));
      }
    }
    _diagnostic('profile', 'unavailable');
    throw AuthProfileException();
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      final backend = client;
      _diagnostic('login', 'request');
      final response = await backend.auth
          .signInWithPassword(email: email.trim(), password: password)
          .timeout(const Duration(seconds: 30));
      _diagnostic('login', 'response');
      if (response.session == null || response.user == null) {
        throw const AuthException('Session unavailable');
      }
      await _requireProfile(backend, response.user!.id);
    } catch (error) {
      _diagnostic('login', 'failed', error);
      rethrow;
    }
  }

  Future<RegistrationResult> signUp(String email, String password,
      {String name = ''}) async {
    try {
      final backend = client;
      _diagnostic('signup', 'request');
      final response = await backend.auth
          .signUp(
            email: email.trim(),
            password: password,
            data:
                name.trim().isEmpty ? const {} : {'display_name': name.trim()},
          )
          .timeout(const Duration(seconds: 30));
      _diagnostic('signup', 'response');
      final user = response.user;
      if (user == null) throw const AuthException('User unavailable');
      if (user.identities?.isEmpty ?? false) {
        throw const AuthException('User already registered',
            code: 'user_already_exists');
      }
      if (response.session == null) {
        _diagnostic('signup', 'verification_required');
        return RegistrationResult.verificationRequired;
      }
      // The database trigger creates the profile. Never insert as anon or
      // replace the trigger with a privileged client-side operation.
      await _requireProfile(backend, user.id);
      return RegistrationResult.authenticated;
    } catch (error) {
      _diagnostic('signup', 'failed', error);
      rethrow;
    }
  }

  Future<void> signOut() async {
    await client.auth.signOut();
    AutoLockService.lock();
  }

  Future<void> resetPassword(String email) =>
      client.auth.resetPasswordForEmail(email.trim());
}
