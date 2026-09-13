import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/config/feature_flags.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/account.dart';
import '../../data/models/institution.dart';
import '../../data/models/transfer_record.dart';
import '../../providers/finance_providers.dart';
import '../../widgets/institution_logo.dart';
import '../connections/connection_service.dart';
import '../connections/financial_provider_adapter.dart';
import '../connections/provider_registry.dart';
import 'transfer_receipt_page.dart';

/// NUSARTA Transfer.
///
/// Uang tidak pernah disimpan oleh NUSARTA: setiap transfer dijalankan dan
/// diverifikasi oleh bank/e-wallet via provider resmi. Halaman ini hanya
/// menampilkan data terhubung sungguhan dan kemampuan penyedia yang nyata.
class TransferPage extends ConsumerWidget {
  const TransferPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = FeatureFlags.isEnabled(FeatureFlag.transfers);
    final accounts = ref.watch(accountsProvider);
    final institutions = ref.watch(institutionsProvider);
    final sources = (accounts.valueOrNull ?? const <Account>[])
        .where((a) => a.isLinked)
        .toList();
    final catalog = institutions.valueOrNull ?? const <Institution>[];

    return Scaffold(
      backgroundColor: AppColors.backgroundOff,
      appBar: AppBar(title: const Text('Transfer')),
      body: SafeArea(
        child: !enabled
            ? const _UnavailableView(
                reason: 'Fitur transfer belum aktif di aplikasi ini.')
            : sources.isEmpty
                ? const _NoSourcesView()
                : TransferFlow(
                    sources: sources,
                    institutions: catalog,
                    actions: const ServerTransferActions(),
                  ),
      ),
    );
  }
}

/// Server-backed actions. Cannot be faked: with no registered provider every
/// operation reports the truthful "unavailable" state.
class ServerTransferActions implements TransferActions {
  const ServerTransferActions();

  @override
  bool get recipientValidationAvailable =>
      ConnectionService.hasLiveProvider &&
      FinancialProviderRegistry.adapters
          .any((a) => a.capabilities.recipientValidationSupported);

  @override
  Future<RecipientValidation> validateRecipient(
          {required Institution target, required String accountIdentifier}) =>
      ConnectionService.validateRecipient(
          target: target, accountIdentifier: accountIdentifier);

  @override
  Future<TransferQuote> getQuote(
          {required Institution target, required TransferRequest request}) =>
      ConnectionService.getTransferQuote(target: target, request: request);

  @override
  Future<TransferReferenceResult> startTransfer(
          {required Institution target, required TransferRequest request}) =>
      ConnectionService.startTransfer(target: target, request: request);
}

abstract class TransferActions {
  bool get recipientValidationAvailable;
  Future<RecipientValidation> validateRecipient(
      {required Institution target, required String accountIdentifier});
  Future<TransferQuote> getQuote(
      {required Institution target, required TransferRequest request});
  Future<TransferReferenceResult> startTransfer(
      {required Institution target, required TransferRequest request});
}

enum _Step { source, recipient, amount, confirm, authorizing }

class TransferFlow extends StatefulWidget {
  const TransferFlow({
    super.key,
    required this.sources,
    required this.institutions,
    required this.actions,
  });

  final List<Account> sources;
  final List<Institution> institutions;
  final TransferActions actions;

  @override
  State<TransferFlow> createState() => TransferFlowState();
}

class TransferFlowState extends State<TransferFlow> {
  _Step _step = _Step.source;
  int _sourceIndex = 0;
  Institution? _target;
  final _recipientNumber = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  RecipientValidation? _validation;
  bool _validating = false;
  bool _starting = false;
  double? _fee;
  TransferRecord? _result;
  String? _error;

  static final _currency =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void dispose() {
    _recipientNumber.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Account get _source => widget.sources[_sourceIndex];
  int _idempotency() => Random().nextInt(1 << 30);

  bool get _numberValid {
    final digits = _recipientNumber.text.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 6;
  }

  double? get _amountValue =>
      double.tryParse(_amount.text.replaceAll(',', '.'));

  Future<void> _validateRecipient() async {
    final target = _target;
    if (target == null) return;
    setState(() {
      _validating = true;
      _error = null;
    });
    try {
      final result = await widget.actions.validateRecipient(
          target: target, accountIdentifier: _recipientNumber.text);
      if (!mounted) return;
      setState(() => _validation = result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _validating = false);
    }
  }

  Future<void> _continueToConfirmation() async {
    final amount = _amountValue;
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Masukkan nominal transfer yang valid.');
      return;
    }
    setState(() {
      _step = _Step.confirm;
      _error = null;
    });
    final target = _target!;
    try {
      final quote = await widget.actions
          .getQuote(target: target, request: _request(target, amount));
      if (!mounted) return;
      setState(() => _fee = quote.fee);
    } catch (_) {
      // Provider quote unavailable: fee is confirmed at the provider.
    }
  }

  TransferRequest _request(Institution target, double amount) =>
      TransferRequest(
        idempotencyKey:
            'nus_${_source.externalId ?? _source.id}_${DateTime.now().microsecondsSinceEpoch}_${_idempotency()}',
        sourceExternalId: _source.externalId ?? _source.id,
        institutionCode: target.code,
        recipientAccountIdentifier: _recipientNumber.text,
        amount: amount,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        currency: 'IDR',
      );

  Future<void> _startTransfer() async {
    final amount = _amountValue!;
    final target = _target!;
    setState(() {
      _step = _Step.authorizing;
      _starting = true;
    });
    try {
      final ref = await widget.actions
          .startTransfer(target: target, request: _request(target, amount));
      if (!mounted) return;
      setState(() => _finishWith(ref.status, null, ref.reference));
    } catch (e) {
      if (!mounted) return;
      setState(() =>
          _finishWith(TransferStepStatus.failed, _friendlyError(e), null));
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  void _finishWith(
      TransferStepStatus status, String? message, String? reference) {
    final normalized = message ?? TransferStatusLabels.subtitle(status);
    final source = _source;
    _result = TransferRecord(
      reference: reference ?? 'nus-${DateTime.now().millisecondsSinceEpoch}',
      provider: _target?.provider ?? 'belum terhubung',
      sourceAccountName: source.displayName ?? source.name,
      sourceMasked: source.maskedAccountNumber ??
          (source.lastFour == null ? '•••• ••••' : '•••• ${source.lastFour}'),
      sourceInstitutionName: source.name,
      recipientInstitutionName: _target?.name ?? '',
      recipientInstitutionCode: _target?.code ?? '',
      recipientMasked:
          '•••• ${_recipientNumber.text.replaceAll(RegExp(r'\D'), '').isNotEmpty ? _recipientNumber.text.replaceAll(RegExp(r'\D'), '').substring(max(0, _recipientNumber.text.replaceAll(RegExp(r'\D'), '').length - 4)) : '••••'}',
      recipientName: _validation?.displayName,
      amount: _amountValue ?? 0,
      fee: _fee ?? 0,
      status: status,
      occurredAt: DateTime.now(),
      message: status == TransferStepStatus.failed ? normalized : null,
    );
  }

  String _friendlyError(Object error) {
    if (error is ProviderCapabilityException) return error.message;
    if (error is UnsupportedError) {
      final message = error.message;
      return (message == null || message.isEmpty)
          ? 'Operasi tidak didukung.'
          : message;
    }
    if (error is FormatException) return 'Data dari penyedia tidak valid.';
    return 'Transfer belum dapat diproses. Coba lagi nanti.';
  }

  void _reset() {
    setState(() {
      _result = null;
      _fee = null;
      _validation = null;
      _error = null;
      _step = _Step.source;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) {
      return _StepResult(
        record: _result!,
        onRestart: _reset,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepHeader(
            title: switch (_step) {
          _Step.source => 'Pilih Sumber Dana',
          _Step.recipient => 'Pilih Tujuan',
          _Step.amount => 'Nominal Transfer',
          _Step.confirm => 'Konfirmasi Transfer',
          _Step.authorizing => 'Menunggu Otorisasi',
        }),
        Expanded(child: _buildStep()),
      ],
    );
  }

  Widget _buildStep() => switch (_step) {
        _Step.source => _sourceStep(),
        _Step.recipient => _recipientStep(),
        _Step.amount => _amountStep(),
        _Step.confirm => _confirmStep(),
        _Step.authorizing => _authorizingStep(),
      };

  Widget _sourceStep() => ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Text('Hanya akun terhubung yang ditampilkan sebagai sumber.',
              style: TextStyle(color: AppColors.neutral, fontSize: 13)),
          const SizedBox(height: 10),
          for (var i = 0; i < widget.sources.length; i++)
            _SourceTile(
              account: widget.sources[i],
              selected: i == _sourceIndex,
              onTap: () => setState(() => _sourceIndex = i),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => setState(() => _step = _Step.recipient),
            child: const Text('Lanjut'),
          ),
        ],
      );

  Widget _recipientStep() => ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Text('Institusi tujuan dan nomor rekening/nomor wallet.',
              style: TextStyle(color: AppColors.neutral, fontSize: 13)),
          const SizedBox(height: 10),
          for (final institution in widget.institutions)
            if (institution.isBank || institution.isEwallet)
              _TargetTile(
                institution: institution,
                selected: _target?.code == institution.code,
                onTap: () => setState(() => _target = institution),
              ),
          const SizedBox(height: 14),
          TextField(
            controller: _recipientNumber,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Nomor rekening / wallet',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() => _validation = null),
          ),
          const SizedBox(height: 10),
          if (widget.actions.recipientValidationAvailable) ...[
            FilledButton.tonal(
              onPressed: _target == null || !_numberValid || _validating
                  ? null
                  : _validateRecipient,
              child: _validating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Validasi Penerima'),
            ),
            if (_validation != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(children: [
                  Icon(
                    _validation!.valid
                        ? Icons.verified_outlined
                        : Icons.error_outline,
                    size: 18,
                    color: _validation!.valid
                        ? AppColors.primary
                        : AppColors.expense,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _validation!.valid
                          ? 'Nama penerima: ${_validation!.displayName ?? '—'}'
                          : 'Penerima tidak valid. Periksa kembali nomornya.',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ]),
              ),
          ] else
            Text(
              'Nama penerima akan dikonfirmasi oleh penyedia pada saat '
              'otorisasi. NUSARTA tidak meminta nama penerima dari pengguna '
              'untuk menghindari kesalahan dan pemalsuan.',
              style: TextStyle(
                  color: AppColors.neutral, fontSize: 12.5, height: 1.5),
            ),
          if (_error != null) _ErrorText(_error!),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _step = _Step.source),
                child: const Text('Kembali'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: _target != null && _numberValid
                    ? () => setState(() => _step = _Step.amount)
                    : null,
                child: const Text('Lanjut'),
              ),
            ),
          ]),
        ],
      );

  Widget _amountStep() => ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Nominal transfer (Rp)',
              hintText: 'contoh: 100000',
              prefixIcon: Icon(Icons.payments_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _note,
            maxLength: 80,
            decoration: const InputDecoration(
              labelText: 'Catatan (opsional)',
              hintText: 'Untuk keperluan pencatatan',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null) _ErrorText(_error!),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _step = _Step.recipient),
                child: const Text('Kembali'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: () => _continueToConfirmation(),
                child: const Text('Lanjutkan'),
              ),
            ),
          ]),
        ],
      );

  Widget _confirmStep() {
    final amount = _amountValue ?? 0;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        _ConfirmCard(
          title: 'Sumber',
          child: Row(children: [
            Expanded(
                child: Text('${_source.displayName ?? _source.name}\n'
                    '${_source.maskedAccountNumber ?? '•••• ••••'}')),
          ]),
        ),
        const SizedBox(height: 10),
        _ConfirmCard(
          title: 'Tujuan',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_target?.name ?? ''} •••• '
                  '${_recipientNumber.text.replaceAll(RegExp(r'\D'), '')}'),
              const SizedBox(height: 4),
              Text(
                _validation?.displayName != null
                    ? 'Nama penerima: ${_validation!.displayName}'
                    : 'Nama penerima: dikonfirmasi penyedia',
                style: TextStyle(color: AppColors.neutral, fontSize: 12.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _ConfirmCard(
          title: 'Rincian',
          child: Column(children: [
            _line('Nominal', _currency.format(amount)),
            const SizedBox(height: 6),
            _line(
                'Biaya Admin',
                _fee == null
                    ? 'Dikonfirmasi penyedia'
                    : _currency.format(_fee!)),
            const Divider(height: 18),
            _line(
                'Total', _fee == null ? '—' : _currency.format(amount + _fee!),
                bold: true),
          ]),
        ),
        const SizedBox(height: 10),
        Text(
          'Setelah konfirmasi, Anda akan diarahkan ke otorisasi resmi '
          'bank/e-wallet. PIN/biometrik/OTP dimasukkan pada layar resmi '
          'penyedia — bukan di NUSARTA.',
          style:
              TextStyle(color: AppColors.neutral, fontSize: 12.5, height: 1.5),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() => _step = _Step.amount),
              child: const Text('Kembali'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton(
              onPressed: _starting ? null : _startTransfer,
              child: _starting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Konfirmasi Transfer'),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _authorizingStep() => ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.gold.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                    strokeWidth: 3, color: AppColors.gold),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
              'Silakan selesaikan verifikasi keamanan dari '
              'penyedia resmi.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            'Otorisasi dilakukan di layar resmi ${_target?.name ?? 'penyedia'}. '
            'PIN/biometrik/OTP tidak pernah dimasukkan di NUSARTA.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.neutral, height: 1.5),
          ),
          const SizedBox(height: 24),
          Text(
            'NUSARTA menunggu konfirmasi dari bank/e-wallet. Status hanya '
            'diambil dari server penyedia.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.neutral, fontSize: 12.5),
          ),
        ],
      );

  Widget _line(String label, String value, {bool bold = false}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.neutral)),
          Text(value,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
        ],
      );
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Text(title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800, color: AppColors.heading)),
      );
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.account,
    required this.selected,
    required this.onTap,
  });
  final Account account;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              InstitutionLogo(
                  code: account.institutionId ?? account.name,
                  name: account.displayName ?? account.name,
                  size: 40),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(account.displayName ?? account.name,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(account.maskedAccountNumber ?? '•••• ••••',
                        style: TextStyle(
                            color: AppColors.neutral, fontSize: 12.5)),
                  ])),
              const SizedBox(width: 8),
              Semantics(
                  selected: selected,
                  child: Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: selected
                          ? AppColors.brandEmerald
                          : AppColors.iconSecondary)),
            ]),
          ),
        ),
      );
}

class _TargetTile extends StatelessWidget {
  const _TargetTile({
    required this.institution,
    required this.selected,
    required this.onTap,
  });
  final Institution institution;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              InstitutionLogo(
                  code: institution.code, name: institution.name, size: 40),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(institution.name,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(institution.isBank ? 'Bank' : 'E-Wallet',
                        style: TextStyle(
                            color: AppColors.neutral, fontSize: 12.5)),
                  ])),
              Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked,
                  color: selected ? AppColors.primary : AppColors.neutral),
            ]),
          ),
        ),
      );
}

class _ConfirmCard extends StatelessWidget {
  const _ConfirmCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      color: AppColors.neutral,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      );
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(children: [
          Icon(Icons.error_outline, color: AppColors.expense, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text(message,
                  style: TextStyle(color: AppColors.expense, fontSize: 13))),
        ]),
      );
}

class _StepResult extends StatelessWidget {
  const _StepResult({required this.record, required this.onRestart});
  final TransferRecord record;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) => ReceiptDetailPage(
        record: record,
        onBack: onRestart,
      );
}

class _UnavailableView extends StatelessWidget {
  const _UnavailableView({required this.reason});
  final String reason;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.deepEmerald, AppColors.primaryDark]),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.gold.withAlpha(80)),
            ),
            child: Column(children: [
              Image.asset('assets/brand/logo.png',
                  width: 72, height: 72, fit: BoxFit.contain),
              const SizedBox(height: 24),
              const Icon(Icons.swap_horiz_rounded,
                  size: 48, color: AppColors.goldLight),
              const SizedBox(height: 16),
              const Text('Transfer',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('Segera Hadir',
                  style: TextStyle(
                      color: AppColors.goldLight, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              Text(reason,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.cream, height: 1.6)),
              const SizedBox(height: 8),
              const Text(
                  'Transfer di NUSARTA hanya berjalan melalui provider resmi '
                  'bank/e-wallet — uangmu tidak pernah berpindah ke NUSARTA.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white70, fontSize: 12.5, height: 1.5)),
            ]),
          ),
          const SizedBox(height: 20),
          const Text(
              'Saat ini NUSARTA mencatat keuangan secara manual. Pindah Saldo '
              'hanya memindahkan catatan antar akun NUSARTA, bukan mengirim uang.',
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton(
              onPressed: () => context.push('/link-accounts'),
              child: const Text('Lihat Katalog Institusi')),
          const SizedBox(height: 8),
          OutlinedButton(
              onPressed: () => context.pop(), child: const Text('Kembali')),
        ]),
      );
}

class _NoSourcesView extends StatelessWidget {
  const _NoSourcesView();

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Icon(Icons.link_off_rounded, size: 56, color: AppColors.neutral),
            const SizedBox(height: 16),
            const Text('Belum ada akun terhubung',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              'Transfer membutuhkan akun bank/e-wallet yang benar-benar '
              'terhubung melalui provider resmi.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.neutral, height: 1.5),
            ),
            const SizedBox(height: 24),
            FilledButton(
                onPressed: () => context.push('/link-accounts'),
                child: const Text('Hubungkan Akun')),
            const SizedBox(height: 8),
            OutlinedButton(
                onPressed: () => context.pop(), child: const Text('Kembali')),
          ],
        ),
      );
}
