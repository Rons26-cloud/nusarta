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

  static void log(String message) {
    if (kDebugMode) debugPrint('STARTUP: $message');
  }

  static Future<void> initialize() async {
    if (_initialized) return;
    if (AppConfig.isConfigured) {
      try {
        log('Supabase initialization started host=${Uri.tryParse(AppConfig.supabaseUrl)?.host ?? '-'} keyConfigured=${AppConfig.supabaseAnonKey.isNotEmpty}');
        await Supabase.initialize(
          url: AppConfig.supabaseUrl,
          publishableKey: AppConfig.supabaseAnonKey,
        );
        _initialized = true;
        _initializationError = null;
        log('Supabase initialization complete');
      } catch (error) {
        _initializationError = error;
        if (kDebugMode) {
          debugPrint('STARTUP FAILED AT: supabase initialization');
        }
        rethrow;
      }
    } else if (kDebugMode) {
      debugPrint('STARTUP FAILED AT: public client configuration missing');
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
}
