import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static Brightness _brightness = Brightness.light;
  static void setBrightness(Brightness brightness) => _brightness = brightness;

  static bool get isDark => _brightness == Brightness.dark;
  static const Color deepEmerald = Color(0xFF031D16);
  static const Color emerald = Color(0xFF075C43);
  static const Color primary = Color(0xFF0B6E4F);
  static const Color primaryDark = Color(0xFF084C36);
  static const Color primaryLight = Color(0xFF10A474);
  static const Color emeraldLight = Color(0xFF10A474);
  static const Color gold = Color(0xFFD9A93B);
  static const Color goldLight = Color(0xFFF1C75B);
  static const Color accent = Color(0xFFC7A24A);
  static const Color accentLight = Color(0xFFE3C878);
  static const Color warmGold = Color(0xFFC7A24A);
  static const Color cream = Color(0xFFF5F7F8);
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static Color get backgroundOff =>
      isDark ? const Color(0xFF0E1914) : const Color(0xFFF5F7F8);
  static Color get surfaceElevated =>
      isDark ? const Color(0xFF15231D) : const Color(0xFFFFFFFF);
  static Color get surfaceMuted =>
      isDark ? const Color(0xFF1B2D25) : const Color(0xFFEEF2F3);

  static Color get successContainer =>
      isDark ? const Color(0xFF1D3A2E) : const Color(0xFFE6F4ED);
  static Color get warningContainer =>
      isDark ? const Color(0xFF3A3017) : const Color(0xFFF7ECD2);
  static Color get errorContainer =>
      isDark ? const Color(0xFF3E211B) : const Color(0xFFFBE7E2);
  static Color get infoContainer =>
      isDark ? const Color(0xFF17303F) : const Color(0xFFE3EFF7);
  static Color get textPrimary =>
      isDark ? const Color(0xFFF5F2E9) : const Color(0xFF10231D);
  static Color get textSecondary =>
      isDark ? const Color(0xFFA7BBB1) : const Color(0xFF5A6B66);
  static Color get textTertiary =>
      isDark ? const Color(0xFF7F9389) : const Color(0xFF8A9892);
  static Color get textDisabled =>
      isDark ? const Color(0xFF5E7268) : const Color(0xFFAFBBB6);
  static Color get textInverse =>
      isDark ? const Color(0xFFF5F2E9) : Colors.white;
  static Color get neutral => textSecondary;
  static Color get heading => isDark ? const Color(0xFFC9E3D5) : primaryDark;
  static Color get numberPrimary =>
      isDark ? const Color(0xFFF1EEE5) : primaryDark;
  static Color get numberPositive =>
      isDark ? const Color(0xFF5CD4AC) : const Color(0xFF10A474);
  static Color get numberNegative =>
      isDark ? const Color(0xFFF19A8E) : const Color(0xFFC0392B);
  static Color get numberNeutral =>
      isDark ? const Color(0xFFC9E3D5) : const Color(0xFF596B63);
  static Color get iconPrimary =>
      isDark ? const Color(0xFFF5F2E9) : const Color(0xFF10231D);
  static Color get iconSecondary =>
      isDark ? const Color(0xFFA7BBB1) : const Color(0xFF5A6B66);
  static Color get iconDisabled =>
      isDark ? const Color(0xFF5E7268) : const Color(0xFFAFBBB6);
  static Color get brandEmerald => isDark ? const Color(0xFF7FD6B5) : primary;
  static Color get brandGold => isDark ? const Color(0xFFE8C86E) : warmGold;
  static Color get success =>
      isDark ? const Color(0xFF5CD4AC) : const Color(0xFF10A474);
  static Color get danger => isDark ? const Color(0xFFF19A8E) : expense;
  static Color get expense =>
      isDark ? const Color(0xFFF19A8E) : const Color(0xFFC0392B);
  static Color get income =>
      isDark ? const Color(0xFF5CD4AC) : const Color(0xFF10A474);
  static Color get warning =>
      isDark ? const Color(0xFFE7C15C) : const Color(0xFFD9A93B);
  static Color get info =>
      isDark ? const Color(0xFF90C6EA) : const Color(0xFF1E5F8A);
  static Color get border =>
      isDark ? const Color(0xFF2E4A3C) : const Color(0xFFE2E8E6);
  static Color get divider =>
      isDark ? const Color(0xFF2E4A3C) : const Color(0xFFE2E8E6);
  static Color get inputFill =>
      isDark ? const Color(0xFF15231D) : const Color(0xFFFFFFFF);
  static Color get inputBorder =>
      isDark ? const Color(0xFF2E4A3C) : const Color(0xFFE2E8E6);
  static Color get inputFocusedBorder => isDark ? accentLight : primary;
  static Color get placeholder =>
      isDark ? const Color(0xFF8E9F96) : const Color(0xFF8A9892);
}
