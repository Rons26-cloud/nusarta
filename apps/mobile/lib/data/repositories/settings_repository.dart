import '../../core/data/supabase_client.dart';

class SettingsRepository {
  SettingsRepository._();

  static const _table = 'app_settings';

  static Future<Map<String, dynamic>> getSettings() async {
    final rows =
        await SupabaseConfig.client.from(_table).select().maybeSingle();
    return rows ?? {};
  }

  static Future<void> upsert({
    String? theme,
    String? currencyCode,
    int? autoLockMinutes,
  }) async {
    final userId = SupabaseConfig.client.auth.currentUser!.id;
    await SupabaseConfig.client.from(_table).upsert({
      'user_id': userId,
      if (theme != null) 'theme': theme,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (autoLockMinutes != null) 'auto_lock_minutes': autoLockMinutes,
    });
  }
}
