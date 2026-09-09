import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/supabase_client.dart';
import '../security/secure_store.dart';

/// Outcome of an account deletion attempt.
enum DeleteAccountError {
  none,
  unauthenticated,
  confirmation,
  reauthenticationFailed,
  network,
  server,
}

class DeleteAccountResult {
  const DeleteAccountResult(this.error, {this.message});

  final DeleteAccountError error;
  final String? message;

  bool get ok => error == DeleteAccountError.none;
}

/// Server-side deletion boundary. The implementation only ever talks to the
/// authenticated API — no privileged credentials exist on the client.
/// The real gateway uses `public.delete_my_account` (SECURITY DEFINER) which
/// deletes only the authenticated caller (auth.uid()) server-side.
abstract class AccountDeletionGateway {
  bool get isSignedIn;
  String? get signedInUserEmail;

  /// Re-authenticates (password). Refreshes the access JWT so the server's
  /// re-authentication freshness check (iat within 5 minutes) passes.
  Future<void> reauthenticate({required String email, required String password});

  /// Invokes the server-authoritative deletion for the current account.
  /// Must not accept an arbitrary user id.
  Future<void> requestDeletion({required String confirmation});

  Future<void> signOut();
}

class SupabaseAccountDeletionGateway implements AccountDeletionGateway {
  SupabaseAccountDeletionGateway(this._client);

  final SupabaseClient _client;

  @override
  bool get isSignedIn => _client.auth.currentUser != null;

  @override
  String? get signedInUserEmail => _client.auth.currentUser?.email;

  @override
  Future<void> reauthenticate(
      {required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> requestDeletion({required String confirmation}) async {
    await _client.rpc('delete_my_account', params: {'p_confirm': confirmation});
  }

  @override
  Future<void> signOut() => _client.auth.signOut();
}

/// Orchestrates the deletion flow:
/// validate state → re-authenticate → server deletion → sign out →
/// wipe local sensitive state (PIN material, lockout/attempt state,
/// biometric preference, cached preferences). Runs on the CURRENT user only.
class AccountDeletionService {
  AccountDeletionService({
    required AccountDeletionGateway gateway,
    Future<void> Function()? onLocalStateCleared,
  })  : _gateway = gateway,
        _onLocalStateCleared = onLocalStateCleared ?? SecureStore.clear;

  final AccountDeletionGateway _gateway;
  final Future<void> Function() _onLocalStateCleared;

  bool get isSignedIn => _gateway.isSignedIn;
  String? get signedInUserEmail => _gateway.signedInUserEmail;

  Future<DeleteAccountResult> deleteAccount({
    required String email,
    required String password,
    required String confirmation,
  }) async {
    if (!_gateway.isSignedIn) {
      return const DeleteAccountResult(DeleteAccountError.unauthenticated);
    }
    if (confirmation.trim().toUpperCase() != 'HAPUS') {
      return const DeleteAccountResult(DeleteAccountError.confirmation);
    }

    try {
      await _gateway.reauthenticate(email: email, password: password);
    } catch (_) {
      return const DeleteAccountResult(
        DeleteAccountError.reauthenticationFailed,
        message: 'Reautentikasi gagal',
      );
    }

    try {
      await _gateway.requestDeletion(confirmation: confirmation);
    } catch (e) {
      return DeleteAccountResult(_mapServerError(e));
    }

    await _gateway.signOut();
    await _onLocalStateCleared();
    return const DeleteAccountResult(DeleteAccountError.none);
  }

  DeleteAccountError _mapServerError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('unauthenticated') || message.contains('nusa1')) {
      return DeleteAccountError.unauthenticated;
    }
    if (message.contains('re-authentication') || message.contains('nusa2')) {
      return DeleteAccountError.reauthenticationFailed;
    }
    if (message.contains('confirmation required') ||
        message.contains('nusa3')) {
      return DeleteAccountError.confirmation;
    }
    if (message.contains('network') ||
        message.contains('host lookup') ||
        message.contains('connection')) {
      return DeleteAccountError.network;
    }
    return DeleteAccountError.server;
  }
}

final accountDeletionServiceProvider = Provider<AccountDeletionService>((ref) {
  return AccountDeletionService(
    gateway: SupabaseAccountDeletionGateway(SupabaseConfig.client),
    onLocalStateCleared: SecureStore.clear,
  );
});