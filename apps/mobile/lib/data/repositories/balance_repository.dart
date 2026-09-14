import '../models/account.dart';

enum BalanceSource { live, sandbox, simulated, unavailable }

class AccountBalance {
  const AccountBalance(this.account, this.source, this.amount);
  final Account account;
  final BalanceSource source;
  final double? amount;
  bool get authoritative => source == BalanceSource.live && amount != null;
  String get label => switch (source) {
        BalanceSource.live => 'Saldo provider',
        BalanceSource.sandbox => 'SANDBOX',
        BalanceSource.simulated => 'SIMULASI',
        BalanceSource.unavailable => 'Saldo tidak tersedia',
      };
}

/// Server-owned provenance: manual ledger balances are never bank funds.
class BalanceRepository {
  const BalanceRepository();
  AccountBalance read(Account account) {
    final source = switch (account.balanceSource) {
      'live' || 'provider' => BalanceSource.live,
      'sandbox' => BalanceSource.sandbox,
      'simulated' => BalanceSource.simulated,
      _ => BalanceSource.unavailable,
    };
    final available = account.isConnected &&
        account.lastSyncedAt != null &&
        account.currencyCode == 'IDR' &&
        account.balance.isFinite &&
        source != BalanceSource.unavailable;
    return AccountBalance(
        account,
        available ? source : BalanceSource.unavailable,
        available ? account.balance : null);
  }

  List<AccountBalance> connected(Iterable<Account> accounts,
          {String? userId}) =>
      accounts
          .where((a) => a.isConnected && (userId == null || a.userId == userId))
          .map(read)
          .toList(growable: false);

  double total(Iterable<Account> accounts, {String? userId}) =>
      connected(accounts, userId: userId)
          .fold(0, (sum, item) => sum + (item.amount ?? 0));
}

String maskAccountIdentifier(String value) {
  final clean = value.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  if (clean.length <= 4) return '••••';
  return '•••• ${clean.substring(clean.length - 4)}';
}
