import '../../data/models/institution.dart';
import 'financial_provider_adapter.dart';
import 'provider_registry.dart';

/// Client-side entry point for linked finance.
///
/// Real financial operations always run server-side through a provider
/// adapter. If no official provider is registered, every operation reports
/// the truth: capability unavailable. Nothing here creates fake balances,
/// fake connections, or fake transfer success.
class ConnectionService {
  const ConnectionService._();

  static bool get hasLiveProvider => FinancialProviderRegistry.adapters
      .any((a) => a.providerId != 'nusarta_simulator');

  static bool canLink(Institution institution) {
    final adapter =
        FinancialProviderRegistry.adapterFor(institution.provider ?? '');
    if (adapter == null) return false;
    return adapter.capabilities.linkSupported &&
        institution.status == InstitutionStatus.available;
  }

  static bool canSync(Institution institution) {
    final adapter =
        FinancialProviderRegistry.adapterFor(institution.provider ?? '');
    if (adapter == null) return false;
    return adapter.capabilities.syncTransactionsSupported;
  }

  static FinancialProviderAdapter? _adapterFor(Institution institution) {
    if (FinancialProviderRegistry.sandboxEnabled &&
        institution.providerSupport['simulation_supported'] == true) {
      return FinancialProviderRegistry.adapterFor('nusarta_simulator');
    }
    if (institution.provider == null) return null;
    return FinancialProviderRegistry.adapterFor(institution.provider!);
  }

  static UnsupportedError _unavailable(Institution institution) {
    return UnsupportedError(
        '${institution.name} belum memiliki koneksi resmi. Status saat ini: '
        '${_statusLabel(institution.status)}.');
  }

  static Future<ConnectionRequest> startLink(Institution institution) async {
    final adapter = _adapterFor(institution);
    if (adapter == null) throw _unavailable(institution);
    return adapter.linkAccount(institution);
  }

  static Future<SyncResult> requestSync(Institution institution) async {
    final adapter = _adapterFor(institution);
    if (adapter == null) throw _unavailable(institution);
    throw const ProviderCapabilityException(
        FinancialCapability.syncTransactions,
        'Sinkronisasi transaksi aktifkan hanya saat provider resmi terhubung.');
  }

  /// True for any institution whose provider hosts transfer readiness. The
  /// UI must mirror a provider's real capability, never a claim.
  static bool transferSupportedBy(Institution institution) {
    final adapter = _adapterFor(institution);
    if (adapter == null) return false;
    return adapter.capabilities.transferSupported &&
        institution.transferSupported;
  }

  static Future<RecipientValidation> validateRecipient(
      {int? userId,
      required Institution target,
      required String accountIdentifier}) async {
    final adapter = _adapterFor(target);
    if (adapter == null) throw _unavailable(target);
    if (!adapter.capabilities.recipientValidationSupported) {
      throw const ProviderCapabilityException(
          FinancialCapability.validateRecipient,
          'Institusi tidak mendukung validasi penerima.');
    }
    return adapter.validateRecipient(userId, target.code, accountIdentifier);
  }

  static Future<TransferQuote> getTransferQuote(
      {required Institution target, required TransferRequest request}) async {
    final adapter = _adapterFor(target);
    if (adapter == null) throw _unavailable(target);
    if (!adapter.capabilities.transferSupported) {
      throw const ProviderCapabilityException(
          FinancialCapability.createTransfer,
          'Transfer belum didukung untuk institusi ini.');
    }
    return adapter.getTransferQuote(request);
  }

  /// Creates a transfer after NUSARTA app authorization. Provider credentials
  /// are never collected by this app. Backend enforces its own authorization.
  static Future<TransferReferenceResult> startTransfer(
      {int? userId,
      required Institution target,
      required TransferRequest request}) async {
    final adapter = _adapterFor(target);
    if (adapter == null) throw _unavailable(target);
    if (!adapter.capabilities.transferSupported) {
      throw const ProviderCapabilityException(
          FinancialCapability.createTransfer,
          'Transfer belum didukung untuk institusi ini.');
    }
    return adapter.createTransfer(request);
  }

  static String _statusLabel(InstitutionStatus status) => switch (status) {
        InstitutionStatus.available => 'tersedia',
        InstitutionStatus.maintenance => 'pemeliharaan',
        InstitutionStatus.unsupported => 'tidak didukung',
        InstitutionStatus.comingSoon => 'segera hadir',
      };
}
