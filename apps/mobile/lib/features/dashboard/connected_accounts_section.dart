import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/account.dart';
import '../../data/models/institution.dart';
import '../../data/repositories/balance_repository.dart';
import '../../widgets/finance_summary.dart';
import '../../widgets/institution_logo.dart';

/// "Akun Terhubung" on the Beranda. Renders only accounts that are genuinely
/// active and linked. Balance provenance is required; simulator balances
/// are visibly labelled and never represented as live bank balances.
class ConnectedAccountsSection extends StatelessWidget {
  const ConnectedAccountsSection({
    super.key,
    required this.accounts,
    required this.institutions,
    required this.hidden,
  });

  final List<Account> accounts;
  final List<Institution> institutions;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final linked = accounts.where((a) => a.isConnected).toList();
    if (linked.isEmpty) return const SizedBox.shrink();
    final byInstitution = <String, Institution>{
      for (final i in institutions) i.id: i
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Akun Terhubung',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.heading)),
            TextButton.icon(
              onPressed: () => context.push('/link-accounts'),
              icon: const Icon(Icons.add_link_rounded, size: 16),
              label: const Text('Tambah'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: linked.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final account = linked[index];
              final institution = byInstitution[account.institutionId];
              final hasBalance =
                  const BalanceRepository().read(account).amount != null;
              return SizedBox(
                width: 224,
                child: Card(
                  margin: EdgeInsets.zero,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () =>
                        context.push('/account-detail?accountId=${account.id}'),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            InstitutionLogo(
                                code: institution?.code ?? account.name,
                                name: institution?.name ??
                                    account.displayName ??
                                    account.name,
                                size: 38),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        institution?.name ??
                                            account.displayName ??
                                            account.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13.5)),
                                    Text(
                                      account.maskedAccountNumber ??
                                          '•••• ••••',
                                      style: TextStyle(
                                          color: AppColors.neutral,
                                          fontSize: 12),
                                    ),
                                  ]),
                            ),
                          ]),
                          const Spacer(),
                          if (hasBalance)
                            MoneyValue(account.balance,
                                hidden: hidden,
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 17,
                                    color: AppColors.heading))
                          else
                            Text('Saldo tidak tersedia',
                                style: TextStyle(
                                    color: AppColors.neutral, fontSize: 13)),
                          const SizedBox(height: 4),
                          Row(children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              account.balanceSource == 'simulated' ||
                                      account.balanceSource == 'sandbox'
                                  ? 'SANDBOX · Bukan saldo bank nyata'
                                  : account.lastSyncedAt == null
                                      ? 'Belum sinkron'
                                      : 'Terakhir sinkron · ${account.lastSyncedAt!.day}/${account.lastSyncedAt!.month}',
                              style: TextStyle(
                                  color: AppColors.neutral, fontSize: 11.5),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
