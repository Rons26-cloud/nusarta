import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/security/secure_store.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/transaction.dart';
import '../../providers/auth_provider.dart';
import '../../providers/finance_providers.dart';
import '../../widgets/cash_flow_chart.dart';
import '../../widgets/finance_load_state.dart';
import '../../widgets/finance_summary.dart';
import '../../widgets/transaction_tile.dart';
import '../transactions/add_transaction_sheet.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  bool _hideBalance = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _hideBalance = await AppSecureStore.hideBalance;
      if (mounted) setState(() {});
    });
  }

  DateTime get _monthStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  String _timeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat pagi!';
    if (hour < 15) return 'Selamat siang!';
    if (hour < 19) return 'Selamat sore!';
    return 'Selamat malam!';
  }

  void _openAddSheet({TransactionKind? kind}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddTransactionSheet(initialKind: kind),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider);
    final transactions = ref.watch(transactionsProvider);
    final notifications = ref.watch(notificationsProvider);
    final user = ref.watch(currentUserProvider);

    final unreadCount = notifications.valueOrNull == null
        ? 0
        : notifications.valueOrNull!.where((n) => !n.isRead).length;

    final now = DateTime.now();
    final monthLabel = DateFormat.yMMMM('id_ID').format(now);

    final displayName = user?.userMetadata?['display_name'] as String?;
    final greetingName = (displayName != null && displayName.trim().isNotEmpty)
        ? displayName.trim()
        : (user?.email?.split('@').first ?? '');

    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/brand/logo.png',
          height: 32,
          fit: BoxFit.contain,
        ),
        actions: [
          IconButton(
            tooltip: 'Notifikasi',
            onPressed: () => context.push('/notifications'),
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text('$unreadCount'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(accountsProvider);
          ref.invalidate(transactionsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greetingName.isEmpty
                        ? 'Halo 👋'
                        : 'Halo, ${greetingName[0].toUpperCase()}'
                            '${greetingName.substring(1)} 👋',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_timeGreeting()} · Keuangan yang baik, dimulai hari ini.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.neutral),
                  ),
                ],
              ),
            ),
            accounts.when(
              loading: () => const _BalanceSkeleton(),
              error: (error, _) => FinanceLoadError(
                  error: error,
                  onRetry: () => ref.invalidate(accountsProvider)),
              data: (list) {
                final total = list
                    .where((a) => !a.isArchived)
                    .fold<double>(0, (s, a) => s + a.balance);
                return _BalanceCard(
                  total: total,
                  subtitle: 'Total saldo seluruh akun',
                  hidden: _hideBalance,
                  onToggleVisibility: () async {
                    final next = !_hideBalance;
                    setState(() => _hideBalance = next);
                    await AppSecureStore.setHideBalance(next);
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            _QuickActions(
              onAdd: () => _openAddSheet(),
              onTransactions: () => context.push('/transactions'),
              onReports: () => context.push('/reports'),
              onBudgets: () => context.push('/budgets'),
            ),
            const SizedBox(height: 16),
            Text('Ringkasan bulanan · $monthLabel',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            transactions.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => FinanceLoadError(
                  error: error,
                  onRetry: () => ref.invalidate(transactionsProvider)),
              data: (txs) {
                final monthTx = txs
                    .where((t) =>
                        !t.occurredAt.isBefore(_monthStart) &&
                        t.occurredAt
                            .isBefore(DateTime(now.year, now.month + 1)))
                    .toList();
                final income = monthTx
                    .where((t) => t.kind.name == 'income')
                    .fold<double>(0, (s, t) => s + t.amount);
                final expense = monthTx
                    .where((t) => t.kind.name == 'expense')
                    .fold<double>(0, (s, t) => s + t.amount);

                return Row(
                  children: [
                    Expanded(
                      child: _StatBox(
                        label: 'Pemasukan',
                        amount: income,
                        color: AppColors.income,
                        hidden: _hideBalance,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatBox(
                        label: 'Pengeluaran',
                        amount: expense,
                        color: AppColors.expense,
                        hidden: _hideBalance,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            transactions.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Ringkasan belum dapat dimuat.'),
              data: (txs) => CashFlowChart(
                  transactions: txs,
                  start: _monthStart,
                  end: DateTime(now.year, now.month + 1),
                  hidden: _hideBalance),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: Text('Transaksi terbaru',
                        style: Theme.of(context).textTheme.titleMedium)),
                TextButton(
                  onPressed: () => context.push('/transactions'),
                  child: const Text('Lihat semua'),
                ),
              ],
            ),
            transactions.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => FinanceLoadError(
                  error: error,
                  onRetry: () => ref.invalidate(transactionsProvider)),
              data: (txs) {
                if (txs.isEmpty) {
                  return _EmptyTransactions(
                    onAdd: () => _openAddSheet(),
                  );
                }
                return Column(
                  children: txs
                      .take(5)
                      .map((t) => TransactionTile(
                            transaction: t,
                            categoryName: ref
                                .watch(allCategoriesProvider)
                                .valueOrNull
                                ?.where((c) => c.id == t.categoryId)
                                .firstOrNull
                                ?.name,
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onAdd,
    required this.onTransactions,
    required this.onReports,
    required this.onBudgets,
  });

  final VoidCallback onAdd;
  final VoidCallback onTransactions;
  final VoidCallback onReports;
  final VoidCallback onBudgets;

  @override
  Widget build(BuildContext context) {
    Widget action(IconData icon, String label, VoidCallback onTap) {
      return Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8E6)),
            ),
            child: Column(
              children: [
                Icon(icon, color: AppColors.primary, size: 22),
                const SizedBox(height: 6),
                Text(label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        action(Icons.add_circle_outline, 'Tambah', onAdd),
        const SizedBox(width: 8),
        action(Icons.receipt_long_outlined, 'Transaksi', onTransactions),
        const SizedBox(width: 8),
        action(Icons.donut_small_outlined, 'Budget', onBudgets),
        const SizedBox(width: 8),
        action(Icons.bar_chart_outlined, 'Laporan', onReports),
      ],
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8E6)),
      ),
      child: Column(
        children: [
          const Icon(Icons.receipt_long_outlined,
              size: 40, color: AppColors.neutral),
          const SizedBox(height: 8),
          const Text('Belum ada transaksi.'),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: onAdd,
            child: const Text('Tambah Transaksi'),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.total,
    required this.subtitle,
    required this.hidden,
    required this.onToggleVisibility,
  });

  final double total;
  final String subtitle;
  final bool hidden;
  final VoidCallback onToggleVisibility;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.deepEmerald, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Total Saldo',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const Spacer(),
              IconButton(
                onPressed: onToggleVisibility,
                icon: Icon(
                  hidden ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white70,
                  size: 20,
                ),
                tooltip: hidden ? 'Tampilkan saldo' : 'Sembunyikan saldo',
              ),
            ],
          ),
          const SizedBox(height: 4),
          MoneyValue(
            total,
            hidden: hidden,
            style: const TextStyle(
                color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: Colors.white.withAlpha(204))),
        ],
      ),
    );
  }
}

class _BalanceSkeleton extends StatelessWidget {
  const _BalanceSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withAlpha(38),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.amount,
    required this.color,
    required this.hidden,
  });

  final String label;
  final double amount;
  final Color color;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.neutral)),
            const SizedBox(height: 6),
            MoneyValue(
              amount,
              hidden: hidden,
              style: TextStyle(
                  color: color, fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
