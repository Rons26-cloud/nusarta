import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/data/supabase_client.dart';
import 'core/router/app_router.dart';
import 'core/security/auto_lock_service.dart';
import 'core/security/biometric_service.dart';
import 'core/security/pin_service.dart';
import 'core/security/secure_store.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/updates/update_models.dart';
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
      Future<void>.delayed(const Duration(seconds: 2), () async {
        if (!mounted) return;
        final state = await ref.read(updateControllerProvider).check();
        _maybeNotifyUpdate(state, ref);
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
    if (state == AppLifecycleState.resumed &&
        !BiometricService.authenticating) {
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

  void _maybeNotifyUpdate(UpdateState state, WidgetRef ref) {
    final release = state.release;
    if (state.status != UpdateStatus.updateAvailable || release == null) {
      return;
    }
    if (!mounted) return;
    AppSecureStore.dismissedUpdateVersion.then((dismissed) {
      if (!mounted || dismissed == release.version) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Versi ${release.version} terbaru tersedia'),
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'Perbarui',
            onPressed: () {
              AppSecureStore.dismissUpdateVersion(release.version);
              router.push('/version');
            },
          ),
          onVisible: () {
            // Non-blocking: reminder auto-dismisses after the duration.
            AppSecureStore.dismissUpdateVersion(release.version);
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = switch (ref.watch(themeModeProvider)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    // Keep the semantic palette in sync with the active theme before the
    // widget tree is built so AppColors reflects the rendered brightness.
    final dark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    AppColors.setBrightness(dark ? Brightness.dark : Brightness.light);
    // Theme-aware system status/navigation bars (overridden locally on brand
    // hero pages via AnnotatedRegion).
    SystemChrome.setSystemUIOverlayStyle(
      dark
          ? SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              systemNavigationBarColor: AppColors.surfaceElevated,
              systemNavigationBarIconBrightness: Brightness.light,
              systemNavigationBarDividerColor: Colors.transparent,
            )
          : SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              systemNavigationBarColor: AppColors.surfaceElevated,
              systemNavigationBarIconBrightness: Brightness.dark,
              systemNavigationBarDividerColor: Colors.transparent,
            ),
    );
    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeMode,
      routerConfig: router,
      scrollBehavior:
          const MaterialScrollBehavior().copyWith(overscroll: false),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('id'), Locale('en')],
    );
  }
}
