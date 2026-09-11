import 'package:flutter/foundation.dart';

import '../../core/config/app_config.dart';
import '../../core/data/supabase_client.dart';
import '../../core/security/secure_store.dart';
import '../models/device.dart';

class DeviceRepository {
  DeviceRepository._();

  static const _table = 'devices';

  static Future<List<Device>> listMine() async {
    final rows = await SupabaseConfig.client
        .from(_table)
        .select()
        .eq('user_id', SupabaseConfig.client.auth.currentUser!.id)
        .order('last_seen_at', ascending: false);
    return rows.map((r) => Device.fromMap(r)).toList();
  }

  static Future<void> ensureRegistered() async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) return;

      final identifier = await AppSecureStore.getOrCreateDeviceId();
      final platform = _detectPlatform();
      const version = '${AppConfig.version}+${AppConfig.buildNumber}';
      final biometricEnabled = await AppSecureStore.isBiometricEnabled;

      final existing = await SupabaseConfig.client
          .from(_table)
          .select('id')
          .eq('user_id', user.id)
          .eq('device_identifier', identifier)
          .maybeSingle();

      final row = {
        'user_id': user.id,
        'device_identifier': identifier,
        'platform': platform.dbValue,
        'app_version': version,
        'device_name': 'NUSARTA ($_platformLabelName)',
        'biometric_enabled': biometricEnabled,
        'last_seen_at': DateTime.now().toUtc().toIso8601String(),
      };

      if (existing == null) {
        await SupabaseConfig.client.from(_table).insert(row);
      } else {
        await SupabaseConfig.client.from(_table).update({
          'last_seen_at': row['last_seen_at'],
          'platform': row['platform'],
        }).eq('id', existing['id'] as String);
      }
    } catch (_) {}
  }

  static DevicePlatform _detectPlatform() {
    if (kIsWeb) return DevicePlatform.web;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => DevicePlatform.android,
      TargetPlatform.iOS || TargetPlatform.macOS => DevicePlatform.ios,
      _ => DevicePlatform.other,
    };
  }

  static String get _platformLabelName {
    if (kIsWeb) return 'Web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'Android',
      TargetPlatform.iOS => 'iOS',
      TargetPlatform.macOS => 'macOS',
      TargetPlatform.windows => 'Windows',
      TargetPlatform.linux => 'Linux',
      _ => 'Lainnya',
    };
  }
}
