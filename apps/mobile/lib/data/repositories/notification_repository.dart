import '../../core/data/supabase_client.dart';
import '../models/notification.dart';

class NotificationRepository {
  NotificationRepository._();

  static const _table = 'notifications';

  static Future<List<AppNotification>> listMine() async {
    final rows = await SupabaseConfig.client
        .from(_table)
        .select()
        .eq('user_id', SupabaseConfig.client.auth.currentUser!.id)
        .order('created_at', ascending: false)
        .limit(50);
    return rows.map((r) => AppNotification.fromMap(r)).toList();
  }

  static Future<void> markRead(String id) async {
    await SupabaseConfig.client
        .from(_table)
        .update({'is_read': true})
        .eq('id', id)
        .eq('user_id', SupabaseConfig.client.auth.currentUser!.id);
  }

  static Future<void> markAllRead() async {
    await SupabaseConfig.client
        .from(_table)
        .update({'is_read': true})
        .eq('user_id', SupabaseConfig.client.auth.currentUser!.id)
        .eq('is_read', false);
  }

  static Future<String?> createForSelf({
    required AppNotificationType type,
    required String title,
    String? body,
    Map<String, dynamic> data = const {},
  }) async {
    if (!type.isV1Supported) return null;
    final rowId =
        await SupabaseConfig.client.rpc('create_user_notification', params: {
      'p_type': type.dbValue,
      'p_title': title,
      'p_body': body,
      'p_data': data,
    });
    return rowId as String?;
  }
}
