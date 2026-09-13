import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/account_connection.dart';
import '../../data/models/institution.dart';
import '../../providers/finance_providers.dart';
import '../../widgets/institution_logo.dart';

enum _CatalogFilter { all, bank, ewallet }

class LinkAccountsPage extends ConsumerStatefulWidget {
  const LinkAccountsPage({super.key});

  static const _monogramColors = [
    Color(0xFF0E6B58),
    Color(0xFF1E7660),
    Color(0xFF1E5F8A),
    Color(0xFF7A5C1E),
    Color(0xFF6B4A8A),
    Color(0xFF8A3A3A),
    Color(0xFF2A6B7A),
  ];

  @override
  ConsumerState<LinkAccountsPage> createState() => _LinkAccountsPageState();
}

class _LinkAccountsPageState extends ConsumerState<LinkAccountsPage> {
  _CatalogFilter _filter = _CatalogFilter.all;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final institutionsAsync = ref.watch(institutionsProvider);
    final connectionsAsync = ref.watch(accountConnectionsProvider);
    final institutions =
        (institutionsAsync.valueOrNull ?? const <Institution>[])
            .where((i) =>
                i.name.toLowerCase().contains(_query) ||
                i.code.toLowerCase().contains(_query))
            .toList();
    final connections =
        connectionsAsync.valueOrNull ?? const <AccountConnection>[];
    final banks = institutions.where((i) => i.isBank && i.isActive).toList();
    final wallets =
        institutions.where((i) => i.isEwallet && i.isActive).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundOff,
      appBar: AppBar(title: const Text('Hubungkan Akun')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          TextField(
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
              decoration: const InputDecoration(
                  hintText: 'Cari bank atau e-wallet',
                  prefixIcon: Icon(Icons.search))),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.deepEmerald, AppColors.primaryDark]),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.gold.withAlpha(90)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.link_rounded,
                    color: AppColors.goldLight, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sinkronisasi langsung dari sumbernya',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _connectionSummary(connections),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => context.push('/tutorial/link-account'),
            icon: const Icon(Icons.menu_book_outlined, size: 18),
            label: const Text('Pelajari cara menghubungkan akun'),
          ),
          if (institutionsAsync.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (banks.isEmpty && wallets.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                Icon(Icons.store_mall_directory_outlined,
                    size: 40, color: AppColors.neutral),
                const SizedBox(height: 12),
                Text(
                  _query.isEmpty
                      ? 'Katalog institusi belum tersedia.\nCoba lagi nanti.'
                      : 'Bank atau e-wallet tidak ditemukan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.neutral),
                ),
              ]),
            )
          else ...[
            const SizedBox(height: 14),
            _FilterBar(
              selected: _filter,
              onChanged: (filter) => setState(() => _filter = filter),
            ),
            if (_filter == _CatalogFilter.all || _filter == _CatalogFilter.bank)
              if (banks.isNotEmpty) ...[
                const _SectionHeader(title: 'BANK'),
                for (final institution in banks)
                  _InstitutionCard(
                      institution: institution,
                      color: _monogramColorFor(institution)),
              ],
            if (_filter == _CatalogFilter.all ||
                _filter == _CatalogFilter.ewallet)
              if (wallets.isNotEmpty) ...[
                const _SectionHeader(title: 'E-WALLET'),
                for (final institution in wallets)
                  _InstitutionCard(
                      institution: institution,
                      color: _monogramColorFor(institution)),
              ],
          ],
          const SizedBox(height: 8),
          Text(
            'NUSARTA tidak pernah meminta PIN, kata sandi, kode OTP, atau '
            'credential bank. Koneksi hanya dibuat melalui provider resmi '
            'dengan persetujuan (consent) dari kamu.',
            textAlign: TextAlign.center,
            style:
                TextStyle(color: AppColors.neutral, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }

  String _connectionSummary(List<AccountConnection> connections) {
    final linked = connections.where((c) => c.isLinked).toList();
    if (linked.isEmpty) {
      return 'Belum ada akun yang terhubung. Status koneksi selalu '
          'berdasarkan provider resmi yang tersedia.';
    }
    return '${linked.length} akun terhubung. Saldo dan transaksi hanya '
        'ditampilkan dari sumber provider.';
  }

  Color _monogramColorFor(Institution institution) {
    final index = institution.code.codeUnits.fold<int>(0,
        (sum, unit) => (sum + unit) % LinkAccountsPage._monogramColors.length);
    return LinkAccountsPage._monogramColors[index];
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onChanged});

  final _CatalogFilter selected;
  final ValueChanged<_CatalogFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _FilterChipButton(
        label: 'SEMUA',
        active: selected == _CatalogFilter.all,
        onTap: () => onChanged(_CatalogFilter.all),
      ),
      const SizedBox(width: 8),
      _FilterChipButton(
        label: 'BANK',
        active: selected == _CatalogFilter.bank,
        onTap: () => onChanged(_CatalogFilter.bank),
      ),
      const SizedBox(width: 8),
      _FilterChipButton(
        label: 'E-WALLET',
        active: selected == _CatalogFilter.ewallet,
        onTap: () => onChanged(_CatalogFilter.ewallet),
      ),
    ]);
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.neutral;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: active ? AppColors.primary : AppColors.neutral),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? Colors.white : color,
                fontSize: 12.5,
                fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 22, 4, 8),
        child: Text(title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 1.5,
                fontWeight: FontWeight.w800,
                color: AppColors.brandEmerald)),
      );
}

class _InstitutionCard extends StatelessWidget {
  const _InstitutionCard({required this.institution, required this.color});

  final Institution institution;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final status = institution.status;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            _InstitutionLogo(institution: institution),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(institution.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 3),
                  Row(children: [
                    Flexible(
                      child: Text(
                        _capabilityLabel(institution),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            TextStyle(color: AppColors.neutral, fontSize: 12.5),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _StatusChip(status: status),
          ]),
        ),
      ),
    );
  }

  String _capabilityLabel(Institution institution) {
    final features = <String>[];
    if (institution.syncSupported) features.add('Sinkronisasi transaksi');
    if (institution.transferSupported) features.add('Transfer');
    if (features.isEmpty) {
      return 'Koneksi resmi belum aktif';
    }
    return features.join(' · ');
  }

  void _openDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _InstitutionDetailSheet(institution: institution),
    );
  }
}

class _InstitutionLogo extends StatelessWidget {
  const _InstitutionLogo({required this.institution});
  final Institution institution;

  @override
  Widget build(BuildContext context) =>
      InstitutionLogo(code: institution.code, name: institution.name, size: 40);
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final InstitutionStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      InstitutionStatus.available => ('Tersedia', AppColors.primary),
      InstitutionStatus.maintenance => ('Pemeliharaan', AppColors.accent),
      InstitutionStatus.unsupported => ('Belum Didukung', AppColors.neutral),
      InstitutionStatus.comingSoon => ('Segera Hadir', AppColors.gold),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11.5, fontWeight: FontWeight.w700)),
    );
  }
}

class _InstitutionDetailSheet extends StatelessWidget {
  const _InstitutionDetailSheet({required this.institution});

  final Institution institution;

  @override
  Widget build(BuildContext context) {
    final status = institution.status;

    final provider = institution.provider;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(institution.name,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(22),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.accent.withAlpha(70)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.shield_outlined,
                        size: 18, color: AppColors.accent),
                    SizedBox(width: 8),
                    Text('Consent',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent)),
                  ]),
                  const SizedBox(height: 8),
                  Text(
                    'Menghubungkan akun memerlukan persetujuan resmi dari '
                    'kamu. NUSARTA hanya meminta akses yang diperlukan dan '
                    'tidak akan menyimpan PIN, kata sandi, atau OTP.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.neutral, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _InfoRow('Status', _statusLabel(status)),
            _InfoRow('Sinkronisasi saldo',
                institution.syncSupported ? 'Tersedia' : 'Belum tersedia'),
            _InfoRow('Sinkronisasi transaksi',
                institution.syncSupported ? 'Tersedia' : 'Belum tersedia'),
            _InfoRow('Transfer',
                institution.transferSupported ? 'Tersedia' : 'Belum tersedia'),
            if (provider != null && provider.isNotEmpty) ...[
              const SizedBox(height: 4),
              _InfoRow('Provider', provider),
            ],
            const SizedBox(height: 18),
            const FilledButton(
                onPressed: null, child: Text('Penyambungan belum tersedia')),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(InstitutionStatus status) => switch (status) {
        InstitutionStatus.available => 'Tersedia',
        InstitutionStatus.comingSoon => 'Segera Hadir',
        InstitutionStatus.maintenance => 'Pemeliharaan',
        InstitutionStatus.unsupported => 'Belum didukung',
      };
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 150,
              child: Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.neutral)),
            ),
            Expanded(
                child: Text(value,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
      );
}
