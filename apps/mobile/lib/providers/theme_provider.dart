import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/security/secure_store.dart';

final themeModeProvider =
    StateNotifierProvider<ThemeModeController, String>((ref) {
  return ThemeModeController();
});

class ThemeModeController extends StateNotifier<String> {
  ThemeModeController() : super('system') {
    _load();
  }

  Future<void> _load() async {
    state = await AppSecureStore.themeMode;
  }

  Future<void> set(String value) async {
    if (value != 'system' && value != 'light' && value != 'dark') return;
    state = value;
    await AppSecureStore.setThemeMode(value);
  }

  ThemeMode get themeMode => switch (state) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
}