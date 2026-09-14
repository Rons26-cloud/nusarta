import '../../core/data/supabase_client.dart';
import '../../data/models/institution.dart';
import 'financial_provider_adapter.dart';

/// NUSARTA simulator: zero provider API calls, no real balance or debit.
class SandboxProviderAdapter extends FinancialProviderAdapter {
  const SandboxProviderAdapter();
  static const executionMode = 'SANDBOX_SIMULATED_SOURCE';
  @override
  String get providerId => 'nusarta_simulator';
  @override
  String get providerName => 'NUSARTA Sandbox Simulator';
  @override
  FinancialProviderCapabilities get capabilities =>
      const FinancialProviderCapabilities({
        FinancialCapability.createTransfer,
        FinancialCapability.getTransferStatus
      });
  @override
  Future<TransferQuote> getTransferQuote(TransferRequest request) async =>
      const TransferQuote(fee: 0);
  @override
  Future<TransferReferenceResult> createTransfer(
      TransferRequest request) async {
    final response = await SupabaseConfig.client.functions
        .invoke('brankas-disburse', headers: {
      'x-nusarta-request-key': request.idempotencyKey
    }, body: {
      'execution_mode': executionMode,
      'source_account_id': request.sourceAccountId,
      'destination_institution_id': request.destinationInstitutionId,
      'destination_identifier': request.recipientAccountIdentifier,
      'amount': request.amount,
      'destination_account_id': request.destinationAccountId,
      'note': request.note,
    });
    final row = Map<String, dynamic>.from(response.data['transfer'] as Map);
    return TransferReferenceResult(
        reference: row['id'] as String,
        record: row,
        status: statusFromDb(row['status'] as String));
  }

  static TransferStepStatus statusFromDb(String status) => switch (status) {
        'success' => TransferStepStatus.success,
        'failed' => TransferStepStatus.failed,
        'reversed' => TransferStepStatus.reversed,
        'cancelled' => TransferStepStatus.cancelled,
        'pending' || 'processing' || 'draft' => TransferStepStatus.processing,
        _ => TransferStepStatus.unknown,
      };
  Future<Map<String, dynamic>> readRecord(String reference) async =>
      await SupabaseConfig.client
          .from('future_transfers')
          .select()
          .eq('id', reference)
          .single();

  @override
  Future<TransferStepStatus> getTransferStatus(String reference) async {
    final row = await SupabaseConfig.client
        .from('future_transfers')
        .select('status')
        .eq('id', reference)
        .single();
    return statusFromDb(row['status'] as String);
  }

  @override
  Future<ConnectionRequest> linkAccount(Institution institution) =>
      throw UnsupportedError('Gunakan koneksi simulasi eksplisit.');
  @override
  Future<void> refreshConnection(String providerConnectionId) =>
      throw UnsupportedError('Saldo live belum tersedia.');
  @override
  Future<List<LinkedAccountInfo>> syncAccounts(String providerConnectionId) =>
      throw UnsupportedError('Saldo live belum tersedia.');
  @override
  Future<SyncResult> syncTransactions(String providerConnectionId) =>
      throw UnsupportedError('Sinkronisasi live belum tersedia.');
  @override
  Future<void> disconnect(String providerConnectionId) =>
      throw UnsupportedError('Koneksi live belum tersedia.');
  @override
  Future<RecipientValidation> validateRecipient(int? userId,
          String institutionCode, String accountIdentifier) async =>
      const RecipientValidation(valid: false, errorCode: 'inquiry_unavailable');
}
