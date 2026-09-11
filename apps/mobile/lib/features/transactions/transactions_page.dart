import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/labels.dart';
import '../../data/models/transaction.dart';
import '../../providers/finance_providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/finance_load_state.dart';
import '../../widgets/transaction_tile.dart';
import 'add_transaction_sheet.dart';

enum _KindFilter { all, income, expense, transfer }

class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  _KindFilter _filter = _KindFilter.all;

  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Hari ini';
    if (diff == 1) return 'Kemarin';
    return DateFormat.yMMMMEEEEd('id_ID').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionsProvider);
    final allCategories = ref.watch(allCategoriesProvider);
    final accounts = ref.watch(accountsProvider);

    String? accountName(String? id) {
      final a = accounts.valueOrNull?.where((x) => x.id == id).firstOrNull;
      return a?.name;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<_KindFilter>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: _KindFilter.all, label: Text('Semua')),
                    ButtonSegment(
                        value: _KindFilter.income, label: Text('Pemasukan')),
                    ButtonSegment(
                        value: _KindFilter.expense, label: Text('Pengeluaran')),
                    ButtonSegment(
                        value: _KindFilter.transfer,
                        label: Text('Pindah Saldo')),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (s) => setState(() => _filter = s.first),
                )),
          ),
          Expanded(
            child: transactions.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => FinanceLoadError(
                  error: error,
                  onRetry: () => ref.invalidate(transactionsProvider)),
              data: (txs) {
                final filtered = txs.where((t) {
                  return switch (_filter) {
                    _KindFilter.all => true,
                    _KindFilter.income => t.kind == TransactionKind.income,
                    _KindFilter.expense => t.kind == TransactionKind.expense,
                    _KindFilter.transfer => t.kind == TransactionKind.transfer,
                  };
                }).toList();

                if (filtered.isEmpty) {
                  return const EmptyState(
                    icon: Icons.swap_vert,
                    title: 'Belum ada transaksi',
                    message: 'Catat pemasukan, pengeluaran, atau pindah saldo.',
                  );
                }

                // Group by day, preserving newest-first order.
                final categories = allCategories.valueOrNull ?? [];
                final groups = <String, List<Transaction>>{};
                for (final t in filtered) {
                  final key = DateFormat('yyyy-MM-dd').format(t.occurredAt);
                  groups.putIfAbsent(key, () => []).add(t);
                }
                final orderedDays = groups.keys.toList()
                  ..sort((a, b) => b.compareTo(a));

                return ListView(
                  padding: const EdgeInsets.only(bottom: 96),
                  children: [
                    for (final day in orderedDays)
                      _DaySection(
                        label: _dayLabel(DateTime.parse('${day}T00:00:00')),
                        children: [
                          for (final t in groups[day]!) ...[
                            TransactionTile(
                              transaction: t,
                              categoryName: categories
                                  .where((c) => c.id == t.categoryId)
                                  .firstOrNull
                                  ?.name,
                              accountName: accountName(t.accountId),
                              onTap: () => showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (_) => _DetailSheet(
                                  t: t,
                                  categoryName: categories
                                      .where((c) => c.id == t.categoryId)
                                      .firstOrNull
                                      ?.name,
                                  accountName: accountName(t.accountId),
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                          ],
                        ],
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const AddTransactionSheet(),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Catat Transaksi'),
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.neutral,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _DetailSheet extends ConsumerWidget {
  const _DetailSheet({
    required this.t,
    required this.categoryName,
    required this.accountName,
  });

  final Transaction t;
  final String? categoryName;
  final String? accountName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amount = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    ).format(t.amount);
    final dateTime = DateFormat(
      'EEEE, d MMMM yyyy · HH:mm',
      'id_ID',
    ).format(t.occurredAt);

    final color = switch (t.kind) {
      TransactionKind.income => AppColors.income,
      TransactionKind.expense => AppColors.expense,
      TransactionKind.transfer => AppColors.accent,
    };

    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 108,
                child: Text(label,
                    style: const TextStyle(color: AppColors.neutral)),
              ),
              Expanded(child: Text(value)),
            ],
          ),
        );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Detail Transaksi',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              transactionKindLabel(t.kind),
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(amount,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: color,
                    )),
            const SizedBox(height: 16),
            row('Waktu', dateTime),
            row('Akun', accountName ?? '—'),
            if (t.kind != TransactionKind.transfer)
              row('Kategori', categoryName ?? '—'),
            if (t.note != null && t.note!.isNotEmpty) row('Catatan', t.note!),
            const SizedBox(height: 20),
            if (t.kind != TransactionKind.transfer)
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => AddTransactionSheet(initial: t),
                  );
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Ubah'),
              ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () => _confirmDelete(context, ref),
              style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
              child: const Text('Hapus', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus transaksi ini?'),
        content: const Text(
            'Saldo dan laporan akan diperbarui. Tindakan ini tidak dapat dibatalkan.'),
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
    final controller = ref.read(transactionsControllerProvider);
    await controller.delete(t.id);
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi dihapus.')),
      );
    }
  }
}
