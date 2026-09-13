import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/labels.dart';
import '../../data/models/account.dart';
import '../../data/models/institution.dart';
import '../../providers/finance_providers.dart';
import '../../widgets/finance_summary.dart';
import '../../widgets/finance_transaction_entry.dart';
import '../../widgets/institution_logo.dart';
import '../connections/connection_service.dart';

/// Detail of a connected financial account. All data comes from providers;
/// balance is only shown after a real sync. Actions are gated by the real
/// institution/provider capability.
class AccountDetailPage extends ConsumerWidget {
  const AccountDetailPage({super.key, required this.accountId});

  final String accountId;

  static final _date = DateFormat('d MMM yyyy, HH:mm', 'id_ID');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider).valueOrNull;
    Account? account;
    for (final a in accounts ?? const <Account>[]) {
      if (a.id == accountId) {
        account = a;
        break;
      }
    }
    if (account == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Akun')),
        body: const Center(child: Text('Akun tidak ditemukan.')),
      );
    }
    final current = account;

    final institutions = ref.watch(institutionsProvider).valueOrNull;
    Institution? institution;
    for (final i in institutions ?? const <Institution>[]) {
      if (i.id == current.institutionId) {
        institution = i;
        break;
      }
    }
    final transferAvailable = institution != null &&
        ConnectionService.transferSupportedBy(institution);
    final hasBalance = current.isLinked && current.lastSyncedAt != null;
    final transactions =
        ref.watch(transactionsProvider).valueOrNull ?? const [];
    final recent =
        (transactions.where((t) => t.accountId == current.id).toList()
              ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt)))
            .take(5);

    return Scaffold(
      backgroundColor: AppColors.backgroundOff,
      appBar: AppBar(title: const Text('Detail Akun')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(children: [
                  InstitutionLogo(
                      code: institution?.code ?? current.name,
                      name: institution?.name ??
                          current.displayName ??
                          current.name,
                      size: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            institution?.name ??
                                current.displayName ??
                                current.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 17)),
                        const SizedBox(height: 2),
                        Text(current.maskedAccountNumber ?? '•••• ••••',
                            style: TextStyle(
                                color: AppColors.neutral, fontSize: 13)),
                      ],
                    ),
                  ),
                  if (hasBalance)
                    MoneyValue(current.balance,
                        style: TextStyle(
                            color: AppColors.numberPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 17))
                  else
                    Text('Saldo tidak tersedia',
                        style: TextStyle(
                            color: AppColors.neutral, fontSize: 12.5)),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              child: Column(children: [
                _InfoRow('Jenis akun', accountTypeLabel(current.type)),
                _InfoRow('Status koneksi',
                    _connectionLabel(current.connectionStatus)),
                _InfoRow(
                    'Terakhir sinkron',
                    current.lastSyncedAt == null
                        ? 'Belum pernah'
                        : _date.format(current.lastSyncedAt!)),
              ]),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => _sync(context),
                  icon: const Icon(Icons.sync_rounded, size: 18),
                  label: const Text('Sinkronkan'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: transferAvailable
                      ? () => context.push('/transfer')
                      : null,
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: const Text('Transfer'),
                ),
              ),
            ]),
            if (!transferAvailable) ...[
              const SizedBox(height: 6),
              Text('Transfer belum didukung untuk akun ini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.neutral, fontSize: 12)),
            ],
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _disconnect(context),
              icon: const Icon(Icons.link_off_rounded, size: 18),
              label: const Text('Putuskan Koneksi'),
              style:
                  OutlinedButton.styleFrom(foregroundColor: AppColors.expense),
            ),
            const SizedBox(height: 22),
            Text('Transaksi terbaru',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.heading)),
            const SizedBox(height: 8),
            if (recent.isEmpty)
              Text('Belum ada transaksi.',
                  style: TextStyle(color: AppColors.neutral))
            else
              for (final t in recent)
                FinanceTransactionEntry(
                  transaction: t,
                  hidden: false,
                  categoryName: 'Provider',
                  accountName: current.displayName ?? current.name,
                ),
          ],
        ),
      ),
    );
  }

  void _sync(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Sinkronisasi otomatis aktif saat koneksi provider terhubung.')));
  }

  Future<void> _disconnect(BuildContext context) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Putuskan Koneksi?'),
              content: const Text(
                  'Akun tidak lagi tersinkron. Pemutusan dilakukan resmi '
                  'melalui penyedia (server-side); data yang menjadi hakmu '
                  'tetap aman.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Batal')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Putuskan')),
              ],
            ));
    if (confirmed != true || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Koneksi akan diputuskan melalui penyedia resmi.')));
  }

  String _connectionLabel(ConnectionStatus status) => switch (status) {
        ConnectionStatus.active => 'Terhubung',
        ConnectionStatus.pending => 'Menunggu konfirmasi',
        ConnectionStatus.expired => 'Kedaluwarsa',
        ConnectionStatus.error => 'Kesalahan koneksi',
        ConnectionStatus.revoked => 'Diputus',
        ConnectionStatus.disconnected => 'Tidak terhubung',
        ConnectionStatus.manual => 'Manual',
      };
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                child: Text(label, style: TextStyle(color: AppColors.neutral))),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
