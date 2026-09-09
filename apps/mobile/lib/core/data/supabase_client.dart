import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

/// Global Supabase client.
/// Initialized in `main()`. Uses the ANON key only — never the
/// service_role key in the client.
class SupabaseConfig {
  SupabaseConfig._();

  static bool _initialized = false;
  static Object? _initializationError;

  static bool get isInitialized => _initialized;
  static Object? get initializationError => _initializationError;

  static Future<void> initialize() async {
    if (AppConfig.isConfigured) {
      try {
        await Supabase.initialize(
          url: AppConfig.supabaseUrl,
          publishableKey: AppConfig.supabaseAnonKey,
        );
        _initialized = true;
        _initializationError = null;
      } catch (error) {
        _initializationError = error;
        rethrow;
      }
    } else if (kDebugMode) {
      debugPrint(
        'AppConfig: SUPABASE_URL / SUPABASE_ANON_KEY not set. '
        'Copy app_config.example.dart to app_config.dart.',
      );
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
}
