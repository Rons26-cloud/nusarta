import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/transaction.dart';
import '../../providers/finance_providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/transaction_tile.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _query = TextEditingController();
  TransactionKind? _kind;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(transactionsProvider).valueOrNull ?? [];
    final accounts = ref.watch(accountsProvider).valueOrNull ?? [];
    final categories = ref.watch(allCategoriesProvider).valueOrNull ?? [];

    final q = _query.text.trim().toLowerCase();
    final filtered = all.where((t) {
      if (_kind != null && t.kind != _kind) return false;
      if (q.isEmpty) return true;

      final accountName = accounts
              .where((a) => a.id == t.accountId)
              .firstOrNull
              ?.name
              .toLowerCase() ??
          '';
      final categoryName = categories
              .where((c) => c.id == t.categoryId)
              .firstOrNull
              ?.name
              .toLowerCase() ??
          '';

      return (t.note ?? '').toLowerCase().contains(q) ||
          accountName.contains(q) ||
          categoryName.contains(q);
    }).toList();

    String? accountNameOf(String? id) {
      final a = accounts.where((x) => x.id == id).firstOrNull;
      return a?.name;
    }

    String? categoryNameOf(String? id) {
      final c = categories.where((x) => x.id == id).firstOrNull;
      return c?.name;
    }

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _query,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Cari catatan, akun, kategori…',
            border: InputBorder.none,
            filled: false,
            suffixIcon: _query.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _query.clear();
                      setState(() {});
                    },
                  ),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<TransactionKind?>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: null, label: Text('Semua')),
                ButtonSegment(
                    value: TransactionKind.income, label: Text('Pemasukan')),
                ButtonSegment(
                    value: TransactionKind.expense, label: Text('Pengeluaran')),
                ButtonSegment(
                    value: TransactionKind.transfer,
                    label: Text('Pindah Saldo')),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() => _kind = s.first),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off,
                    title: 'Tidak ada transaksi yang cocok.',
                    message: 'Coba kata kunci lain atau ubah filter.',
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, i) => TransactionTile(
                      transaction: filtered[i],
                      categoryName: categoryNameOf(filtered[i].categoryId),
                      accountName: accountNameOf(filtered[i].accountId),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
