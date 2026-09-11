import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/config/feature_flags.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/account_status.dart';
import '../../core/utils/labels.dart';
import '../../data/models/account.dart';
import '../../data/models/institution.dart';
import '../../data/models/transaction.dart';
import '../../providers/finance_providers.dart';
import '../../widgets/account_status_badge.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/finance_load_state.dart';
import '../../widgets/transaction_tile.dart';
import 'add_account_sheet.dart';

class AccountsPage extends ConsumerStatefulWidget {
  const AccountsPage({super.key});

  @override
  ConsumerState<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends ConsumerState<AccountsPage> {
  AccountType? _filter;

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider);
    final institutionsAsync = ref.watch(institutionsProvider);
    final institutions = institutionsAsync.valueOrNull ?? const <Institution>[];

    Institution? institutionFor(Account a) {
      if (a.institutionId == null) return null;
      for (final i in institutions) {
        if (i.id == a.institutionId) return i;
      }
      return null;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Akun Keuangan')),
      body: accounts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => FinanceLoadError(
            error: error, onRetry: () => ref.invalidate(accountsProvider)),
        data: (list) {
          final active = list.where((a) => !a.isArchived).toList();
          final archived = list.where((a) => a.isArchived).toList();
          final total = active.fold<double>(0, (s, a) => s + a.balance);

          if (active.isEmpty && archived.isEmpty) {
            return const EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Belum ada akun',
              message: 'Tambahkan akun pertama untuk mulai mencatat keuangan.',
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Saldo',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        NumberFormat.currency(
                          locale: 'id_ID',
                          symbol: 'Rp',
                          decimalDigits: 0,
                        ).format(total),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!FeatureFlags.isEnabled(FeatureFlag.linkedAccounts)) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.rocket_launch_outlined,
                          size: 18, color: AppColors.accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Menghubungkan akun bank & e-wallet otomatis segera '
                          'hadir. Saat ini semua akun dicatat secara manual.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Wrap(spacing: 6, runSpacing: 4, children: [
                for (final item in <(AccountType?, String)>[
                  (null, 'Semua'),
                  (AccountType.bank, 'Bank'),
                  (AccountType.ewallet, 'E-Wallet'),
                  (AccountType.cash, 'Tunai'),
                  (AccountType.custom, 'Lainnya'),
                ])
                  ChoiceChip(
                      label: Text(item.$2),
                      selected: _filter == item.$1,
                      onSelected: (_) => setState(() => _filter = item.$1)),
              ]),
              const SizedBox(height: 12),
              if (!active.any((a) => _filter == null || a.type == _filter))
                const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Belum ada akun pada filter ini.')),
              ...active
                  .where((a) => _filter == null || a.type == _filter)
                  .map((account) => _AccountTile(
                        account: account,
                        institution: institutionFor(account),
                        onTap: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) =>
                              _AccountDetailsSheet(account: account),
                        ),
                      )),
              if (archived.isNotEmpty) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: Text(
                    'Diarsipkan',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.neutral,
                        ),
                  ),
                ),
                ...archived
                    .where((a) => _filter == null || a.type == _filter)
                    .map((account) => _AccountTile(
                          account: account,
                          institution: institutionFor(account),
                          archived: true,
                          onTap: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) =>
                                _AccountDetailsSheet(account: account),
                          ),
                        )),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const AddAccountSheet(),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Akun'),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.account,
    required this.institution,
    required this.onTap,
    this.archived = false,
  });

  final Account account;
  final Institution? institution;
  final VoidCallback onTap;
  final bool archived;

  String get _institutionLabel {
    if (institution != null) return institution!.name;
    return account.type == AccountType.cash
        ? 'Kas / Tunai'
        : accountTypeLabel(account.type);
  }

  @override
  Widget build(BuildContext context) {
    final typeIcon = switch (account.type) {
      AccountType.cash => Icons.payments_outlined,
      AccountType.bank => Icons.account_balance_outlined,
      AccountType.ewallet => Icons.phone_android,
      AccountType.custom => Icons.category_outlined,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        margin: EdgeInsets.zero,
        color:
            archived ? Theme.of(context).cardTheme.color?.withAlpha(153) : null,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primary.withAlpha(26),
                  child: institution?.logoUrl == null
                      ? Icon(typeIcon, color: AppColors.primary)
                      : ClipOval(
                          child: Image.network(institution!.logoUrl!,
                              width: 44,
                              height: 44,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) =>
                                  Icon(typeIcon, color: AppColors.primary))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              account.displayName ?? account.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (account.isPrimary) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.star,
                                size: 15, color: AppColors.accent),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _institutionLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.neutral,
                            ),
                      ),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          NumberFormat.currency(
                            locale: 'id_ID',
                            symbol: 'Rp',
                            decimalDigits: 0,
                          ).format(account.balance),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: archived
                                ? AppColors.neutral
                                : AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          AccountStatusBadge(account: account),
                          if (account.maskedAccountNumber != null)
                            Text(
                              account.maskedAccountNumber!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.neutral),
                            ),
                        ],
                      ),
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
}

class _AccountDetailsSheet extends ConsumerStatefulWidget {
  const _AccountDetailsSheet({required this.account});

  final Account account;

  @override
  ConsumerState<_AccountDetailsSheet> createState() =>
      _AccountDetailsSheetState();
}

class _AccountDetailsSheetState extends ConsumerState<_AccountDetailsSheet> {
  bool _busy = false;

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 118,
              child: Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.neutral),
              ),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      );

  Future<void> _confirmDelete(Account account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus akun ini?'),
        content: const Text('Akun beserta transaksinya akan dihapus permanen. '
            'Saldo dan laporan akan diperbarui.'),
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
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    await ref.read(accountsControllerProvider).delete(account.id);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _toggleArchive(Account account) async {
    setState(() => _busy = true);
    await ref
        .read(accountsControllerProvider)
        .archive(account.id, !account.isArchived);
    if (mounted) {
      setState(() => _busy = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts =
        ref.watch(accountsProvider).valueOrNull ?? const <Account>[];
    Account? liveAccount;
    for (final a in accounts) {
      if (a.id == widget.account.id) {
        liveAccount = a;
        break;
      }
    }
    final account = liveAccount ?? widget.account;

    final institutions =
        ref.watch(institutionsProvider).valueOrNull ?? const <Institution>[];
    Institution? institution;
    if (account.institutionId != null) {
      for (final i in institutions) {
        if (i.id == account.institutionId) {
          institution = i;
          break;
        }
      }
    }

    final allCategories =
        ref.watch(allCategoriesProvider).valueOrNull ?? const [];
    final accountTxs =
        (ref.watch(transactionsProvider).valueOrNull ?? const <Transaction>[])
            .where((t) => t.accountId == account.id)
            .toList();

    final icon = switch (account.type) {
      AccountType.cash => Icons.payments_outlined,
      AccountType.bank => Icons.account_balance_outlined,
      AccountType.ewallet => Icons.phone_android,
      AccountType.custom => Icons.category_outlined,
    };

    final institutionName = institution?.name ??
        (account.type == AccountType.cash ? 'Kas / Tunai' : '—');
    final lastSynced = account.lastSyncedAt == null
        ? 'Setelan manual'
        : DateFormat('d MMM yyyy · HH:mm', 'id_ID')
            .format(account.lastSyncedAt!);

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primary.withAlpha(26),
                        child: Icon(icon, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account.displayName ?? account.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                AccountStatusBadge(account: account),
                                Text(
                                  accountTypeLabel(account.type).toUpperCase(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: AppColors.neutral),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    NumberFormat.currency(
                      locale: 'id_ID',
                      symbol: 'Rp',
                      decimalDigits: 0,
                    ).format(account.balance),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _infoRow('Instansi', institutionName),
                  _infoRow('Nomor Akun', account.maskedAccountNumber ?? '—'),
                  _infoRow('Terakhir Sinkron', lastSynced),
                  _infoRow('Akun Utama', account.isPrimary ? 'Ya' : 'Tidak'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      connectionStatusDescription(account),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text('Transaksi',
                          style: Theme.of(context).textTheme.titleSmall),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.push('/transactions'),
                        child: const Text('Lihat semua'),
                      ),
                    ],
                  ),
                  if (accountTxs.isEmpty)
                    Text(
                      'Belum ada transaksi di akun ini.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.neutral),
                    )
                  else
                    ...accountTxs.take(3).map(
                          (t) => TransactionTile(
                            transaction: t,
                            categoryName: allCategories
                                    .where((c) => c.id == t.categoryId)
                                    .firstOrNull
                                    ?.name ??
                                t.kind.name,
                          ),
                        ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            if (!account.isPrimary)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () async {
                          setState(() => _busy = true);
                          await ref
                              .read(accountsControllerProvider)
                              .setPrimary(account.id, isPrimary: true);
                          if (mounted) setState(() => _busy = false);
                        },
                  icon: const Icon(Icons.star_outline),
                  label: const Text('Jadikan Akun Utama'),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (_) =>
                                  _EditAccountSheet(account: account),
                            ),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Ubah'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _toggleArchive(account),
                    icon: Icon(account.isArchived
                        ? Icons.unarchive_outlined
                        : Icons.archive_outlined),
                    label: Text(account.isArchived ? 'Aktifkan' : 'Arsipkan'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy ? null : () => _confirmDelete(account),
              child: const Text('Hapus Akun',
                  style: TextStyle(color: AppColors.expense)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditAccountSheet extends ConsumerStatefulWidget {
  const _EditAccountSheet({required this.account});

  final Account account;

  @override
  ConsumerState<_EditAccountSheet> createState() => _EditAccountSheetState();
}

class _EditAccountSheetState extends ConsumerState<_EditAccountSheet> {
  late final TextEditingController _nameController;
  late bool _isPrimary;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
        text: widget.account.displayName ?? widget.account.name);
    _isPrimary = widget.account.isPrimary;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _busy = true);
    final account = widget.account;
    final controller = ref.read(accountsControllerProvider);
    if (_isPrimary && !account.isPrimary) {
      await controller.setPrimary(account.id, isPrimary: true);
    }
    await controller.update(Account(
      id: account.id,
      userId: account.userId,
      name: name,
      type: account.type,
      balance: account.balance,
      currencyCode: account.currencyCode,
      isArchived: account.isArchived,
      provider: account.provider,
      externalId: account.externalId,
      isLinked: account.isLinked,
      institutionId: account.institutionId,
      maskedAccountNumber: account.maskedAccountNumber,
      lastFour: account.lastFour,
      displayName: name,
      isPrimary: _isPrimary,
      connectionType: account.connectionType,
      connectionStatus: account.connectionStatus,
      lastSyncedAt: account.lastSyncedAt,
    ));
    if (mounted) Navigator.pop(context);
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
            Text('Ubah Akun', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              enabled: !_busy,
              decoration: const InputDecoration(
                labelText: 'Nama Akun',
                prefixIcon: Icon(Icons.edit_outlined),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Jadikan akun utama'),
              value: _isPrimary,
              onChanged: (v) => setState(() => _isPrimary = v),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
