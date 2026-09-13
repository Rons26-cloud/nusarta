import 'financial_provider_adapter.dart';

/// Registry of server-backed provider adapters.
///
/// Deliberately empty: adapters are registered only when an official
/// provider integration is live (license, OAuth/open-finance/SDK). The
/// registry is the single place the app learns whether a real capability
/// exists, so the UI can never display a fake "Terhubung".
class FinancialProviderRegistry {
  const FinancialProviderRegistry._();

  static const _adapters = <FinancialProviderAdapter>{};

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
