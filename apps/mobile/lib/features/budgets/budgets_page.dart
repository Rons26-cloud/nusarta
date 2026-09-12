import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/category.dart';
import '../../data/models/finance.dart';
import '../../data/models/transaction.dart';
import '../../providers/auth_provider.dart';
import '../../providers/finance_providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/finance_summary.dart';

class BudgetsPage extends ConsumerStatefulWidget {
  const BudgetsPage({super.key});

  @override
  ConsumerState<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends ConsumerState<BudgetsPage> {
  BudgetPeriod _period = BudgetPeriod.monthly;
  DateTime _periodStart(BudgetPeriod period) {
    final now = DateTime.now();
    switch (period) {
      case BudgetPeriod.weekly:
        return now.subtract(const Duration(days: 7));
      case BudgetPeriod.monthly:
        return DateTime(now.year, now.month, 1);
      case BudgetPeriod.yearly:
        return DateTime(now.year, 1, 1);
    }
  }

  double _spentFor(Budget b, List<Transaction> txs) {
    final start = _periodStart(b.period);
    return txs
        .where((t) =>
            t.kind == TransactionKind.expense &&
            t.categoryId == b.categoryId &&
            !t.occurredAt.isBefore(start))
        .fold<double>(0, (s, t) => s + t.amount);
  }

  @override
  Widget build(BuildContext context) {
    final budgets = ref.watch(budgetsProvider);
    final categories = ref.watch(allCategoriesProvider).valueOrNull ?? [];
    final transactions = ref.watch(transactionsProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Budget')),
      body: budgets.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Gagal memuat budget')),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.donut_small_outlined,
              title: 'Belum ada budget',
              message: 'Atur batas pengeluaran per kategori.',
            );
          }
          final visible = list.where((b) => b.period == _period).toList();
          final total = visible.fold<double>(0, (sum, b) => sum + b.amount);
          final spentTotal = visible.fold<double>(
              0, (sum, b) => sum + _spentFor(b, transactions));
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
            itemCount: visible.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              if (i == 0) {
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(spacing: 8, runSpacing: 4, children: [
                        for (final period in BudgetPeriod.values)
                          ChoiceChip(
                              label: Text(_periodLabel(period)),
                              selected: _period == period,
                              onSelected: (_) =>
                                  setState(() => _period = period)),
                      ]),
                      const SizedBox(height: 12),
                      FinanceSummary(
                          title: 'Total budget · ${_periodLabel(_period)}',
                          amount: total,
                          details: [
                            ('Terpakai', spentTotal),
                            ('Sisa', total - spentTotal)
                          ]),
                      if (visible.isEmpty)
                        const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Belum ada budget pada periode ini.')),
                    ]);
              }
              final b = visible[i - 1];
              final cat = categories
                      .where((c) => c.id == b.categoryId)
                      .firstOrNull
                      ?.name ??
                  'Kategori';
              final spent = _spentFor(b, transactions);
              final ratio = b.amount <= 0 ? 0.0 : (spent / b.amount);
              final over = ratio >= 1.0;
              final warn = !over && ratio >= 0.8;

              final progressColor = over
                  ? AppColors.expense
                  : (warn ? const Color(0xFFD69E2E) : AppColors.primary);

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(cat,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: AppColors.expense, size: 20),
                                  tooltip: 'Hapus budget',
                                  onPressed: () => _confirmDelete(context, b),
                                ),
                              ],
                            ),
                            Text(
                              '${_periodLabel(b.period)} · Terpakai '
                              '${_format(spent)} dari ${_format(b.amount)}'
                              '${over ? ' (Melebihi)' : warn ? ' (Hampir batas)' : ''}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.neutral),
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: ratio.clamp(0, 1),
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                color: progressColor,
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${(ratio * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: progressColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => _AddBudgetSheet(
            categories:
                categories.where((c) => c.kind.name == 'expense').toList(),
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Budget'),
      ),
    );
  }

  String _periodLabel(BudgetPeriod p) => switch (p) {
        BudgetPeriod.weekly => 'Mingguan',
        BudgetPeriod.monthly => 'Bulanan',
        BudgetPeriod.yearly => 'Tahunan'
      };

  String _format(double v) => NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp',
        decimalDigits: 0,
      ).format(v);

  Future<void> _confirmDelete(BuildContext context, Budget b) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus budget ini?'),
        content: const Text('Batas anggaran untuk kategori ini akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(budgetsControllerProvider).delete(b.id);
  }
}

class _AddBudgetSheet extends ConsumerStatefulWidget {
  const _AddBudgetSheet({required this.categories});

  final List<Category> categories;

  @override
  ConsumerState<_AddBudgetSheet> createState() => _AddBudgetSheetState();
}

class _AddBudgetSheetState extends ConsumerState<_AddBudgetSheet> {
  String? _categoryId;
  final _amount = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Tambah Budget',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              isExpanded: true,
              // ignore: deprecated_member_use
              value: _categoryId,
              decoration: const InputDecoration(labelText: 'Kategori'),
              items: widget.categories
                  .map<DropdownMenuItem<String>>(
                      (c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                  .toList(),
              onChanged: (v) => setState(() => _categoryId = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Batas (Rp)'),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving
                  ? null
                  : () async {
                      final category = widget.categories
                          .where((c) => c.id == _categoryId)
                          .firstOrNull;
                      if (category == null) return;
                      final amount =
                          double.tryParse(_amount.text.replaceAll(',', '')) ??
                              0;
                      if (amount <= 0) return;
                      setState(() => _saving = true);
                      final userId = ref.read(currentUserProvider)?.id ?? '';
                      await ref.read(budgetsControllerProvider).create(Budget(
                            id: '',
                            userId: userId,
                            categoryId: category.id,
                            amount: amount,
                          ));
                      if (context.mounted) Navigator.pop(context);
                    },
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
