import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('STARTUP_1_MAIN');
  // Start decoding the first screen immediately, without holding runApp or
  // waiting for backend/security initialization.
  final splash = const AssetImage('assets/brand/splash_screen.png')
      .resolve(ImageConfiguration.empty);
  late final ImageStreamListener splashListener;
  splashListener = ImageStreamListener(
    (_, __) => splash.removeListener(splashListener),
    onError: (Object error, StackTrace? stack) =>
        splash.removeListener(splashListener),
  );
  splash.addListener(splashListener);
  // Render the branded splash immediately; startup is coordinated by SplashPage.
  runApp(const ProviderScope(child: NusartaApp()));
  debugPrint('STARTUP_2_RUNAPP');
}
