import '../../core/data/supabase_client.dart';
import '../models/account_connection.dart';

class AccountConnectionRepository {
  AccountConnectionRepository._();

  static const _table = 'account_connections';

  /// Lists the signed-in user's own connections (RLS-scoped server-side).
  static Future<List<AccountConnection>> listMine() async {
    final rows =
        await SupabaseConfig.client.from(_table).select().order('created_at');
    return rows.map((r) => AccountConnection.fromMap(r)).toList();
  }
}
