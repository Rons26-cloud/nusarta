enum BudgetPeriod { weekly, monthly, yearly }

class Budget {
  final String id;
  final String userId;
  final String categoryId;
  final double amount;
  final BudgetPeriod period;

  const Budget({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.amount,
    this.period = BudgetPeriod.monthly,
  });

  factory Budget.fromMap(Map<String, dynamic> map) => Budget(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        categoryId: map['category_id'] as String,
        amount: (map['amount'] as num).toDouble(),
        period: BudgetPeriod.values.firstWhere(
          (p) => p.name == map['period'],
          orElse: () => BudgetPeriod.monthly,
        ),
      );

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'category_id': categoryId,
        'amount': amount,
        'period': period.name,
      };
}

enum GoalPeriod { weekly, monthly, yearly }

class FinancialGoal {
  final String id;
  final String userId;
  final String name;
  final double target;
  final double current;
  final DateTime? deadline;

  const FinancialGoal({
    required this.id,
    required this.userId,
    required this.name,
    required this.target,
    this.current = 0,
    this.deadline,
  });

  double get progress {
    if (target <= 0) return 0;
    return (current / target).clamp(0, 1);
  }

  factory FinancialGoal.fromMap(Map<String, dynamic> map) => FinancialGoal(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        name: map['name'] as String,
        target: (map['target'] as num).toDouble(),
        current: (map['current'] as num?)?.toDouble() ?? 0,
        deadline: map['deadline'] == null
            ? null
            : DateTime.tryParse(map['deadline'] as String),
      );

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'name': name,
        'target': target,
        'current': current,
        'deadline': deadline?.toIso8601String(),
      };
}
