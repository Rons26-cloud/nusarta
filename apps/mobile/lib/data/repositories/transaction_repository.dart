import '../../core/data/supabase_client.dart';
import '../models/transaction.dart';

class TransactionRepository {
  TransactionRepository._();

  static const _table = 'transactions';

  static Future<List<Transaction>> list({
    TransactionKind? kind,
    String? accountId,
    String? categoryId,
    DateTime? from,
    DateTime? to,
    String? search,
    int limit = 200,
  }) async {
    var query = SupabaseConfig.client.from(_table).select();

    if (kind != null) query = query.eq('kind', kind.name);
    if (accountId != null) query = query.eq('account_id', accountId);
    if (categoryId != null) query = query.eq('category_id', categoryId);
    if (from != null) query = query.gte('occurred_at', from.toIso8601String());
    if (to != null) query = query.lte('occurred_at', to.toIso8601String());
    if (search != null && search.isNotEmpty) {
      query = query.ilike('note', '%$search%');
    }

    final rows =
        await query.order('occurred_at', ascending: false).limit(limit);
    return rows.map((r) => Transaction.fromMap(r)).toList();
  }

  static Future<Transaction> create(Transaction t) async {
    final rows = await SupabaseConfig.client
        .from(_table)
        .insert(t.toMap())
        .select()
        .single();
    return Transaction.fromMap(rows);
  }

  static Future<void> update(Transaction t) async {
    final map = t.toMap()..remove('user_id');
    await SupabaseConfig.client.from(_table).update(map).eq('id', t.id);
  }

  static Future<void> delete(String id) async {
    await SupabaseConfig.client.from(_table).delete().eq('id', id);
  }

  // Internal transfer: atomic RPC; the database updates both balances.
  static Future<void> createTransfer(InternalTransfer transfer) async {
    final params = <String, dynamic>{
      'from_account_id': transfer.fromAccountId,
      'to_account_id': transfer.toAccountId,
      'amount': transfer.amount,
    };
    if (transfer.note != null) params['note'] = transfer.note;
    await SupabaseConfig.client.rpc('create_internal_transfer', params: params);
  }
}
