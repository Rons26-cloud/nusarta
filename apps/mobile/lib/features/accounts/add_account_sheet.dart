import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/feature_flags.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/labels.dart';
import '../../data/models/account.dart';
import '../../data/models/institution.dart';
import '../../providers/finance_providers.dart';

enum _ManualSource { cash, custom }

class AddAccountSheet extends ConsumerStatefulWidget {
  const AddAccountSheet({super.key});

  @override
  ConsumerState<AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends ConsumerState<AddAccountSheet> {
  final _name = TextEditingController();
  final _balance = TextEditingController();
  final _lastFour = TextEditingController();
  Object? _selected;
  bool _isPrimary = false;
  bool _saving = false;
  String? _saveError;
  String? _lastFourError;

  @override
  void dispose() {
    _name.dispose();
    _balance.dispose();
    _lastFour.dispose();
    super.dispose();
  }

  AccountType get _typeFor {
    final sel = _selected;
    if (sel is Institution) {
      return switch (sel.institutionType) {
        'ewallet' => AccountType.ewallet,
        'bank' => AccountType.bank,
        _ => AccountType.custom,
      };
    }
    return switch (sel) {
      _ManualSource.cash => AccountType.cash,
      _ => AccountType.custom,
    };
  }

  void _onSelected(Object? value) {
    setState(() {
      _selected = value;
      _lastFourError = null;
      if (value is Institution) {
        _name.text = value.name;
      } else if (value == _ManualSource.cash) {
        _name.text = 'Kas';
      } else if (value == _ManualSource.custom) {
        _name.text = '';
      }
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = _name.text.trim();
    final lastFourInput = _lastFour.text.trim();
    if (name.isEmpty) return;
    if (lastFourInput.isNotEmpty && lastFourInput.length != 4) {
      setState(
          () => _lastFourError = 'Masukkan 4 digit terakhir nomor rekening.');
      return;
    }

    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final institution =
          _selected is Institution ? _selected as Institution : null;
      final controller = ref.read(accountsControllerProvider);
      await controller.createAccount(
        name: name,
        type: _typeFor,
        balance: double.tryParse(_balance.text.replaceAll(',', '').trim()) ?? 0,
        institutionId: institution?.id,
        displayName: name,
        lastFour: lastFourInput.isEmpty ? null : lastFourInput,
        maskedAccountNumber:
            lastFourInput.isEmpty ? null : '•••• $lastFourInput',
        isPrimary: _isPrimary,
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _saveError =
            'Akun belum berhasil disimpan. Periksa koneksi dan coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final institutionsAsync = ref.watch(institutionsProvider);
    final institutions = institutionsAsync.valueOrNull ?? const <Institution>[];
    final catalogAvailable =
        FeatureFlags.isEnabled(FeatureFlag.institutionCatalog);

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Tambah Akun', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Pilih bank, e-wallet, atau catat sumber secara manual.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.neutral),
            ),
            const SizedBox(height: 16),
            if (catalogAvailable) ...[
              if (institutionsAsync.isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(),
                ),
              DropdownButtonFormField<Object?>(
                // Keep compatible with Flutter 3.24 until the toolchain upgrade is verified.
                // ignore: deprecated_member_use
                value: _selected,
                isExpanded: true,
                hint: const Text('Pilih sumber akun (opsional)'),
                items: [
                  const DropdownMenuItem(
                    value: _ManualSource.cash,
                    child: Text('Kas / Tunai'),
                  ),
                  const DropdownMenuItem(
                    value: _ManualSource.custom,
                    child: Text('Akun Lainnya (Manual)'),
                  ),
                  if (institutions.isNotEmpty)
                    const DropdownMenuItem(
                      enabled: false,
                      child: Text('Katalog bank & e-wallet'),
                    ),
                  for (final inst in institutions)
                    DropdownMenuItem(
                      value: inst,
                      child: Text(
                          '${inst.name} — ${institutionTypeLabel(inst.institutionType)}'),
                    ),
                ],
                onChanged: _onSelected,
              ),
              if (institutions.isEmpty && !institutionsAsync.isLoading)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Katalog belum tersedia. Kamu masih bisa menambahkan '
                    'akun secara manual.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.neutral),
                  ),
                ),
            ] else
              DropdownButtonFormField<Object?>(
                // Keep compatible with Flutter 3.24 until the toolchain upgrade is verified.
                // ignore: deprecated_member_use
                value: _selected,
                isExpanded: true,
                hint: const Text('Tipe akun'),
                items: [
                  for (final s in _ManualSource.values)
                    DropdownMenuItem(
                      value: s,
                      child: Text(switch (s) {
                        _ManualSource.cash => 'Kas / Tunai',
                        _ManualSource.custom => 'Akun Lainnya (Manual)',
                      }),
                    ),
                ],
                onChanged: _onSelected,
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Nama Akun',
                prefixIcon: Icon(Icons.edit_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lastFour,
              keyboardType: TextInputType.number,
              maxLength: 4,
              onChanged: (_) {
                if (_lastFourError != null) {
                  setState(() => _lastFourError = null);
                }
              },
              decoration: InputDecoration(
                labelText: '4 Digit Terakhir (opsional)',
                prefixText: '••••  ',
                counterText: '',
                errorText: _lastFourError,
                prefixIcon: const Icon(Icons.pin_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _balance,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Saldo Awal (opsional)',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Saldo awal adalah saldo yang kamu masukkan secara manual.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.neutral),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Jadikan akun utama'),
              subtitle: const Text('Akun yang paling sering kamu gunakan'),
              value: _isPrimary,
              onChanged: (v) => setState(() => _isPrimary = v),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline,
                      size: 18, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Akun yang terhubung otomatis ke bank/e-wallet segera '
                      'hadir. Saat ini semua akun dicatat secara manual dan '
                      'belum ada koneksi ke pihak luar.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_saveError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    _saveError!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ),
            FilledButton(
              onPressed: _saving || _name.text.trim().isEmpty ? null : _save,
              child: Text(_saving ? 'Menyimpan...' : 'Simpan Akun'),
            ),
          ],
        ),
      ),
    );
  }
}
