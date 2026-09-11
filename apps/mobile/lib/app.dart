import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/data/supabase_client.dart';
import 'core/router/app_router.dart';
import 'core/security/auto_lock_service.dart';
import 'core/security/pin_service.dart';
import 'core/security/secure_store.dart';
import 'core/theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/update_provider.dart';

class NusartaApp extends ConsumerStatefulWidget {
  const NusartaApp({super.key});

  @override
  ConsumerState<NusartaApp> createState() => _NusartaAppState();
}

class _NusartaAppState extends ConsumerState<NusartaApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(seconds: 2), () {
        if (mounted) ref.read(updateControllerProvider).check();
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Apply immediate auto-lock on resume.
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!SupabaseConfig.isInitialized ||
            SupabaseConfig.client.auth.currentSession == null) {
          return;
        }
        final hasPin = await PinService.isSet;
        if (!hasPin || !mounted) return;
        final minutes = await AppSecureStore.autoLockMinutes;
        if (minutes == 0) AutoLockService.lock();
        if (!await AutoLockService.shouldLock() || !mounted) return;
        if (router.routerDelegate.currentConfiguration.uri.path == '/lock') {
          return;
        }
        router.go('/lock');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: switch (ref.watch(themeModeProvider)) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('id'), Locale('en')],
    );
  }
}
