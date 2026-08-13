import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  static const String _fontFamily = 'Roboto';

  static TextTheme createTextTheme(bool isDark) {
    final Color color = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final Color secondaryColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final Color tertiaryColor = isDark ? AppColors.textTertiaryDark : AppColors.textTertiary;

    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 48,
        fontWeight: FontWeight.w900,
        color: color,
        letterSpacing: -1,
      ),
      displayMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 36,
        fontWeight: FontWeight.w800,
        color: color,
        letterSpacing: -0.5,
      ),
      displaySmall: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 30,
        fontWeight: FontWeight.w800,
        color: color,
      ),
      headlineLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: color,
      ),
      headlineMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: color,
      ),
      headlineSmall: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: color,
      ),
      titleLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: color,
      ),
      titleMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      titleSmall: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      bodyLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: secondaryColor,
        height: 1.4,
      ),
      bodySmall: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: tertiaryColor,
      ),
      labelLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: color,
        letterSpacing: 0.5,
      ),
      labelMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: secondaryColor,
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: tertiaryColor,
        letterSpacing: 1,
      ),
    );
  }
}
