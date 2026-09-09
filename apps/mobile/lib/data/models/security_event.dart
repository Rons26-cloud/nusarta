enum SecurityEventCategory {
  auth,
  security,
  connection,
  transfer,
  account,
  system;

  String get dbValue => name;

  static SecurityEventCategory fromDb(String value) =>
      SecurityEventCategory.values
              .where((c) => c.name == value)
              .firstOrNull ??
          SecurityEventCategory.system;
}

class SecurityEvent {
  final int id;
  final String userId;
  final SecurityEventCategory category;
  final String eventType;
  final int severity;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const SecurityEvent({
    required this.id,
    required this.userId,
    required this.category,
    required this.eventType,
    this.severity = 0,
    this.metadata = const {},
    required this.createdAt,
  });

  factory SecurityEvent.fromMap(Map<String, dynamic> map) => SecurityEvent(
        id: (map['id'] as num).toInt(),
        userId: map['user_id'] as String,
        category: SecurityEventCategory.fromDb(map['event_category'] as String? ?? 'system'),
        eventType: map['event_type'] as String? ?? '',
        severity: (map['severity'] as num?)?.toInt() ?? 0,
        metadata:
            (map['metadata'] as Map?)?.cast<String, dynamic>() ?? const {},
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}