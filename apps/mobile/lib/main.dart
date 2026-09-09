import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/data/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await SupabaseConfig.initialize().timeout(const Duration(seconds: 10));
  } catch (_) {
    debugPrint('Supabase initialization failed');
  }
  runApp(const ProviderScope(child: NusartaApp()));
}
