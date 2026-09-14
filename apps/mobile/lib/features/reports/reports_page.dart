import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/transaction.dart';
import '../../providers/finance_providers.dart';
import '../../widgets/cash_flow_chart.dart';
import '../../widgets/finance_overview.dart';
import '../../widgets/finance_summary.dart';
import '../../widgets/finance_transaction_entry.dart';
import 'finance_view_data.dart';

enum ReportRange { monthly, yearly }

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});
  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  ReportRange _range = ReportRange.monthly;
  DateTime _period = DateTime.now();
  TransactionKind? _kind;
  String? _accountId, _categoryId;
  final _cache = FinanceViewCache();
  final _previousCache = FinanceViewCache();
  final _budgetCache = FinanceViewCache();
  final _compareCache = FinanceViewCache();

  bool get _yearly => _range == ReportRange.yearly;
  DateTime get _start => DateTime(_period.year, _yearly ? 1 : _period.month);
  DateTime get _end => _yearly
      ? DateTime(_period.year + 1)
      : DateTime(_period.year, _period.month + 1);
  void _move(int delta) => setState(() => _period = _yearly
      ? DateTime(_period.year + delta, _period.month)
      : DateTime(_period.year, _period.month + delta));

  Widget _groups(String title, Map<String, FinanceGroup> groups,
      Map<String, String> names, double total,
      {String fallback = 'Tanpa kategori'}) {
    final ranked = FinanceViewData.ranked(groups);
    return FinanceSection(
        title: title,
        child: ranked.isEmpty
            ? const Text('Belum ada aktivitas pada periode ini.')
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                for (final item in ranked)
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(names[item.key] ?? fallback,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            MoneyValue(item.value.amount,
                                style: Theme.of(context).textTheme.titleMedium),
                            Text(
                                '${total == 0 ? '0' : (item.value.amount / total * 100).toStringAsFixed(1)}% • ${item.value.count} transaksi'),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                                value: total == 0
                                    ? 0
                                    : (item.value.amount / total)
                                        .clamp(0.0, 1.0),
                                minHeight: 5,
                                color: AppColors.primary),
                          ])),
              ]));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionsProvider);
    final accountState = ref.watch(accountsProvider);
    final categoryState = ref.watch(allCategoriesProvider);
    final accounts = accountState.valueOrNull ?? [];
    final categories = categoryState.valueOrNull ?? [];
    final accountNames = {
      for (final a in accounts) a.id: a.displayName ?? a.name
    };
    final categoryNames = {for (final c in categories) c.id: c.name};
    final now = DateTime.now();
    final start = _start, end = _end;
    final active = !now.isBefore(start) && now.isBefore(end);
    final previousStart = _yearly
        ? DateTime(start.year - 1)
        : DateTime(start.year, start.month - 1);
    final previousFullEnd = start;
    final previousLastDay = DateTime(previousStart.year,
            (_yearly ? now.month : previousStart.month) + 1, 0)
        .day;
    final previousEnd = !active
        ? previousFullEnd
        : DateTime(
            previousStart.year,
            _yearly ? now.month : previousStart.month,
            now.day.clamp(1, previousLastDay),
            now.hour,
            now.minute,
            now.second);
    final periodLabel =
        DateFormat(_yearly ? 'yyyy' : 'MMMM yyyy', 'id_ID').format(start);

    final controls =
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SegmentedButton<ReportRange>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: ReportRange.monthly, label: Text('Bulan')),
            ButtonSegment(value: ReportRange.yearly, label: Text('Tahun')),
          ],
          selected: {_range},
          onSelectionChanged: (value) => setState(() => _range = value.first)),
      const SizedBox(height: 12),
      Row(children: [
        IconButton(
            tooltip: 'Periode sebelumnya',
            onPressed: () => _move(-1),
            icon: const Icon(Icons.chevron_left)),
        Expanded(
            child: Text(periodLabel,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge)),
        IconButton(
            tooltip: 'Periode berikutnya',
            onPressed: end.isAfter(now) ? null : () => _move(1),
            icon: const Icon(Icons.chevron_right)),
      ]),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 4, children: [
        for (final option in <(String, TransactionKind?)>[
          ('Semua', null),
          ('Pemasukan', TransactionKind.income),
          ('Pengeluaran', TransactionKind.expense)
        ])
          ChoiceChip(
              label: Text(option.$1),
              selected: _kind == option.$2,
              onSelected: (_) => setState(() => _kind = option.$2)),
      ]),
      const SizedBox(height: 12),
      InlineFinanceState(
          state: accountState,
          retry: () => ref.invalidate(accountsProvider),
          builder: (_) => DropdownButtonFormField<String>(
              key: ValueKey('account-filter-$_accountId'),
              isExpanded: true,
              initialValue:
                  accountNames.containsKey(_accountId) ? _accountId : null,
              decoration: const InputDecoration(labelText: 'Akun'),
              items: [
                const DropdownMenuItem<String>(
                    value: null, child: Text('Semua akun')),
                for (final a in accounts)
                  DropdownMenuItem(
                      value: a.id,
                      child: Text(a.displayName ?? a.name,
                          overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (id) => setState(() => _accountId = id))),
      const SizedBox(height: 10),
      InlineFinanceState(
          state: categoryState,
          retry: () => ref.invalidate(allCategoriesProvider),
          builder: (_) => DropdownButtonFormField<String>(
              key: ValueKey('category-filter-$_categoryId'),
              isExpanded: true,
              initialValue:
                  categoryNames.containsKey(_categoryId) ? _categoryId : null,
              decoration: const InputDecoration(labelText: 'Kategori'),
              items: [
                const DropdownMenuItem<String>(
                    value: null, child: Text('Semua kategori')),
                for (final c in categories)
                  DropdownMenuItem(
                      value: c.id,
                      child: Text(c.name, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (id) => setState(() => _categoryId = id))),
      if (_kind != null || _accountId != null || _categoryId != null)
        TextButton(
            onPressed: () => setState(() {
                  _kind = null;
                  _accountId = null;
                  _categoryId = null;
                }),
            child: const Text('Reset filter')),
      const SizedBox(height: 16),
    ]);

    return Scaffold(
      appBar: AppBar(title: const Text('Laporan')),
      body: SafeArea(
          top: false,
          child: state.when(
            loading: () => ListView(
                padding: const EdgeInsets.all(16),
                children: [controls, const LinearProgressIndicator()]),
            error: (_, __) =>
                ListView(padding: const EdgeInsets.all(16), children: [
              controls,
              InlineFinanceState(
                  state: state,
                  retry: () => ref.invalidate(transactionsProvider),
                  builder: (_) => const SizedBox.shrink()),
            ]),
            data: (transactions) {
              final effectiveAccount =
                  accountNames.containsKey(_accountId) ? _accountId : null;
              final effectiveCategory =
                  categoryNames.containsKey(_categoryId) ? _categoryId : null;
              final data = _cache.get(transactions, start, end,
                  kind: _kind,
                  accountId: effectiveAccount,
                  categoryId: effectiveCategory);
              final previous = _previousCache.get(
                  transactions, previousStart, previousEnd,
                  kind: _kind,
                  accountId: effectiveAccount,
                  categoryId: effectiveCategory);
              final comparison = _compareCache.get(
                  transactions, start, active ? now : end,
                  kind: _kind,
                  accountId: effectiveAccount,
                  categoryId: effectiveCategory);
              final budgetData = _budgetCache.get(transactions, start, end);
              final header = <Widget>[
                controls,
                if (data.sourceMayBeLimited)
                  const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                          'Laporan mencakup maksimal 200 transaksi terbaru yang dimuat. Riwayat periode ini mungkin belum lengkap.')),
                if (data.transactions.isEmpty)
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text('Belum ada transaksi pada periode ini.',
                          textAlign: TextAlign.center)),
                FinanceMetrics(data: data),
                const SizedBox(height: 12),
                FinanceSection(
                    title: 'Aktivitas periode',
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                              '${data.transactions.length} transaksi • ${data.days.length} hari aktif'),
                          const SizedBox(height: 8),
                          const Text(
                              'Rata-rata nominal pemasukan / pengeluaran'),
                          MoneyValue(data.average),
                          const SizedBox(height: 8),
                          const Text(
                              'Saldo awal dan akhir historis belum tersedia.',
                              style: TextStyle(fontSize: 12)),
                          const Text(
                              'Pindah saldo tidak dihitung sebagai pemasukan atau pengeluaran.',
                              style: TextStyle(fontSize: 12)),
                        ])),
                const SizedBox(height: 12),
                CashFlowChart(
                    transactions: data.transactions,
                    start: start,
                    end: end,
                    yearly: _yearly),
                const SizedBox(height: 12),
                FinanceSection(
                    title: 'Pemasukan vs Pengeluaran',
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(data.income > 0
                              ? 'Pengeluaran memakai ${(data.expense / data.income * 100).toStringAsFixed(1)}% dari pemasukan.'
                              : 'Rasio belum tersedia karena belum ada pemasukan.'),
                          const SizedBox(height: 8),
                          Text(
                              'Selisih ${data.net < 0 ? 'defisit' : 'surplus'}'),
                          MoneyValue(data.net),
                        ])),
                _groups('Pengeluaran per kategori', data.expenseCategories,
                    categoryNames, data.expense),
                _groups('Pemasukan per kategori', data.incomeCategories,
                    categoryNames, data.income),
                _groups('Akun dengan aktivitas terbesar', data.accounts,
                    accountNames, data.income + data.expense,
                    fallback: 'Akun tidak tersedia'),
                FinanceSection(
                    title: 'Transaksi terbesar',
                    child: data.largest.isEmpty
                        ? const Text('Belum ada pemasukan atau pengeluaran.')
                        : Column(children: [
                            for (final t in data.largest.take(3))
                              FinanceTransactionEntry(
                                  transaction: t,
                                  categoryName: categoryNames[t.categoryId] ??
                                      'Tanpa kategori',
                                  accountName: accountNames[t.accountId] ??
                                      'Akun tidak tersedia'),
                          ])),
                FinanceSection(
                    title: 'Frekuensi transaksi',
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                              '${data.cashCount} pemasukan / pengeluaran dalam ${data.elapsedDays(now)} hari kalender'),
                          Text(
                              '${(data.cashCount / data.elapsedDays(now)).toStringAsFixed(1)} transaksi per hari'),
                          Text(
                              '${data.days.length} hari dengan aktivitas pemasukan / pengeluaran'),
                          if (data.days.isNotEmpty)
                            Builder(builder: (_) {
                              final days = data.days.entries.toList()
                                ..sort((a, b) =>
                                    b.value.count.compareTo(a.value.count));
                              return Text(
                                  'Teraktif: ${DateFormat('d MMM yyyy', 'id_ID').format(days.first.key)} • ${days.first.value.count} transaksi');
                            }),
                        ])),
                FinanceSection(
                    title: 'Tren periode sebelumnya',
                    child: PeriodComparison(
                        current: comparison, previous: previous)),
                BudgetOverview(
                    data: budgetData,
                    categoryNames: categoryNames,
                    yearly: _yearly,
                    historical: !active),
                const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                        'Budget seluruh kategori • tujuan menunjukkan progres saat ini.',
                        style: TextStyle(fontSize: 12))),
                const GoalsOverview(),
                const SizedBox(height: 20),
                Text('Detail transaksi • $periodLabel',
                    style: Theme.of(context).textTheme.titleLarge),
                const Text('Terbaru ke terlama • waktu lokal perangkat',
                    style: TextStyle(fontSize: 12)),
                const SizedBox(height: 12),
              ];
              return CustomScrollView(
                key: const PageStorageKey('reports-scroll'),
                slivers: [
                  SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      sliver: SliverList(
                          delegate: SliverChildListDelegate(header))),
                  SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                          delegate:
                              SliverChildBuilderDelegate((context, index) {
                        final t = data.transactions[index];
                        final local = t.occurredAt.toLocal();
                        final previousDate = index == 0
                            ? null
                            : data.transactions[index - 1].occurredAt.toLocal();
                        final newDay = previousDate == null ||
                            local.year != previousDate.year ||
                            local.month != previousDate.month ||
                            local.day != previousDate.day;
                        return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (newDay)
                                Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(4, 16, 4, 8),
                                    child: Text(
                                        DateFormat('d MMMM yyyy', 'id_ID')
                                            .format(local),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700))),
                              FinanceTransactionEntry(
                                  transaction: t,
                                  categoryName: categoryNames[t.categoryId] ??
                                      'Tanpa kategori',
                                  accountName: accountNames[t.accountId] ??
                                      'Akun tidak tersedia'),
                            ]);
                      }, childCount: data.transactions.length))),
                  const SliverToBoxAdapter(
                      child: Padding(
                          padding: EdgeInsets.fromLTRB(16, 20, 16, 32),
                          child: Text('Akhir laporan',
                              key: ValueKey('report-end'),
                              textAlign: TextAlign.center))),
                ],
              );
            },
          )),
    );
  }
}
