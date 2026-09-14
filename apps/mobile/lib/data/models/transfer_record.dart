import '../../features/connections/financial_provider_adapter.dart';

/// A verified transfer outcome owned by the server/provider. Values here are
/// never taken from the input form: the receipt only shows a SUCCESS once the
/// provider confirms it.
class TransferRecord {
  const TransferRecord({
    required this.reference,
    required this.provider,
    required this.sourceAccountName,
    required this.sourceMasked,
    required this.sourceInstitutionName,
    required this.recipientInstitutionName,
    required this.recipientInstitutionCode,
    required this.recipientMasked,
    this.recipientName,
    required this.amount,
    required this.fee,
    required this.status,
    required this.occurredAt,
    this.message,
    this.currency = 'IDR',
    this.executionMode = 'UNVERIFIED',
  });

  final String executionMode;
  bool get isSimulation => executionMode == 'SANDBOX_SIMULATED_SOURCE';
  final String reference;
  final String provider;
  final String sourceAccountName;
  final String sourceMasked;
  final String sourceInstitutionName;
  final String recipientInstitutionName;
  final String recipientInstitutionCode;
  final String recipientMasked;
  final String? recipientName;
  final double amount;
  final double fee;
  final TransferStepStatus status;
  final DateTime occurredAt;
  final String? message;
  final String currency;

  double get total => amount + fee;

  bool get isSuccess => status == TransferStepStatus.success;
}

/// Maps a provider step status to the user-facing copy used by the receipt.
class TransferStatusLabels {
  const TransferStatusLabels._();

  static String title(TransferStepStatus status) => switch (status) {
        TransferStepStatus.success => 'Transfer Berhasil',
        TransferStepStatus.reversed => 'Transfer Dikembalikan',
        TransferStepStatus.processing => 'Transfer sedang diproses',
        TransferStepStatus.authorized => 'Transfer berhasil diotorisasi',
        TransferStepStatus.failed => 'Transfer tidak berhasil',
        TransferStepStatus.cancelled => 'Otorisasi dibatalkan',
        TransferStepStatus.expired => 'Otorisasi kedaluwarsa',
        TransferStepStatus.unknown => 'Status transaksi sedang diperiksa',
      };

  static String subtitle(TransferStepStatus status) => switch (status) {
        TransferStepStatus.success =>
          'Dana diproses melalui penyedia jasa resmi.',
        TransferStepStatus.reversed => 'Dana dikembalikan ke akun sumber.',
        TransferStepStatus.processing =>
          'Penyedia sedang memproses transaksi ini.',
        TransferStepStatus.authorized => 'Menunggu pemrosesan dari penyedia.',
        TransferStepStatus.failed => 'Transfer tidak dapat diselesaikan.',
        TransferStepStatus.cancelled =>
          'Verifikasi keamanan tidak diselesaikan.',
        TransferStepStatus.expired => 'Sesi otorisasi telah berakhir.',
        TransferStepStatus.unknown =>
          'Informasi status belum tersedia dari penyedia.',
      };
}
