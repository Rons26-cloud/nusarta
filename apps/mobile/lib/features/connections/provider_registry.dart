import 'package:flutter/foundation.dart';

import 'financial_provider_adapter.dart';
import 'sandbox_provider_adapter.dart';

/// Registry of server-backed provider adapters.
///
/// Live adapters stay absent until verified. An explicit debug-only flag
/// registers the NUSARTA simulator; that adapter never claims live bank
/// access. Institution branding alone never enables transfer capabilities.
class FinancialProviderRegistry {
  const FinancialProviderRegistry._();

  static const sandboxEnabled =
      kDebugMode && bool.fromEnvironment('NUSARTA_SANDBOX');
  static const _adapters = <FinancialProviderAdapter>{
    if (sandboxEnabled) SandboxProviderAdapter(),
  };

  static bool get hasAnyProvider => _adapters.isNotEmpty;

  static FinancialProviderAdapter? adapterFor(String providerId) {
    for (final adapter in _adapters) {
      if (adapter.providerId == providerId) return adapter;
    }
    return null;
  }

  static List<FinancialProviderAdapter> get adapters =>
      _adapters.toList(growable: false);

  static UnsupportedError get noneAvailable =>
      UnsupportedError('Provider keuangan resmi belum tersedia.');
}
