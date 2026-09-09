import '../../core/data/supabase_client.dart';
import '../models/account.dart';

class AccountRepository {
  AccountRepository._();

  static const _table = 'accounts';

  static Future<List<Account>> listAll() async {
    final rows =
        await SupabaseConfig.client.from(_table).select().order('created_at');
    return rows.map((r) => Account.fromMap(r)).toList();
  }

  static Future<Account> create(Account account) async {
    final rows = await SupabaseConfig.client
        .from(_table)
        .insert(account.toMap()..['opening_balance'] = account.balance)
        .select()
        .single();
    return Account.fromMap(rows);
  }

  static Future<Account> createSimple({
    required String name,
    required AccountType type,
    double balance = 0,
  }) async {
    return createAccount(
      name: name,
      type: type,
      balance: balance,
    );
  }

  static Future<Account> createAccount({
    required String name,
    required AccountType type,
    double balance = 0,
    String? institutionId,
    String? lastFour,
    String? maskedAccountNumber,
    String? displayName,
    bool isPrimary = false,
  }) async {
    if (isPrimary) {
      await clearPrimary(SupabaseConfig.client.auth.currentUser!.id);
    }
    final account = Account(
      id: '',
      userId: SupabaseConfig.client.auth.currentUser!.id,
      name: name,
      type: type,
      balance: balance,
      institutionId: institutionId,
      lastFour: lastFour,
      maskedAccountNumber: maskedAccountNumber,
      displayName: displayName,
      isPrimary: isPrimary,
      connectionType: ConnectionType.manual,
      connectionStatus: ConnectionStatus.manual,
    );
    return create(account);
  }

  static Future<void> setPrimary(String id, {required bool isPrimary}) async {
    if (isPrimary) {
      await clearPrimary(SupabaseConfig.client.auth.currentUser!.id);
    }
    await SupabaseConfig.client
        .from(_table)
        .update({'is_primary': isPrimary}).eq('id', id);
  }

  static Future<void> clearPrimary(String userId) async {
    await SupabaseConfig.client
        .from(_table)
        .update({'is_primary': false}).eq('user_id', userId).eq('is_primary', true);
  }

  static Future<void> update(Account account) async {
    final map = account.toMap()..remove('user_id');
    await SupabaseConfig.client.from(_table).update(map).eq('id', account.id);
  }

  static Future<void> delete(String id) async {
    await SupabaseConfig.client.from(_table).delete().eq('id', id);
  }

  static Future<void> archive(String id, bool archived) async {
    await SupabaseConfig.client
        .from(_table)
        .update({'is_archived': archived}).eq('id', id);
  }
}
