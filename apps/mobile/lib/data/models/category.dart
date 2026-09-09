import 'transaction.dart';

class Category {
  final String id;
  final String userId;
  final String name;
  final TransactionKind kind;
  final String? icon;
  final String? color;
  final bool isDefault;
  final bool isArchived;

  const Category({
    required this.id,
    required this.userId,
    required this.name,
    this.kind = TransactionKind.expense,
    this.icon,
    this.color,
    this.isDefault = false,
    this.isArchived = false,
  });

  factory Category.fromMap(Map<String, dynamic> map) => Category(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        name: map['name'] as String,
        kind: TransactionKind.values.firstWhere(
          (k) => k.name == map['kind'],
          orElse: () => TransactionKind.expense,
        ),
        icon: map['icon'] as String?,
        color: map['color'] as String?,
        isDefault: map['is_default'] as bool? ?? false,
        isArchived: map['is_archived'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'name': name,
        'kind': kind.name,
        'icon': icon,
        'color': color,
        'is_default': isDefault,
        'is_archived': isArchived,
      };
}
