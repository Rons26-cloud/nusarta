import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/data/supabase_client.dart';

/// Session state (null = signed out).
final authStateProvider = StreamProvider<AuthState>(
  (ref) => SupabaseConfig.client.auth.onAuthStateChange,
);

final currentUserProvider = Provider<User?>(
  (ref) => SupabaseConfig.client.auth.currentUser,
);

/// Registration + login/logout.
final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController();
});

class AuthController {
  AuthController();

  Future<void> signInWithEmail(String email, String password) async {
    await SupabaseConfig.client.auth
        .signInWithPassword(email: email, password: password);
  }

  Future<void> signUp(String email, String password, {String name = ''}) async {
    await SupabaseConfig.client.auth.signUp(
      email: email,
      password: password,
      data: name.trim().isEmpty ? const {} : {'display_name': name.trim()},
    );
  }

  Future<void> signOut() async {
    await SupabaseConfig.client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await SupabaseConfig.client.auth.resetPasswordForEmail(email);
  }
}
