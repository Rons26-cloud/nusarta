// Institution catalog: metadata only; provider support is tracked separately.
class Institution {
  final String id;
  final String code;
  final String name;
  final String institutionType;
  final String? logoUrl;
  final String country;
  final bool isActive;
  final Map<String, dynamic> providerSupport;

  const Institution({
    required this.id,
    required this.code,
    required this.name,
    required this.institutionType,
    this.logoUrl,
    this.country = 'ID',
    this.isActive = true,
    this.providerSupport = const {},
  });

  /// Whether an official provider integration is claimed for this institution.
  bool get hasProviderIntegration =>
      (providerSupport['integration_available'] as bool?) ?? false;

  bool get isBank => institutionType == 'bank';
  bool get isEwallet => institutionType == 'ewallet';

  factory Institution.fromMap(Map<String, dynamic> map) => Institution(
        id: map['id'] as String,
        code: map['code'] as String,
        name: map['name'] as String,
        institutionType: map['institution_type'] as String? ?? 'other',
        logoUrl: map['logo_url'] as String?,
        country: map['country'] as String? ?? 'ID',
        isActive: map['is_active'] as bool? ?? true,
        providerSupport:
            (map['provider_support'] as Map?)?.cast<String, dynamic>() ??
                const {},
      );

  Map<String, dynamic> toMap() => {
        'code': code,
        'name': name,
        'institution_type': institutionType,
        'logo_url': logoUrl,
        'country': country,
        'is_active': isActive,
        'provider_support': providerSupport,
      };
}
