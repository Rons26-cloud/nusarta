import '../../data/models/account.dart';
import '../../data/models/device.dart';
import '../../data/models/notification.dart';
import '../../data/models/transaction.dart';

/// Human-readable Indonesian labels used across the app.
String accountTypeLabel(AccountType type) => switch (type) {
      AccountType.cash => 'Kas',
      AccountType.bank => 'Bank',
      AccountType.ewallet => 'E-Wallet',
      AccountType.custom => 'Lainnya',
    };

String transactionKindLabel(TransactionKind kind) => switch (kind) {
      TransactionKind.income => 'Pemasukan',
      TransactionKind.expense => 'Pengeluaran',
      TransactionKind.transfer => 'Pindah Saldo',
    };

String institutionTypeLabel(String type) => switch (type) {
      'bank' => 'Bank',
      'ewallet' => 'E-Wallet',
      'cash' => 'Kas/Tunai',
      _ => 'Lainnya',
    };

String devicePlatformLabel(DevicePlatform platform) => switch (platform) {
      DevicePlatform.android => 'Android',
      DevicePlatform.ios => 'iOS',
      DevicePlatform.web => 'Web',
      DevicePlatform.other => 'Perangkat lain',
    };

String notificationTypeLabel(AppNotificationType type) => switch (type) {
      AppNotificationType.transaction => 'Transaksi',
      AppNotificationType.budget => 'Budget',
      AppNotificationType.security => 'Keamanan',
      AppNotificationType.accountConnection => 'Koneksi Akun',
      AppNotificationType.transfer => 'Transfer',
      AppNotificationType.system => 'Sistem',
    };
