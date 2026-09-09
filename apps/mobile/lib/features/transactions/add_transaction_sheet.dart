import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/labels.dart';
import '../../data/models/transaction.dart';
import '../../providers/auth_provider.dart';
import '../../providers/finance_providers.dart';

/// Adds thousand separators and places the cursor at the end.
class _AmountFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');
    final parsed = int.tryParse(digits) ?? 0;
    final formatted = NumberFormat.decimalPattern('id_ID').format(parsed);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Records income / expense / internal transfer, or edits an existing one.
class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({super.key, this.initialKind, this.initial});

  /// Pre-selected kind (e.g. from a dashboard quick action).
  final TransactionKind? initialKind;

  /// Non-null when editing an existing income/expense transaction.
  final Transaction? initial;

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  late TransactionKind _kind;
  String? _accountId;
  String? _categoryId;
  DateTime _occurredAt = DateTime.now();
  late final TextEditingController _amount;
  final _note = TextEditingController();
  bool _saving = false;
  String? _saveError;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _kind = initial?.kind ?? widget.initialKind ?? TransactionKind.expense;
    _amount = TextEditingController(
      text: initial == null
          ? ''
          : NumberFormat.decimalPattern('id_ID').format(initial.amount.toInt()),
    );
    if (initial != null) {
      _accountId = initial.accountId;
      _categoryId = initial.categoryId;
      _occurredAt = initial.occurredAt;
      _note.text = initial.note ?? '';
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final amount = double.tryParse(_amount.text.replaceAll('.', '')) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nominal yang benar.')),
      );
      return;
    }
    if (_kind != TransactionKind.transfer && _accountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih akun terlebih dahulu.')),
      );
      return;
    }

    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final controller = ref.read(transactionsControllerProvider);
      final userId = ref.read(currentUserProvider)?.id ?? '';
      final note = _note.text.trim().isEmpty ? null : _note.text.trim();

      if (_kind == TransactionKind.transfer) {
        if (_isEdit) throw UnsupportedError('edit-transfer');
        if (_accountId == null ||
            _toAccountId == null ||
            _accountId == _toAccountId) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Pilih akun asal dan tujuan yang berbeda.')),
          );
          return;
        }
        await controller.transfer(InternalTransfer(
          fromAccountId: _accountId!,
          toAccountId: _toAccountId!,
          amount: amount,
          note: note,
        ));
      } else if (_isEdit) {
        await controller.update(Transaction(
          id: widget.initial!.id,
          userId: widget.initial!.userId,
          accountId: _accountId!,
          categoryId: _categoryId,
          kind: _kind,
          source: widget.initial!.source,
          amount: amount,
          note: note,
          occurredAt: _occurredAt,
        ));
      } else {
        await controller.addIncomeExpense(Transaction(
          id: '',
          userId: userId,
          accountId: _accountId!,
          categoryId: _categoryId,
          kind: _kind,
          source: TransactionSource.manual,
          amount: amount,
          note: note,
          occurredAt: _occurredAt,
        ));
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit
              ? 'Transaksi berhasil diperbarui.'
              : 'Transaksi berhasil dicatat.'),
        ),
      );
      Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _saveError =
            'Transaksi belum berhasil disimpan. Periksa koneksi dan coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _toAccountId;

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider).valueOrNull ?? [];
    final categories = ref
            .watch(categoriesProvider(
                _kind == TransactionKind.transfer ? null : _kind))
            .valueOrNull ??
        [];

    final activeAccounts = accounts.where((a) => !a.isArchived).toList();

    String accountLabel(String? id) {
      final a = activeAccounts.where((x) => x.id == id).firstOrNull;
      if (a == null) return 'Akun';
      return '${a.name} — ${accountTypeLabel(a.type)}';
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEdit ? 'Ubah Transaksi' : 'Catat Transaksi',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<TransactionKind>(
                  segments: const [
                    ButtonSegment(
                      value: TransactionKind.expense,
                      icon: Icon(Icons.north_east),
                      label: Text('Pengeluaran'),
                    ),
                    ButtonSegment(
                      value: TransactionKind.income,
                      icon: Icon(Icons.south_west),
                      label: Text('Pemasukan'),
                    ),
                    ButtonSegment(
                      value: TransactionKind.transfer,
                      icon: Icon(Icons.swap_horiz),
                      label: Text('Pindah Saldo'),
                    ),
                  ],
                  showSelectedIcon: false,
                  selected: {_kind},
                  onSelectionChanged: _saving
                      ? null
                      : (s) => setState(() {
                            _kind = s.first;
                            _categoryId = null;
                          }),
                )),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: _accountId,
              decoration: InputDecoration(
                labelText:
                    _kind == TransactionKind.transfer ? 'Dari Akun' : 'Akun',
              ),
              items: activeAccounts
                  .map((a) => DropdownMenuItem(
                      value: a.id, child: Text(accountLabel(a.id))))
                  .toList(),
              onChanged: _saving ? null : (v) => setState(() => _accountId = v),
            ),
            if (_kind == TransactionKind.transfer) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: _toAccountId,
                decoration: const InputDecoration(labelText: 'Ke Akun'),
                items: activeAccounts
                    .map((a) => DropdownMenuItem(
                        value: a.id, child: Text(accountLabel(a.id))))
                    .toList(),
                onChanged:
                    _saving ? null : (v) => setState(() => _toAccountId = v),
              ),
              const SizedBox(height: 8),
              Text(
                'Ini hanya memindahkan saldo catatan antar akun NUSARTA. '
                'Tidak mengirim uang melalui bank.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.neutral),
              ),
            ] else ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: _categoryId,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: categories
                    .map((c) =>
                        DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged:
                    _saving ? null : (v) => setState(() => _categoryId = v),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              inputFormatters: [_AmountFormatter()],
              decoration: const InputDecoration(
                labelText: 'Nominal (Rp)',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving
                        ? null
                        : () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _occurredAt,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null && mounted) {
                              setState(() => _occurredAt = DateTime(
                                    picked.year,
                                    picked.month,
                                    picked.day,
                                    _occurredAt.hour,
                                    _occurredAt.minute,
                                  ));
                            }
                          },
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: Text(DateFormat.yMMMd('id_ID').format(_occurredAt)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving
                        ? null
                        : () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(_occurredAt),
                            );
                            if (picked != null && mounted) {
                              setState(() => _occurredAt = DateTime(
                                    _occurredAt.year,
                                    _occurredAt.month,
                                    _occurredAt.day,
                                    picked.hour,
                                    picked.minute,
                                  ));
                            }
                          },
                    icon: const Icon(Icons.access_time, size: 18),
                    label: Text(DateFormat.Hm('id_ID').format(_occurredAt)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              enabled: !_saving,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                prefixIcon: Icon(Icons.notes_outlined),
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
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEdit ? 'Simpan Perubahan' : 'Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
