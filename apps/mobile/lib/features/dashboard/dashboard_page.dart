import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/security/secure_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/labels.dart';
import '../../data/models/account.dart';
import '../../data/repositories/balance_repository.dart';
import '../../providers/finance_providers.dart';
import '../../widgets/cash_flow_chart.dart';
import '../../widgets/finance_load_state.dart';
import '../../widgets/finance_overview.dart';
import '../../widgets/finance_summary.dart';
import '../../widgets/finance_transaction_entry.dart';
import '../reports/finance_view_data.dart';
import '../transactions/add_transaction_sheet.dart';
import 'connected_accounts_section.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});
  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  bool _hideBalance = false;
  final _cache = FinanceViewCache();
  final _previousCache = FinanceViewCache();
  final _comparisonCache = FinanceViewCache();

  @override
  void initState() {
    super.initState();
    AppSecureStore.hideBalance.then((value) {
      if (mounted) setState(() => _hideBalance = value);
    });
  }

  void _add() => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddTransactionSheet());

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider);
    final transactions = ref.watch(transactionsProvider);
    final categories = ref.watch(allCategoriesProvider);
    final categoryNames = <String, String>{
      for (final c in categories.valueOrNull ?? []) c.id: c.name
    };
    final accountNames = <String, String>{
      for (final a in accounts.valueOrNull ?? []) a.id: a.displayName ?? a.name
    };
    final now = DateTime.now();
    final start = DateTime(now.year, now.month);
    final end = DateTime(now.year, now.month + 1);
    final txs = transactions.valueOrNull;
    final data = txs == null ? null : _cache.get(txs, start, end);
    final prior = txs == null
        ? null
        : _previousCache.get(txs, DateTime(now.year, now.month - 1), start);

    return Scaffold(
      backgroundColor: AppColors.backgroundOff,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
            statusBarColor: AppColors.deepEmerald,
            statusBarIconBrightness: Brightness.light),
        child: SafeArea(
          top: false,
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(accountsProvider);
              ref.invalidate(transactionsProvider);
              ref.invalidate(budgetsProvider);
              ref.invalidate(goalsProvider);
              await Future.wait([
                ref
                    .read(accountsProvider.future)
                    .then<void>((_) {}, onError: (Object _, StackTrace __) {}),
                ref
                    .read(transactionsProvider.future)
                    .then<void>((_) {}, onError: (Object _, StackTrace __) {}),
              ]);
            },
            child: ListView(
              key: const PageStorageKey('home-scroll'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                const _Hero(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      _Balance(
                          accounts: accounts,
                          retry: () => ref.invalidate(accountsProvider),
                          data: data,
                          hidden: _hideBalance,
                          toggle: () async {
                            setState(() => _hideBalance = !_hideBalance);
                            await AppSecureStore.setHideBalance(_hideBalance);
                          }),
                      if ((accounts.valueOrNull ?? const <Account>[])
                          .any((a) => a.isConnected)) ...[
                        const SizedBox(height: 14),
                        ConnectedAccountsSection(
                            accounts: accounts.valueOrNull ?? const <Account>[],
                            institutions:
                                ref.watch(institutionsProvider).valueOrNull ??
                                    const [],
                            hidden: _hideBalance),
                      ],
                      const SizedBox(height: 16),
                      _Actions(
                          onAdd: _add,
                          onTransfer: () => context.push('/transfer'),
                          onBudget: () => context.push('/budgets'),
                          onGoal: () => context.push('/goals')),
                      const SizedBox(height: 22),
                      _title(context, 'Ringkasan bulan ini',
                          DateFormat.yMMMM('id_ID').format(now)),
                      const SizedBox(height: 10),
                      InlineFinanceState(
                        state: transactions,
                        retry: () => ref.invalidate(transactionsProvider),
                        builder: (list) {
                          final current = _cache.get(list, start, end);
                          final comparable =
                              _comparisonCache.get(list, start, now);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              FinanceMetrics(
                                  data: current, hidden: _hideBalance),
                              const SizedBox(height: 10),
                              PeriodComparison(
                                  current: comparable,
                                  previous: prior ?? current,
                                  hidden: _hideBalance),
                              const SizedBox(height: 14),
                              CashFlowChart(
                                  transactions: current.transactions,
                                  start: start,
                                  end: end,
                                  hidden: _hideBalance),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      FinanceSection(
                          title: 'Akun keuangan',
                          route: '/accounts',
                          child: InlineFinanceState(
                              state: accounts,
                              retry: () => ref.invalidate(accountsProvider),
                              builder: (list) {
                                final active = list
                                    .where((a) => !a.isArchived)
                                    .take(3)
                                    .toList();
                                if (active.isEmpty) {
                                  return const Text('Belum ada akun keuangan.');
                                }
                                return Column(
                                  children: [
                                    for (final account in active)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 7),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: AppColors.primary
                                                  .withAlpha(22),
                                              child: Icon(
                                                account.type == AccountType.bank
                                                    ? Icons
                                                        .account_balance_outlined
                                                    : account.type ==
                                                            AccountType.ewallet
                                                        ? Icons
                                                            .phone_android_outlined
                                                        : Icons
                                                            .payments_outlined,
                                                color: AppColors.brandEmerald,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                      account.displayName ??
                                                          account.name,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w700)),
                                                  Text(
                                                    accountTypeLabel(
                                                            account.type) +
                                                        (account.maskedAccountNumber ==
                                                                null
                                                            ? ''
                                                            : ' • ${account.maskedAccountNumber!}'),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: MoneyValue(account.balance,
                                                  hidden: _hideBalance,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleSmall),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                );
                              })),
                      if (data != null) ...[
                        const SizedBox(height: 14),
                        BudgetOverview(
                            data: data,
                            categoryNames: categoryNames,
                            hidden: _hideBalance),
                      ],
                      const SizedBox(height: 14),
                      GoalsOverview(hidden: _hideBalance),
                      const SizedBox(height: 14),
                      _title(context, 'Transaksi terbaru', null),
                      const SizedBox(height: 8),
                      InlineFinanceState(
                        state: transactions,
                        retry: () => ref.invalidate(transactionsProvider),
                        builder: (list) {
                          final recent = [...list]..sort(
                              (a, b) => b.occurredAt.compareTo(a.occurredAt));
                          if (recent.isEmpty) {
                            return FinanceSection(
                                title: 'Belum ada transaksi',
                                child: FilledButton.tonal(
                                    onPressed: _add,
                                    child: const Text('Tambah Transaksi')));
                          }
                          return Column(
                            children: [
                              for (final t in recent.take(5))
                                FinanceTransactionEntry(
                                  transaction: t,
                                  hidden: _hideBalance,
                                  categoryName: categoryNames[t.categoryId] ??
                                      (t.categoryId == null
                                          ? 'Tanpa kategori'
                                          : 'Kategori tidak tersedia'),
                                  accountName: accountNames[t.accountId] ??
                                      'Akun tidak tersedia',
                                ),
                              TextButton(
                                onPressed: () => context.push('/transactions'),
                                child: const Text('Lihat Semua Transaksi'),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      InlineFinanceState(
                        state: transactions,
                        retry: () => ref.invalidate(transactionsProvider),
                        builder: (list) {
                          final current = _cache.get(list, start, end);
                          final ranked =
                              FinanceViewData.ranked(current.expenseCategories);
                          final highest = current.dailyExpense.entries.toList()
                            ..sort((a, b) => b.value.compareTo(a.value));
                          return FinanceSection(
                              title: 'Insight',
                              child: _hideBalance
                                  ? const Text('Insight disembunyikan.')
                                  : ranked.isEmpty
                                      ? const Text(
                                          'Belum cukup data pengeluaran untuk insight bulan ini.')
                                      : Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Text(
                                                'Pengeluaran terbesar: ${categoryNames[ranked.first.key] ?? 'Tanpa kategori'}'),
                                            MoneyValue(
                                                ranked.first.value.amount),
                                            if (highest.isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              Text(
                                                  'Hari pengeluaran tertinggi: ${DateFormat('d MMM yyyy', 'id_ID').format(highest.first.key)}'),
                                              MoneyValue(highest.first.value),
                                            ],
                                            const SizedBox(height: 8),
                                            const Text(
                                                'Rata-rata pengeluaran per hari kalender'),
                                            MoneyValue(current.expense /
                                                current.elapsedDays(now)),
                                          ],
                                        ));
                        },
                      ),
                      const SizedBox(height: 14),
                      const Text('Anda sudah melihat seluruh ringkasan.',
                          key: ValueKey('home-end'),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 18),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _title(BuildContext context, String title, String? subtitle) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
              child: Text(title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800, color: AppColors.heading))),
          if (subtitle != null)
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) => ClipPath(
        clipper: _HeroClipper(),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
              20, MediaQuery.paddingOf(context).top + 10, 20, 27),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [AppColors.deepEmerald, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset('assets/brand/logo.png',
                  height: 44, alignment: Alignment.centerLeft),
              const SizedBox(height: 3),
              const Text('Keuanganmu, Dalam Kendalimu.',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );
}

class _Balance extends StatelessWidget {
  const _Balance(
      {required this.accounts,
      required this.retry,
      required this.data,
      required this.hidden,
      required this.toggle});
  final AsyncValue<List<Account>> accounts;
  final FinanceViewData? data;
  final bool hidden;
  final VoidCallback toggle;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) => accounts.when(
        loading: () => const SizedBox(
            height: 150, child: Center(child: LinearProgressIndicator())),
        error: (error, _) => FinanceLoadError(error: error, onRetry: retry),
        data: (list) {
          const balances = BalanceRepository();
          final linked = balances.connected(list);
          final total = balances.total(list);
          final simulated = linked.any((b) =>
              b.source == BalanceSource.simulated ||
              b.source == BalanceSource.sandbox);
          return Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
                color: AppColors.deepEmerald,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.gold.withAlpha(90))),
            child: CustomPaint(
              painter: _BalancePainter(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 14, 17),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [
                        const Expanded(
                            child: Text('Total saldo',
                                style: TextStyle(
                                    color: AppColors.goldLight,
                                    fontWeight: FontWeight.w700))),
                        IconButton(
                            onPressed: toggle,
                            color: Colors.white,
                            tooltip: hidden
                                ? 'Tampilkan saldo'
                                : 'Sembunyikan saldo',
                            icon: Icon(hidden
                                ? Icons.visibility_off
                                : Icons.visibility)),
                      ]),
                      if (linked.isNotEmpty &&
                          linked.every((b) => b.amount == null))
                        const Text('Saldo belum tersedia',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w700))
                      else
                        MoneyValue(total,
                            hidden: hidden,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 29,
                                fontWeight: FontWeight.w800)),
                      const SizedBox(height: 5),
                      Text(
                          simulated
                              ? 'SANDBOX · Gabungan saldo simulasi'
                              : 'Gabungan seluruh akun terhubung',
                          style: const TextStyle(color: Colors.white70)),
                      if (linked.any((b) => b.amount == null))
                        const Text('Sebagian saldo akun belum tersedia.',
                            style: TextStyle(color: Colors.white70)),
                      if (data != null &&
                          (data!.income != 0 || data!.expense != 0)) ...[
                        const SizedBox(height: 12),
                        Wrap(spacing: 14, runSpacing: 6, children: [
                          _Metric('Pemasukan', data!.income, hidden),
                          _Metric('Pengeluaran', data!.expense, hidden),
                          _Metric('Net cashflow', data!.net, hidden),
                        ]),
                      ],
                    ]),
              ),
            ),
          );
        },
      );
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.hidden);
  final String label;
  final double value;
  final bool hidden;
  @override
  Widget build(BuildContext context) => SizedBox(
      width: 96,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 10)),
        MoneyValue(value,
            hidden: hidden,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700)),
      ]));
}

class _Actions extends StatelessWidget {
  const _Actions(
      {required this.onAdd,
      required this.onTransfer,
      required this.onBudget,
      required this.onGoal});
  final VoidCallback onAdd, onTransfer, onBudget, onGoal;
  @override
  Widget build(BuildContext context) => Row(children: [
        _Action(Icons.add_circle_outline, 'Tambah', onAdd),
        _Action(Icons.swap_horiz_rounded, 'Transfer', onTransfer),
        _Action(Icons.donut_small_outlined, 'Budget', onBudget),
        _Action(Icons.flag_outlined, 'Tujuan', onGoal),
      ]);
}

class _Action extends StatelessWidget {
  const _Action(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Expanded(
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withAlpha(24)),
                  ),
                  child: Column(children: [
                    Icon(icon, color: AppColors.brandEmerald, size: 21),
                    const SizedBox(height: 5),
                    Text(label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ])))));
}

class _HeroClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..lineTo(0, size.height - 24)
    ..quadraticBezierTo(
        size.width * .35, size.height + 12, size.width * .72, size.height - 9)
    ..quadraticBezierTo(
        size.width * .92, size.height - 20, size.width, size.height - 42)
    ..lineTo(size.width, 0)
    ..close();
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _BalancePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gold = Paint()
      ..color = AppColors.gold.withAlpha(125)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()
      ..moveTo(size.width * .4, size.height)
      ..quadraticBezierTo(size.width * .6, size.height * .55, size.width * 1.05,
          size.height * .35);
    canvas.drawPath(path, gold);
    final fine = Paint()
      ..color = Colors.white.withAlpha(22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8;
    for (var i = 0; i < 5; i++) {
      canvas.drawArc(
          Rect.fromLTWH(size.width * .34 - i * 14, size.height * .15 + i * 10,
              size.width * .82 + i * 16, size.height * 1.2),
          3.8,
          1.1,
          false,
          fine);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
