/// Financial provider adapter boundary.
///
/// Every real financial integration flows through a server-side provider
/// adapter (Flutter -> NUSARTA API/Edge Function -> Provider Adapter ->
/// official provider). Provider secrets never reach the mobile client. The
/// mobile app only talks to this capability contract.
///
/// IMPORTANT: No adapter is registered until an official provider
/// integration is actually available. Until then every capability returns
/// "not available", which is the truthful state — never a fake success.
library;

import '../../data/models/institution.dart';

enum FinancialCapability {
  linkAccounts,
  syncAccounts,
  syncTransactions,
  validateRecipient,
  createTransfer,
  getTransferStatus,
}

class FinancialProviderCapabilities {
  const FinancialProviderCapabilities(this.supported);
  final Set<FinancialCapability> supported;

  bool get linkSupported =>
      supported.contains(FinancialCapability.linkAccounts);
  bool get syncAccountsSupported =>
      supported.contains(FinancialCapability.syncAccounts);
  bool get syncTransactionsSupported =>
      supported.contains(FinancialCapability.syncTransactions);
  bool get recipientValidationSupported =>
      supported.contains(FinancialCapability.validateRecipient);
  bool get transferSupported =>
      supported.contains(FinancialCapability.createTransfer);
}

enum ConnectionRequestStatus { pending, active, expired, failed }

class ConnectionRequest {
  const ConnectionRequest({
    required this.providerConnectionId,
    required this.authorizationUrl,
    required this.status,
    this.consentExpiresAt,
  });
  final String providerConnectionId;
  final Uri authorizationUrl;
  final ConnectionRequestStatus status;
  final DateTime? consentExpiresAt;
}

class LinkedAccountInfo {
  const LinkedAccountInfo({
    required this.externalId,
    this.displayName,
    this.maskedAccountNumber,
    this.accountHolder,
    this.balance,
    required this.currency,
  });
  final String externalId;
  final String? displayName;
  final String? maskedAccountNumber;
  final String? accountHolder;
  final double? balance;
  final String currency;
}

enum SyncStatus { syncing, success, failed }

class SyncResult {
  const SyncResult({
    this.status = SyncStatus.success,
    this.added = 0,
    this.skipped = 0,
    this.errorCode,
  });
  final SyncStatus status;
  final int added;
  final int skipped;
  final String? errorCode;
  bool get ok => status == SyncStatus.success;
}

class RecipientValidation {
  const RecipientValidation(
      {required this.valid, this.displayName, this.errorCode});
  final bool valid;
  final String? displayName;
  final String? errorCode;
}

/// Provider-backed transfer attempt. Created server-side only; the client
/// never holds credentials, so it can never fake a transfer.
class TransferRequest {
  const TransferRequest({
    required this.idempotencyKey,
    required this.sourceExternalId,
    required this.institutionCode,
    required this.recipientAccountIdentifier,
    required this.amount,
    this.note,
    required this.currency,
  });
  final String idempotencyKey;
  final String sourceExternalId;
  final String institutionCode;
  final String recipientAccountIdentifier;
  final double amount;
  final String? note;
  final String currency;
}

class TransferQuote {
  const TransferQuote({required this.fee});
  final double fee;
}

enum TransferStepStatus {
  authorized,
  processing,
  success,
  failed,
  expired,
  cancelled,
  unknown;

  bool get isFinal =>
      this == success || this == failed || this == expired || this == cancelled;
}

class TransferReferenceResult {
  const TransferReferenceResult(
      {required this.reference, required this.status});
  final String reference;
  final TransferStepStatus status;
}

enum TransferOutcome { pending, success, failed }

class TransferResult {
  const TransferResult({
    required this.outcome,
    this.providerReference,
    this.failureCode,
    this.failureMessage,
  });
  final TransferOutcome outcome;
  final String? providerReference;
  final String? failureCode;
  final String? failureMessage;
}

class ProviderCapabilityException implements Exception {
  const ProviderCapabilityException(this.capability, this.message);
  final FinancialCapability capability;
  final String message;

  @override
  String toString() => message;
}

abstract class FinancialProviderAdapter {
  const FinancialProviderAdapter();

  /// Stable provider identifier, e.g. `midtrans` or `open_finance`.
  String get providerId;

  /// Official provider name shown only after a real integration is connected.
  String get providerName;

  FinancialProviderCapabilities get capabilities;

  /// Starts the official authorization flow. The returned URL is opened in
  /// the user's browser/OS and the callback is handled server-side.
  Future<ConnectionRequest> linkAccount(Institution institution);

  Future<void> refreshConnection(String providerConnectionId);

  Future<List<LinkedAccountInfo>> syncAccounts(String providerConnectionId);

  /// Upserts normalized transactions idempotently; de-duplication is by
  /// `provider_transaction_id` per account.
  Future<SyncResult> syncTransactions(String providerConnectionId);

  Future<void> disconnect(String providerConnectionId);

  /// Resolves a recipient account name with the institution/provider. When
  /// unsupported, the result is `valid=false` with a safe error code.
  Future<RecipientValidation> validateRecipient(
      int? userId, String institutionCode, String accountIdentifier);

  /// Provider quote for a transfer (admin fee and/or rate). Throws
  /// [ProviderCapabilityException] when the provider cannot quote.
  Future<TransferQuote> getTransferQuote(TransferRequest request);

  /// Server-side transfer initiation. Returns a reference the client polled
  /// by [getTransferStatus]; the provider owns the actual movement of funds.
  Future<TransferReferenceResult> createTransfer(TransferRequest request);

  Future<TransferStepStatus> getTransferStatus(String reference);
}
