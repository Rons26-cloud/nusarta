enum AccountType {
  cash,
  bank,
  ewallet,
  custom;

  static AccountType fromName(String value) => AccountType.values.firstWhere(
        (t) => t.name == value,
        orElse: () => AccountType.custom,
      );
}

/// One of several ways a financial account may be (in the future) connected.
enum ConnectionType {
  manual,
  bankApi,
  ewalletApi,
  openBanking,
  paymentProvider;

  String get dbValue => switch (this) {
        ConnectionType.manual => 'manual',
        ConnectionType.bankApi => 'bank_api',
        ConnectionType.ewalletApi => 'ewallet_api',
        ConnectionType.openBanking => 'open_banking',
        ConnectionType.paymentProvider => 'payment_provider',
      };

  static ConnectionType fromDb(String value) => switch (value) {
        'bank_api' => ConnectionType.bankApi,
        'ewallet_api' => ConnectionType.ewalletApi,
        'open_banking' => ConnectionType.openBanking,
        'payment_provider' => ConnectionType.paymentProvider,
        _ => ConnectionType.manual,
      };
}

/// Connection lifecycle status (manual in V1; future values reserved).
enum ConnectionStatus {
  manual,
  disconnected,
  pending,
  active,
  expired,
  error,
  revoked;

  String get dbValue => name;

  static ConnectionStatus fromDb(String value) => ConnectionStatus.values
      .firstWhere((s) => s.name == value, orElse: () => ConnectionStatus.manual);
}

/// V1 accounts are manual. `provider`/`externalId`/`isLinked` are reserved
/// for the future connected-finance layer.
class Account {
  final String id;
  final String userId;
  final String name;
  final AccountType type;
  final double balance;
  final String currencyCode;
  final bool isArchived;
  final String? provider;
  final String? externalId;
  final bool isLinked;
  final String? institutionId;
  final String? maskedAccountNumber;
  final String? lastFour;
  final String? displayName;
  final bool isPrimary;
  final ConnectionType connectionType;
  final ConnectionStatus connectionStatus;
  final DateTime? lastSyncedAt;

  const Account({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.balance,
    this.currencyCode = 'IDR',
    this.isArchived = false,
    this.provider,
    this.externalId,
    this.isLinked = false,
    this.institutionId,
    this.maskedAccountNumber,
    this.lastFour,
    this.displayName,
    this.isPrimary = false,
    this.connectionType = ConnectionType.manual,
    this.connectionStatus = ConnectionStatus.manual,
    this.lastSyncedAt,
  });

  factory Account.fromMap(Map<String, dynamic> map) => Account(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        name: map['name'] as String,
        type: AccountType.fromName(map['type'] as String),
        balance: (map['balance'] as num).toDouble(),
        currencyCode: map['currency_code'] as String? ?? 'IDR',
        isArchived: map['is_archived'] as bool? ?? false,
        provider: map['provider'] as String?,
        externalId: map['external_id'] as String?,
        isLinked: map['is_linked'] as bool? ?? false,
        institutionId: map['institution_id'] as String?,
        maskedAccountNumber: map['masked_account_number'] as String?,
        lastFour: map['last_four'] as String?,
        displayName: map['display_name'] as String?,
        isPrimary: map['is_primary'] as bool? ?? false,
        connectionType: ConnectionType.fromDb(
            map['connection_type'] as String? ?? 'manual'),
        connectionStatus: ConnectionStatus.fromDb(
            map['connection_status'] as String? ?? 'manual'),
        lastSyncedAt: map['last_synced_at'] == null
            ? null
            : DateTime.tryParse(map['last_synced_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'name': name,
        'type': type.name,
        'balance': balance,
        'currency_code': currencyCode,
        'is_archived': isArchived,
        'provider': provider,
        'external_id': externalId,
        'is_linked': isLinked,
        'institution_id': institutionId,
        'masked_account_number': maskedAccountNumber,
        'last_four': lastFour,
        'display_name': displayName,
        'is_primary': isPrimary,
        'connection_type': connectionType.dbValue,
        'connection_status': connectionStatus.dbValue,
        'last_synced_at': lastSyncedAt?.toIso8601String(),
      };
}

/// Branded account presets (no trademarked logos are used — generic icons).
enum AccountPreset {
  cash('Cash', AccountType.cash),
  bca('BCA', AccountType.bank),
  bri('BRI', AccountType.bank),
  bni('BNI', AccountType.bank),
  mandiri('Mandiri', AccountType.bank),
  seabank('SeaBank', AccountType.bank),
  jago('Jago', AccountType.bank),
  gopay('GoPay', AccountType.ewallet),
  dana('DANA', AccountType.ewallet),
  ovo('OVO', AccountType.ewallet),
  shopeepay('ShopeePay', AccountType.ewallet),
  custom('Akun Lain', AccountType.custom);

  final String label;
  final AccountType type;
  const AccountPreset(this.label, this.type);
}
