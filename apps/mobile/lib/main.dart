import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('STARTUP_1_MAIN');
  // Render the branded splash immediately; startup is coordinated by SplashPage.
  runApp(const ProviderScope(child: NusartaApp()));
  debugPrint('STARTUP_2_RUNAPP');
}
