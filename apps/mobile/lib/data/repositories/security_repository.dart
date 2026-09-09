import '../../core/data/supabase_client.dart';
import '../models/security_event.dart';

class SecurityRepository {
  SecurityRepository._();

  static const _table = 'security_events';

  static Future<List<SecurityEvent>> listMine() async {
    final rows = await SupabaseConfig.client
        .from(_table)
        .select()
        .eq('user_id', SupabaseConfig.client.auth.currentUser!.id)
        .order('created_at', ascending: false)
        .limit(12);
    return rows.map((r) => SecurityEvent.fromMap(r)).toList();
  }
}