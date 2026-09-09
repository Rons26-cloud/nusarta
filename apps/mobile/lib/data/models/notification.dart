enum AppNotificationType {
  transaction,
  budget,
  security,
  accountConnection,
  transfer,
  system;

  String get dbValue => switch (this) {
        AppNotificationType.accountConnection => 'account_connection',
        _ => name,
      };

  static AppNotificationType fromDb(String value) => switch (value) {
        'account_connection' => AppNotificationType.accountConnection,
        'transaction' => AppNotificationType.transaction,
        'budget' => AppNotificationType.budget,
        'security' => AppNotificationType.security,
        'transfer' => AppNotificationType.transfer,
        _ => AppNotificationType.system,
      };

  bool get isV1Supported => switch (this) {
        AppNotificationType.transaction ||
        AppNotificationType.budget ||
        AppNotificationType.security ||
        AppNotificationType.system =>
          true,
        _ => false,
      };
}

class AppNotification {
  final String id;
  final String userId;
  final AppNotificationType type;
  final String title;
  final String? body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.body,
    this.data = const {},
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) => AppNotification(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        type: AppNotificationType.fromDb(map['type'] as String? ?? 'system'),
        title: map['title'] as String,
        body: map['body'] as String?,
        data: (map['data'] as Map?)?.cast<String, dynamic>() ?? const {},
        isRead: map['is_read'] as bool? ?? false,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'type': type.dbValue,
        'title': title,
        'body': body,
        'data': data,
        'is_read': isRead,
        'created_at': createdAt.toIso8601String(),
      };
}