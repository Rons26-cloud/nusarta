import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/transaction.dart';
import '../../providers/finance_providers.dart';
import '../../widgets/cash_flow_chart.dart';
import '../../widgets/finance_load_state.dart';
import '../../widgets/finance_summary.dart';

enum ReportRange { daily, weekly, monthly, yearly }

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});
  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  ReportRange _range = ReportRange.monthly;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionsProvider);
    final categories = ref.watch(allCategoriesProvider).valueOrNull ?? [];
    final now = DateTime.now();
    final start = switch (_range) {
      ReportRange.daily => DateTime(now.year, now.month, now.day),
      ReportRange.weekly => DateTime(now.year, now.month, now.day - 6),
      ReportRange.monthly => DateTime(now.year, now.month),
      ReportRange.yearly => DateTime(now.year),
    };
    final end = switch (_range) {
      ReportRange.daily ||
      ReportRange.weekly =>
        DateTime(now.year, now.month, now.day + 1),
      ReportRange.monthly => DateTime(now.year, now.month + 1),
      ReportRange.yearly => DateTime(now.year + 1),
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => FinanceLoadError(
            error: error, onRetry: () => ref.invalidate(transactionsProvider)),
        data: (transactions) {
          final filtered = transactions
              .where((t) =>
                  t.kind != TransactionKind.transfer &&
                  !t.occurredAt.isBefore(start) &&
                  t.occurredAt.isBefore(end))
              .toList();
          final income = filtered
              .where((t) => t.kind == TransactionKind.income)
              .fold<double>(0, (s, t) => s + t.amount);
          final expense = filtered
              .where((t) => t.kind == TransactionKind.expense)
              .fold<double>(0, (s, t) => s + t.amount);
          final byCategory = <String, double>{};
          for (final t
              in filtered.where((t) => t.kind == TransactionKind.expense)) {
            final name = categories
                    .where((c) => c.id == t.categoryId)
                    .firstOrNull
                    ?.name ??
                'Lainnya';
            byCategory[name] = (byCategory[name] ?? 0) + t.amount;
          }
          const palette = [
            AppColors.primary,
            AppColors.gold,
            AppColors.primaryLight,
            Color(0xFF526FAD),
            Color(0xFFB06D3C)
          ];
          return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SegmentedButton<ReportRange>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                            value: ReportRange.daily, label: Text('Hari')),
                        ButtonSegment(
                            value: ReportRange.weekly, label: Text('7 Hari')),
                        ButtonSegment(
                            value: ReportRange.monthly, label: Text('Bulan')),
                        ButtonSegment(
                            value: ReportRange.yearly, label: Text('Tahun')),
                      ],
                      selected: {_range},
                      onSelectionChanged: (s) =>
                          setState(() => _range = s.first),
                    )),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                      child: _ReportCard(
                          label: 'Pemasukan',
                          amount: income,
                          color: AppColors.income)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _ReportCard(
                          label: 'Pengeluaran',
                          amount: expense,
                          color: AppColors.expense)),
                ]),
                const SizedBox(height: 12),
                FinanceSummary(
                    title: 'Arus Kas Bersih',
                    amount: income - expense,
                    details: [('Pemasukan', income), ('Pengeluaran', expense)]),
                const SizedBox(height: 16),
                CashFlowChart(transactions: filtered, start: start, end: end),
                const SizedBox(height: 16),
                Card(
                    child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Pengeluaran per Kategori',
                                style: Theme.of(context).textTheme.titleMedium),
                            if (byCategory.isEmpty)
                              const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Text(
                                      'Belum ada pengeluaran pada periode ini.'))
                            else ...[
                              SizedBox(
                                  height: 180,
                                  child: PieChart(PieChartData(
                                    centerSpaceRadius: 44,
                                    sectionsSpace: 2,
                                    sections: [
                                      for (final item
                                          in byCategory.entries.indexed)
                                        PieChartSectionData(
                                            value: item.$2.value,
                                            title: '',
                                            radius: 24,
                                            color: palette[
                                                item.$1 % palette.length])
                                    ],
                                  ))),
                              for (final item in byCategory.entries.indexed)
                                Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    child: Row(children: [
                                      Icon(Icons.circle,
                                          size: 10,
                                          color: palette[
                                              item.$1 % palette.length]),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(item.$2.key)),
                                      const SizedBox(width: 8),
                                      Flexible(
                                          child: MoneyValue(item.$2.value,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall)),
                                    ])),
                            ],
                          ],
                        ))),
              ]);
        },
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard(
      {required this.label, required this.amount, required this.color});
  final String label;
  final double amount;
  final Color color;
  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            MoneyValue(amount,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w700, fontSize: 16)),
          ])));
}
