enum TransactionKind { income, expense, transfer }

enum TransactionStatus {
  pending,
  completed,
  failed,
  reversed,
  cancelled;

  static TransactionStatus fromDb(String value) =>
      TransactionStatus.values.firstWhere((s) => s.name == value,
          orElse: () => TransactionStatus.completed);
}

enum TransactionSource {
  manual,
  imported,
  bankApi,
  walletApi;

  /// DB enum values.
  String get dbValue => switch (this) {
        TransactionSource.manual => 'manual',
        TransactionSource.imported => 'imported',
        TransactionSource.bankApi => 'bank_api',
        TransactionSource.walletApi => 'wallet_api',
      };

  static TransactionSource fromDb(String value) => switch (value) {
        'imported' => TransactionSource.imported,
        'bank_api' => TransactionSource.bankApi,
        'wallet_api' => TransactionSource.walletApi,
        _ => TransactionSource.manual,
      };

  bool get isManual => this == TransactionSource.manual;
}

class Transaction {
  final String id;
  final String userId;
  final String accountId;
  final String? categoryId;
  final TransactionKind kind;
  final TransactionSource source;
  final TransactionStatus status;
  final double amount;
  final String? note;
  final String? title;
  final DateTime occurredAt;
  final String? providerReference;

  const Transaction({
    required this.id,
    required this.userId,
    required this.accountId,
    this.categoryId,
    required this.kind,
    this.source = TransactionSource.manual,
    this.status = TransactionStatus.completed,
    required this.amount,
    this.note,
    this.title,
    required this.occurredAt,
    this.providerReference,
  });

  factory Transaction.fromMap(Map<String, dynamic> map) => Transaction(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        accountId: map['account_id'] as String,
        categoryId: map['category_id'] as String?,
        kind: TransactionKind.values.firstWhere(
          (k) => k.name == map['kind'],
          orElse: () => TransactionKind.expense,
        ),
        source: TransactionSource.fromDb(map['source'] as String? ?? 'manual'),
        status:
            TransactionStatus.fromDb(map['status'] as String? ?? 'completed'),
        amount: (map['amount'] as num).toDouble(),
        note: map['note'] as String?,
        title: map['title'] as String?,
        occurredAt: DateTime.parse(map['occurred_at'] as String),
        providerReference: map['provider_reference'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'account_id': accountId,
        'category_id': categoryId,
        'kind': kind.name,
        'source': source.dbValue,
        'status': status.name,
        'amount': amount,
        'note': note,
        'title': title,
        'occurred_at': occurredAt.toIso8601String(),
        'provider_reference': providerReference,
      };
}

/// Internal transfer payload: creates two sides via RPC-safe client flow.
class InternalTransfer {
  final String fromAccountId;
  final String toAccountId;
  final double amount;
  final String? note;

  const InternalTransfer({
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    this.note,
  });
}
