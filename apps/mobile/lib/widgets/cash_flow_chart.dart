import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../data/models/transaction.dart';

/// Aggregates provider data locally for display; never creates sample balances.
class CashFlowChart extends StatelessWidget {
  const CashFlowChart(
      {super.key,
      required this.transactions,
      required this.start,
      required this.end,
      this.hidden = false});
  final List<Transaction> transactions;
  final DateTime start;
  final DateTime end;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final days = end.difference(start).inDays;
    final yearly = days > 32;
    final count = yearly ? 12 : (days > 7 ? 5 : days.clamp(1, 7));
    final income = List<double>.filled(count, 0);
    final expense = List<double>.filled(count, 0);
    for (final t in transactions) {
      if (t.occurredAt.isBefore(start) || !t.occurredAt.isBefore(end)) continue;
      final day =
          DateTime(t.occurredAt.year, t.occurredAt.month, t.occurredAt.day)
              .difference(start)
              .inDays;
      final index = (yearly
              ? t.occurredAt.month - 1
              : days > 7
                  ? day ~/ 7
                  : day)
          .clamp(0, count - 1);
      if (t.kind == TransactionKind.income) income[index] += t.amount;
      if (t.kind == TransactionKind.expense) expense[index] += t.amount;
    }
    final maxValue =
        [...income, ...expense].fold<double>(1, (a, b) => a > b ? a : b);
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Pemasukan & pengeluaran',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                const Wrap(spacing: 16, runSpacing: 4, children: [
                  Text('● Pemasukan',
                      style: TextStyle(color: AppColors.income, fontSize: 12)),
                  Text('● Pengeluaran',
                      style: TextStyle(color: AppColors.expense, fontSize: 12)),
                ]),
                const SizedBox(height: 16),
                if (hidden)
                  const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Ringkasan disembunyikan.'))
                else if (income.every((v) => v == 0) &&
                    expense.every((v) => v == 0))
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('Belum ada arus kas pada periode ini.'))
                else
                  SizedBox(
                      height: 160,
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (var i = 0; i < count; i++)
                              Expanded(
                                  child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Expanded(
                                          child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                            Expanded(
                                                child: Semantics(
                                                    label:
                                                        'Pemasukan ${income[i]}',
                                                    child: Container(
                                                        height: 125 *
                                                            income[i] /
                                                            maxValue,
                                                        decoration: BoxDecoration(
                                                            color: AppColors
                                                                .income,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        3))))),
                                            const SizedBox(width: 2),
                                            Expanded(
                                                child: Semantics(
                                                    label:
                                                        'Pengeluaran ${expense[i]}',
                                                    child: Container(
                                                        height: 125 *
                                                            expense[i] /
                                                            maxValue,
                                                        decoration: BoxDecoration(
                                                            color: AppColors
                                                                .expense,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        3))))),
                                          ])),
                                      const SizedBox(height: 8),
                                      Text(
                                          yearly
                                              ? '${i + 1}'
                                              : days > 7
                                                  ? '${i * 7 + 1}'
                                                  : '${start.add(Duration(days: i)).day}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall),
                                    ]),
                              )),
                          ])),
                const SizedBox(height: 8),
                Text(yearly ? 'Bulan (1–12)' : 'Tanggal dalam periode',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            )));
  }
}
