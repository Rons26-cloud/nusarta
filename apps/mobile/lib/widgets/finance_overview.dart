import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../data/models/finance.dart';
import '../features/reports/finance_view_data.dart';
import '../providers/finance_providers.dart';
import 'finance_load_state.dart';
import 'finance_summary.dart';

class FinanceSection extends StatelessWidget {
  const FinanceSection(
      {super.key, required this.title, required this.child, this.route});
  final String title;
  final Widget child;
  final String? route;
  @override
  Widget build(BuildContext context) => Card(
          child: Padding(
        padding: const EdgeInsets.all(16),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(
                child: Text(title,
                    style: Theme.of(context).textTheme.titleMedium)),
            if (route != null)
              TextButton(
                  onPressed: () => context.push(route!),
                  child: const Text('Lihat Semua')),
          ]),
          const SizedBox(height: 12),
          child,
        ]),
      ));
}

/// Inline async state: no nested vertical scroll inside a page list.
class InlineFinanceState<T> extends StatelessWidget {
  const InlineFinanceState(
      {super.key,
      required this.state,
      required this.retry,
      required this.builder});
  final AsyncValue<T> state;
  final VoidCallback retry;
  final Widget Function(T) builder;
  @override
  Widget build(BuildContext context) => state.when(
        loading: () => const Padding(
            padding: EdgeInsets.all(16), child: LinearProgressIndicator()),
        error: (error, _) => Padding(
            padding: const EdgeInsets.all(12),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(FinanceLoadError.messageFor(error)),
              TextButton.icon(
                  onPressed: retry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba lagi')),
            ])),
        data: builder,
      );
}

class FinanceMetrics extends StatelessWidget {
  const FinanceMetrics({super.key, required this.data, this.hidden = false});
  final FinanceViewData data;
  final bool hidden;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
      builder: (context, constraints) => Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final metric in <(String, double, Color)>[
                ('Pemasukan', data.income, AppColors.income),
                ('Pengeluaran', data.expense, AppColors.expense),
                ('Net cashflow / selisih', data.net, AppColors.numberPrimary),
              ])
                SizedBox(
                    width: metric.$1.startsWith('Net')
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 10) / 2,
                    child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: metric.$3.withAlpha(38))),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(metric.$1,
                                  style: Theme.of(context).textTheme.bodySmall),
                              const SizedBox(height: 8),
                              MoneyValue(metric.$2,
                                  hidden: hidden,
                                  style: TextStyle(
                                      color: metric.$3,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w700)),
                            ]))),
            ],
          ));
}

class BudgetOverview extends ConsumerWidget {
  const BudgetOverview(
      {super.key,
      required this.data,
      required this.categoryNames,
      this.hidden = false,
      this.yearly = false,
      this.historical = false});
  final FinanceViewData data;
  final Map<String, String> categoryNames;
  final bool hidden, yearly, historical;

  @override
  Widget build(BuildContext context, WidgetRef ref) => FinanceSection(
        title: yearly ? 'Budget tahunan' : 'Budget bulanan',
        route: '/budgets',
        child: InlineFinanceState(
            state: ref.watch(budgetsProvider),
            retry: () => ref.invalidate(budgetsProvider),
            builder: (budgets) {
              if (historical) {
                return const Text(
                    'Riwayat batas budget belum tersedia. Lihat budget untuk periode saat ini.');
              }
              final selected = budgets
                  .where((b) =>
                      b.period ==
                      (yearly ? BudgetPeriod.yearly : BudgetPeriod.monthly))
                  .toList();
              if (selected.isEmpty) {
                return const Text('Belum ada budget pada periode ini.');
              }
              final total =
                  selected.fold<double>(0, (sum, b) => sum + b.amount);
              final ids = selected.map((b) => b.categoryId).toSet();
              final spent = ids.fold<double>(0,
                  (sum, id) => sum + (data.expenseCategories[id]?.amount ?? 0));
              final ranked = [...selected]..sort((a, b) =>
                  (data.expenseCategories[b.categoryId]?.amount ?? 0).compareTo(
                      data.expenseCategories[a.categoryId]?.amount ?? 0));
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final row in [
                      ('Total budget', total),
                      ('Terpakai', spent),
                      ('Sisa', total - spent)
                    ])
                      Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(row.$1,
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
                                MoneyValue(row.$2,
                                    hidden: hidden,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                              ])),
                    LinearProgressIndicator(
                        value: hidden || total <= 0
                            ? 0
                            : (spent / total).clamp(0.0, 1.0),
                        minHeight: 8,
                        color: spent > total
                            ? AppColors.expense
                            : AppColors.primary),
                    const SizedBox(height: 12),
                    if (!hidden)
                      for (final b in ranked.take(3))
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(categoryNames[b.categoryId] ??
                                      'Kategori tidak tersedia'),
                                  MoneyValue(
                                      data.expenseCategories[b.categoryId]
                                              ?.amount ??
                                          0,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium),
                                  Text(
                                      'dari ${NumberFormat.compactCurrency(locale: 'id_ID', symbol: 'Rp').format(b.amount)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall),
                                ])),
                  ]);
            }),
      );
}

class GoalsOverview extends ConsumerWidget {
  const GoalsOverview({super.key, this.hidden = false});
  final bool hidden;
  @override
  Widget build(BuildContext context, WidgetRef ref) => FinanceSection(
        title: 'Tujuan keuangan',
        route: '/goals',
        child: InlineFinanceState(
            state: ref.watch(goalsProvider),
            retry: () => ref.invalidate(goalsProvider),
            builder: (goals) {
              final active =
                  goals.where((g) => g.current < g.target).take(3).toList();
              if (active.isEmpty) {
                return const Text(
                    'Belum ada tujuan aktif. Tetapkan tujuan keuangan Anda.');
              }
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Progres saat ini • pelacakan manual',
                        style: TextStyle(fontSize: 12)),
                    for (final goal in active)
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(goal.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                Text('Terkumpul',
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
                                MoneyValue(goal.current,
                                    hidden: hidden,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                Text('Target',
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
                                MoneyValue(goal.target,
                                    hidden: hidden,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                    value: hidden ? 0 : goal.progress,
                                    minHeight: 7,
                                    color: AppColors.gold),
                                if (!hidden)
                                  Text(
                                      '${(goal.progress * 100).toStringAsFixed(0)}%'),
                                if (goal.deadline != null)
                                  Text(
                                      'Target tanggal ${DateFormat('d MMM yyyy', 'id_ID').format(goal.deadline!.toLocal())}'),
                              ])),
                  ]);
            }),
      );
}

class PeriodComparison extends StatelessWidget {
  const PeriodComparison(
      {super.key,
      required this.current,
      required this.previous,
      this.hidden = false});
  final FinanceViewData current, previous;
  final bool hidden;
  @override
  Widget build(BuildContext context) {
    if (hidden) return const Text('Perbandingan disembunyikan.');
    if (current.sourceMayBeLimited ||
        previous.transactions.isEmpty ||
        current.transactions.isEmpty) {
      return const Text(
          'Data belum cukup untuk membandingkan periode sebelumnya.');
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Dibanding rentang setara pada periode sebelumnya.',
          style: TextStyle(fontSize: 12)),
      for (final values in [
        ('Pemasukan', current.income, previous.income),
        ('Pengeluaran', current.expense, previous.expense)
      ])
        Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(values.$3 == 0
                ? '${values.$1}: persentase tidak tersedia karena periode sebelumnya Rp0.'
                : '${values.$1}: ${values.$2 >= values.$3 ? '+' : ''}${((values.$2 - values.$3) / values.$3 * 100).toStringAsFixed(1)}%')),
    ]);
  }
}
