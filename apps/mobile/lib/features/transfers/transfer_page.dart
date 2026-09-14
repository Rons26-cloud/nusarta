import 'dart:async';
import 'dart:convert';
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
import '../../data/repositories/balance_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/finance_providers.dart';
import '../../widgets/institution_logo.dart';
import '../connections/connection_service.dart';
import '../connections/financial_provider_adapter.dart';
import '../connections/provider_registry.dart';
import '../connections/sandbox_provider_adapter.dart';
import 'transfer_authorization.dart';
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
    final enabled = FeatureFlags.isEnabled(FeatureFlag.transfers) ||
        FinancialProviderRegistry.sandboxEnabled;
    final accounts = ref.watch(accountsProvider);
    final institutions = ref.watch(institutionsProvider);
    final sources = (accounts.valueOrNull ?? const <Account>[])
        .where((a) =>
            a.isConnected &&
            a.userId == ref.watch(currentUserProvider)?.id &&
            FinancialProviderRegistry.adapterFor(a.provider ?? '')
                    ?.capabilities
                    .transferSupported ==
                true)
        .toList();
    final catalog = (institutions.valueOrNull ?? const <Institution>[])
        .where((i) =>
            i.isActive &&
            (ConnectionService.transferSupportedBy(i) ||
                (FinancialProviderRegistry.sandboxEnabled &&
                    i.providerSupport['simulation_supported'] == true)))
        .toList();

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
                    savedRecipients:
                        ref.watch(transferRecipientsProvider).valueOrNull ??
                            const [],
                    institutions: catalog,
                    actions: const ServerTransferActions(),
                    onStatusChanged: () => ref.invalidate(accountsProvider),
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
    this.authorize = TransferAuthorization.request,
    this.onStatusChanged,
    this.savedRecipients = const [],
  });

  final List<Account> sources;
  final List<Map<String, dynamic>> savedRecipients;
  final List<Institution> institutions;
  final TransferActions actions;
  final VoidCallback? onStatusChanged;
  final Future<bool> Function(BuildContext) authorize;

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
  String? _requestKey;
  String? _requestIdentity;
  Map<String, dynamic>? _serverRecord;
  String? _ownDestinationId;
  Timer? _pollTimer;
  bool _polling = false;
  String _destinationGroup = 'Bank';
  String _search = '';

  @override
  void initState() {
    super.initState();
    final index = widget.sources.indexWhere((a) => a.isPrimary);
    if (index >= 0) _sourceIndex = index;
  }

  static final _currency =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void dispose() {
    _pollTimer?.cancel();
    _recipientNumber.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Account get _source => widget.sources[_sourceIndex];
  String _idempotency() => List.generate(24,
          (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'))
      .join();

  bool get _numberValid {
    final digits = _recipientNumber.text.replaceAll(RegExp(r'\D'), '');
    return _target?.isEwallet == true
        ? RegExp(r'^08[0-9]{8,13}$').hasMatch(digits)
        : RegExp(r'^[0-9]{6,20}$').hasMatch(digits);
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
    if (amount == null ||
        !amount.isFinite ||
        amount <= 0 ||
        amount > 100000000 ||
        amount != amount.truncateToDouble()) {
      setState(() => _error = 'Masukkan nominal transfer yang valid.');
      return;
    }
    final balance = const BalanceRepository().read(_source);
    if (balance.amount != null &&
        (balance.authoritative || balance.source == BalanceSource.simulated) &&
        amount > balance.amount!) {
      setState(() => _error = 'Saldo tidak mencukupi.');
      return;
    }
    final identity = jsonEncode([
      _source.id,
      _target?.id,
      _recipientNumber.text,
      amount,
      _note.text,
      _ownDestinationId
    ]);
    if (_requestIdentity != identity) {
      _requestIdentity = identity;
      _requestKey = _idempotency();
    }
    _fee = null;
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
        idempotencyKey: _requestKey ??= _idempotency(),
        sourceAccountId: _source.id,
        destinationInstitutionId: target.id,
        destinationAccountId: _ownDestinationId,
        sourceExternalId: _source.externalId ?? _source.id,
        institutionCode: target.code,
        recipientAccountIdentifier: _recipientNumber.text,
        amount: amount,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        currency: 'IDR',
      );

  Future<void> _startTransfer() async {
    if (_starting || _fee == null) return;
    final amount = _amountValue!;
    final balance = const BalanceRepository().read(_source);
    if (balance.amount != null && amount + _fee! > balance.amount!) {
      setState(() => _error = 'Saldo tidak mencukupi.');
      return;
    }
    final target = _target!;
    setState(() {
      _step = _Step.authorizing;
      _starting = true;
    });
    try {
      if (!await widget.authorize(context)) {
        if (mounted) setState(() => _step = _Step.confirm);
        return;
      }
      if (!mounted) return;
      final ref = await widget.actions
          .startTransfer(target: target, request: _request(target, amount));
      if (!mounted) return;
      _serverRecord = ref.record;
      setState(() => _finishWith(ref.status, null, ref.reference));
      if (ref.status.isFinal) widget.onStatusChanged?.call();
      if (!ref.status.isFinal && widget.actions is ServerTransferActions) {
        _pollTimer?.cancel();
        _pollTimer = Timer.periodic(
            const Duration(seconds: 3), (_) => _refreshStatus(ref.reference));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _friendlyError(e);
        _step = _Step.confirm;
      });
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _refreshStatus(String reference) async {
    if (_polling || !mounted) return;
    _polling = true;
    try {
      final adapter =
          FinancialProviderRegistry.adapterFor(_source.provider ?? '');
      if (adapter == null) return;
      final TransferStepStatus status;
      if (adapter is SandboxProviderAdapter) {
        _serverRecord = await adapter.readRecord(reference);
        status = SandboxProviderAdapter.statusFromDb(
            _serverRecord!['status'] as String);
      } else {
        status = await adapter.getTransferStatus(reference);
      }
      if (!mounted) return;
      setState(() => _finishWith(status, null, reference));
      if (status.isFinal) {
        _pollTimer?.cancel();
        widget.onStatusChanged?.call();
      }
    } catch (_) {/* Keep last server status on a network failure. */} finally {
      _polling = false;
    }
  }

  void _finishWith(
      TransferStepStatus status, String? message, String? reference) {
    final normalized = message ?? TransferStatusLabels.subtitle(status);
    final source = _source;
    _result = TransferRecord(
      reference: reference ?? 'nus-${DateTime.now().millisecondsSinceEpoch}',
      provider: _source.provider ?? 'belum terhubung',
      executionMode: _source.provider == 'nusarta_simulator'
          ? 'SANDBOX_SIMULATED_SOURCE'
          : 'UNVERIFIED',
      sourceAccountName: source.displayName ?? source.name,
      sourceMasked: source.maskedAccountNumber ??
          (source.lastFour == null ? '•••• ••••' : '•••• ${source.lastFour}'),
      sourceInstitutionName: source.name,
      recipientInstitutionName: _target?.name ?? '',
      recipientInstitutionCode: _target?.code ?? '',
      recipientMasked:
          '•••• ${_recipientNumber.text.replaceAll(RegExp(r'\D'), '').isNotEmpty ? _recipientNumber.text.replaceAll(RegExp(r'\D'), '').substring(max(0, _recipientNumber.text.replaceAll(RegExp(r'\D'), '').length - 4)) : '••••'}',
      recipientName: _validation?.displayName,
      amount:
          (_serverRecord?['amount'] as num?)?.toDouble() ?? _amountValue ?? 0,
      fee: (_serverRecord?['fee_amount'] as num?)?.toDouble() ?? _fee ?? 0,
      status: status,
      occurredAt: DateTime.tryParse(_serverRecord?['completed_at'] as String? ??
              _serverRecord?['created_at'] as String? ??
              '') ??
          DateTime.now(),
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
      _pollTimer?.cancel();
      _requestKey = null;
      _requestIdentity = null;
      _serverRecord = null;
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
        if (_step != _Step.source && _step != _Step.authorizing)
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SourceTile(
                  account: _source, selected: true, onTap: _pickSource)),
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

  Future<void> _pickSource() async {
    final index = await showModalBottomSheet<int>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
                child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(16),
                    children: [
                  const Text('Pilih Akun Sumber',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  for (final type in [
                    AccountType.bank,
                    AccountType.ewallet
                  ]) ...[
                    Text(type == AccountType.bank ? 'BANK' : 'E-WALLET'),
                    for (var i = 0; i < widget.sources.length; i++)
                      if (widget.sources[i].type == type)
                        _SourceTile(
                            account: widget.sources[i],
                            selected: i == _sourceIndex,
                            onTap: () => Navigator.pop(context, i)),
                  ],
                ])));
    if (index != null && mounted) {
      setState(() {
        _sourceIndex = index;
        _fee = null;
        _ownDestinationId = null;
        _step = _Step.recipient;
      });
    }
  }

  Widget _sourceStep() => ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Text('Hanya akun terhubung yang ditampilkan sebagai sumber.',
              style: TextStyle(color: AppColors.neutral, fontSize: 13)),
          const SizedBox(height: 10),
          for (var i = 0; i < widget.sources.length; i++) ...[
            if (i == 0 || widget.sources[i].type != widget.sources[i - 1].type)
              Text(widget.sources[i].type == AccountType.bank
                  ? 'BANK'
                  : 'E-WALLET'),
            _SourceTile(
              account: widget.sources[i],
              selected: i == _sourceIndex,
              onTap: () => setState(() {
                _sourceIndex = i;
                _fee = null;
                _ownDestinationId = null;
              }),
            ),
          ],
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
          Wrap(spacing: 8, children: [
            for (final group in [
              'Akun Saya',
              'Penerima Tersimpan',
              'Bank',
              'E-Wallet'
            ])
              ChoiceChip(
                  label: Text(group),
                  selected: _destinationGroup == group,
                  onSelected: (_) => setState(() => _destinationGroup = group))
          ]),
          TextField(
              decoration:
                  const InputDecoration(hintText: 'Cari bank atau e-wallet'),
              onChanged: (value) =>
                  setState(() => _search = value.toLowerCase())),
          if (_destinationGroup == 'Penerima Tersimpan') ...[
            if (widget.savedRecipients.isEmpty)
              const Text('Belum ada penerima tersimpan.'),
            for (final recipient in widget.savedRecipients)
              ListTile(
                  title: Text(recipient['display_name'] as String),
                  subtitle: Text(
                      recipient['account_reference_masked'] as String? ??
                          '••••'),
                  onTap: () {
                    final targets = widget.institutions
                        .where((i) => i.id == recipient['institution_id']);
                    if (targets.isEmpty) return;
                    setState(() {
                      _target = targets.first;
                      _ownDestinationId = null;
                      _recipientNumber.clear();
                      _validation = null;
                    });
                  }),
            const Text(
                'Masukkan ulang nomor lengkap. Nomor tersimpan hanya tersedia dalam bentuk tersamarkan.'),
          ],
          if (_destinationGroup == 'Akun Saya')
            for (final account
                in widget.sources.where((a) => a.id != _source.id))
              ListTile(
                  title: Text(account.name),
                  subtitle: Text(account.maskedAccountNumber ?? '••••'),
                  onTap: () {
                    final targets = widget.institutions
                        .where((i) => i.id == account.institutionId);
                    if (targets.isEmpty || account.externalId == null) return;
                    setState(() {
                      _target = targets.first;
                      _ownDestinationId = account.id;
                      _recipientNumber.text = account.externalId!;
                    });
                  }),
          for (final institution in widget.institutions)
            if (((_destinationGroup == 'Bank' && institution.isBank) ||
                    (_destinationGroup == 'E-Wallet' &&
                        institution.isEwallet)) &&
                institution.name.toLowerCase().contains(_search))
              _TargetTile(
                institution: institution,
                selected: _target?.code == institution.code,
                onTap: () => setState(() {
                  _target = institution;
                  _validation = null;
                  _ownDestinationId = null;
                }),
              ),
          const SizedBox(height: 14),
          TextField(
            key: const Key('transfer-recipient'),
            controller: _recipientNumber,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Nomor rekening / wallet',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {
              _validation = null;
              _ownDestinationId = null;
            }),
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
              'Validasi nama penerima belum tersedia. Periksa nomor tujuan. ',
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
                  '${maskAccountIdentifier(_recipientNumber.text)}'),
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
          'Otorisasi menggunakan PIN atau biometrik NUSARTA. Jangan masukkan PIN bank atau e-wallet.',
          style:
              TextStyle(color: AppColors.neutral, fontSize: 12.5, height: 1.5),
        ),
        if (_error != null) _ErrorText(_error!),
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
              onPressed: _starting || _fee == null ? null : _startTransfer,
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
          const Text('Verifikasi otorisasi NUSARTA',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            'Gunakan PIN atau biometrik NUSARTA. Credential bank tidak diminta.',
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
        key: ValueKey('source-${account.id}'),
        margin: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              InstitutionLogo(
                  code: account.name,
                  name: account.displayName ?? account.name,
                  size: 40),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(account.displayName ?? account.name,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    if (account.accountHolderName != null)
                      Text(account.accountHolderName!,
                          style: const TextStyle(fontSize: 12)),
                    if (account.isPrimary) const Text('Utama'),
                    Text(const BalanceRepository().read(account).amount == null
                        ? 'Saldo tidak tersedia'
                        : 'Saldo ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(account.balance)}'),
                    if (account.balanceSource == 'simulated')
                      const Text('SANDBOX · Simulasi',
                          style: TextStyle(fontSize: 11)),
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
