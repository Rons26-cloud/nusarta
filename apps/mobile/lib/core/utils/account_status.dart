import '../../data/models/account.dart';

enum AccountBadgeState { manual, connected, pending, needsAttention, revoked }

AccountBadgeState badgeStateFor(Account account) {
  if (account.connectionStatus == ConnectionStatus.active &&
      account.connectionType != ConnectionType.manual) {
    return AccountBadgeState.connected;
  }
  return switch (account.connectionStatus) {
    ConnectionStatus.manual => AccountBadgeState.manual,
    ConnectionStatus.pending => AccountBadgeState.pending,
    ConnectionStatus.expired ||
    ConnectionStatus.error =>
      AccountBadgeState.needsAttention,
    ConnectionStatus.revoked ||
    ConnectionStatus.disconnected =>
      AccountBadgeState.revoked,
    ConnectionStatus.active => AccountBadgeState.manual,
  };
}

String badgeLabelFor(AccountBadgeState state) => switch (state) {
      AccountBadgeState.manual => 'Manual',
      AccountBadgeState.connected => 'Terhubung',
      AccountBadgeState.pending => 'Menunggu',
      AccountBadgeState.needsAttention => 'Perlu Perhatian',
      AccountBadgeState.revoked => 'Dicabut',
    };

String connectionStatusDescription(Account account) {
  if (account.connectionType == ConnectionType.manual) {
    return 'Akun dicatat secara manual. Belum terhubung ke bank/e-wallet.';
  }
  return switch (account.connectionStatus) {
    ConnectionStatus.manual => 'Status koneksi belum dibuat.',
    ConnectionStatus.pending => 'Koneksi sedang menunggu otorisasi.',
    ConnectionStatus.active => 'Koneksi aktif dan sinkron.',
    ConnectionStatus.error => 'Terjadi kesalahan pada koneksi.',
    ConnectionStatus.expired => 'Izin koneksi telah kedaluwarsa.',
    ConnectionStatus.revoked => 'Koneksi telah dicabut.',
    ConnectionStatus.disconnected => 'Koneksi terputus.',
  };
}
