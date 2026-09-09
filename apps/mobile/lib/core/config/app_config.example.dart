/// Copy to app_config.dart; supply public config through --dart-define.
library;

class AppConfig {
  AppConfig._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  static const String appName = 'NUSARTA';
  static const String tagline = 'Keuanganmu, Dalam Kendalimu.';
  static const String version = '1.0.0';
  static const String buildNumber = '1';

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
