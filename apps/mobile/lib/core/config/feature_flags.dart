// Feature flags: keep mobile, web, and database defaults aligned.
// Only the informational catalog is enabled; future integrations stay OFF.
library;

enum FeatureFlag {
  linkedAccounts,
  bankSync,
  ewalletSync,
  transfers,
  transferRecipientValidation,
  pushNotifications,
  institutionCatalog,
}

class FeatureFlags {
  const FeatureFlags._();

  static const FeatureFlags instance = FeatureFlags._();

  static const Map<FeatureFlag, bool> _defaults = {
    FeatureFlag.linkedAccounts: false,
    FeatureFlag.bankSync: false,
    FeatureFlag.ewalletSync: false,
    FeatureFlag.transfers: false,
    FeatureFlag.transferRecipientValidation: false,
    FeatureFlag.pushNotifications: false,
    FeatureFlag.institutionCatalog: true,
  };

  static bool isEnabled(FeatureFlag flag, {Map<FeatureFlag, bool>? overrides}) {
    if (overrides != null && overrides.containsKey(flag)) {
      return overrides[flag]!;
    }
    return _defaults[flag] ?? false;
  }

  static bool get linkedAccountsEnabled =>
      isEnabled(FeatureFlag.linkedAccounts);
  static bool get transferEnabled => isEnabled(FeatureFlag.transfers);
}
