import '../../data/models/transaction.dart';

/// Local presentation aggregation. The repository/provider remain unchanged.
class FinanceViewData {
  FinanceViewData(List<Transaction> source, this.start, this.end,
      {TransactionKind? kind, String? accountId, String? categoryId}) {
    sourceMayBeLimited = source.length >= 200;
    for (final t in source) {
      final date = t.occurredAt.toLocal();
      if (date.isBefore(start) ||
          !date.isBefore(end) ||
          (kind != null && t.kind != kind) ||
          (accountId != null && t.accountId != accountId) ||
          (categoryId != null && t.categoryId != categoryId)) {
        continue;
      }
      transactions.add(t);
      if (t.kind == TransactionKind.transfer) continue;
      final incoming = t.kind == TransactionKind.income;
      if (incoming) {
        income += t.amount;
      } else {
        expense += t.amount;
      }
      final categories = incoming ? incomeCategories : expenseCategories;
      final category =
          categories.putIfAbsent(t.categoryId ?? '', FinanceGroup.new);
      category.add(t);
      accounts.putIfAbsent(t.accountId, FinanceGroup.new).add(t);
      final day = DateTime(date.year, date.month, date.day);
      days.putIfAbsent(day, FinanceGroup.new).add(t);
      if (!incoming) {
        dailyExpense[day] = (dailyExpense[day] ?? 0) + t.amount;
      }
    }
    transactions.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    largest = transactions
        .where((t) => t.kind != TransactionKind.transfer)
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
  }

  final DateTime start;
  final DateTime end;
  late final bool sourceMayBeLimited;
  final transactions = <Transaction>[];
  late final List<Transaction> largest;
  double income = 0;
  double expense = 0;
  final incomeCategories = <String, FinanceGroup>{};
  final expenseCategories = <String, FinanceGroup>{};
  final accounts = <String, FinanceGroup>{};
  final days = <DateTime, FinanceGroup>{};
  final dailyExpense = <DateTime, double>{};
  double get net => income - expense;
  int get cashCount =>
      incomeCategories.values.fold(0, (s, g) => s + g.count) +
      expenseCategories.values.fold(0, (s, g) => s + g.count);
  double get average => cashCount == 0 ? 0 : (income + expense) / cashCount;

  int elapsedDays(DateTime now) {
    final last =
        end.isBefore(now) ? end : DateTime(now.year, now.month, now.day + 1);
    return (DateTime.utc(last.year, last.month, last.day)
            .difference(DateTime.utc(start.year, start.month, start.day))
            .inDays)
        .clamp(1, 366);
  }

  static List<MapEntry<String, FinanceGroup>> ranked(
          Map<String, FinanceGroup> groups) =>
      groups.entries.toList()
        ..sort((a, b) => b.value.amount.compareTo(a.value.amount));
}

class FinanceGroup {
  double amount = 0;
  int count = 0;
  void add(Transaction t) {
    amount += t.amount;
    count++;
  }
}

/// Cache by provider list identity and view parameters; no query in build().
class FinanceViewCache {
  List<Transaction>? _source;
  DateTime? _start, _end;
  TransactionKind? _kind;
  String? _account, _category;
  FinanceViewData? _data;

  FinanceViewData get(List<Transaction> source, DateTime start, DateTime end,
      {TransactionKind? kind, String? accountId, String? categoryId}) {
    if (!identical(source, _source) ||
        start != _start ||
        end != _end ||
        kind != _kind ||
        accountId != _account ||
        categoryId != _category) {
      _source = source;
      _start = start;
      _end = end;
      _kind = kind;
      _account = accountId;
      _category = categoryId;
      _data = FinanceViewData(source, start, end,
          kind: kind, accountId: accountId, categoryId: categoryId);
    }
    return _data!;
  }
}
