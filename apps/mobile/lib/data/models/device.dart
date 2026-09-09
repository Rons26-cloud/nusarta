enum DevicePlatform {
  android,
  ios,
  web,
  other;

  String get dbValue => name;

  static DevicePlatform fromDb(String value) => DevicePlatform.values
      .firstWhere((p) => p.name == value, orElse: () => DevicePlatform.other);
}

class Device {
  final String id;
  final String userId;
  final String deviceIdentifier;
  final DevicePlatform platform;
  final String? appVersion;
  final String? deviceName;
  final bool trusted;
  final bool biometricEnabled;
  final DateTime lastSeenAt;
  final DateTime? revokedAt;
  final DateTime createdAt;

  const Device({
    required this.id,
    required this.userId,
    required this.deviceIdentifier,
    this.platform = DevicePlatform.other,
    this.appVersion,
    this.deviceName,
    this.trusted = false,
    this.biometricEnabled = false,
    required this.lastSeenAt,
    this.revokedAt,
    required this.createdAt,
  });

  bool get isActive => revokedAt == null;

  String get displayName => deviceName ?? 'Perangkat NUSARTA';

  factory Device.fromMap(Map<String, dynamic> map) => Device(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        deviceIdentifier: map['device_identifier'] as String,
        platform: DevicePlatform.fromDb(map['platform'] as String? ?? 'other'),
        appVersion: map['app_version'] as String?,
        deviceName: map['device_name'] as String?,
        trusted: map['trusted'] as bool? ?? false,
        biometricEnabled: map['biometric_enabled'] as bool? ?? false,
        lastSeenAt: DateTime.parse(map['last_seen_at'] as String),
        revokedAt: map['revoked_at'] == null
            ? null
            : DateTime.tryParse(map['revoked_at'] as String),
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'device_identifier': deviceIdentifier,
        'platform': platform.dbValue,
        'app_version': appVersion,
        'device_name': deviceName,
        'trusted': trusted,
        'biometric_enabled': biometricEnabled,
        'last_seen_at': lastSeenAt.toIso8601String(),
        'revoked_at': revokedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };
}