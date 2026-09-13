/// A bank/e-wallet connection the user owns. V1 has no live provider, so
/// the table stays empty until an official connection actually exists.
class AccountConnection {
  final String id;
  final String userId;
  final String institutionId;
  final String? financialAccountId;
  final String? provider;
  final String? providerConnectionId;
  final String status;
  final List<String> scopes;
  final DateTime? consentExpiresAt;
  final DateTime? lastSyncedAt;
  final String? lastErrorCode;
  final DateTime? lastErrorAt;

  const AccountConnection({
    required this.id,
    required this.userId,
    required this.institutionId,
    this.financialAccountId,
    this.provider,
    this.providerConnectionId,
    this.status = 'manual',
    this.scopes = const [],
    this.consentExpiresAt,
    this.lastSyncedAt,
    this.lastErrorCode,
    this.lastErrorAt,
  });

  bool get isLinked => status == 'active' && providerConnectionId != null;

  factory AccountConnection.fromMap(Map<String, dynamic> map) =>
      AccountConnection(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        institutionId: map['institution_id'] as String,
        financialAccountId: map['financial_account_id'] as String?,
        provider: map['provider'] as String?,
        providerConnectionId: map['provider_connection_id'] as String?,
        status: map['status'] as String? ?? 'manual',
        scopes: (map['scopes'] as List?)?.cast<String>() ?? const [],
        consentExpiresAt: map['consent_expires_at'] == null
            ? null
            : DateTime.tryParse(map['consent_expires_at'] as String),
        lastSyncedAt: map['last_synced_at'] == null
            ? null
            : DateTime.tryParse(map['last_synced_at'] as String),
        lastErrorCode: map['last_error_code'] as String?,
        lastErrorAt: map['last_error_at'] == null
            ? null
            : DateTime.tryParse(map['last_error_at'] as String),
      );
}
