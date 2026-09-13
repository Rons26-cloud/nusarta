/// Original raster assets from institution websites; see assets/institutions/SOURCES.md.
class InstitutionLogoRegistry {
  const InstitutionLogoRegistry._();

  static const Map<String, String> _assets = {
    'BCA': 'assets/institutions/banks/bca_mark.png',
    'MANDIRI': 'assets/institutions/banks/mandiri.png',
    'SEABANK': 'assets/institutions/banks/seabank.png',
    'HSBC': 'assets/institutions/banks/hsbc.png',
    'MAYBANK': 'assets/institutions/banks/maybank.png',
    'GOPAY': 'assets/institutions/ewallets/gopay_mark.png',
    'OVO': 'assets/institutions/ewallets/ovo.png',
    'LINKAJA': 'assets/institutions/ewallets/linkaja.png',
    'DOKU': 'assets/institutions/ewallets/doku.png',
    'ASTRAPAY': 'assets/institutions/ewallets/astrapay.png',
  };

  static String _key(String code) =>
      code.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  static String? assetPathFor(String code) => _assets[_key(code)];

  static bool hasOfficialAsset(String code) => assetPathFor(code) != null;

  // Official white wordmarks need a dark backing, independent of app brightness.
  static bool usesWhiteWordmark(String code) =>
      const {'OVO', 'ASTRAPAY'}.contains(_key(code));

  static List<String> missing(Iterable<String> codes) => codes
      .where((code) => !hasOfficialAsset(code))
      .map((code) => code.toUpperCase())
      .toList(growable: false);
}
