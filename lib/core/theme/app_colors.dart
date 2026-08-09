import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF6200EE); // Violet
  static const Color primaryLight = Color(0xFFBB86FC);
  static const Color primaryDark = Color(0xFF3700B3);
  
  static const Color secondary = Color(0xFF03DAC6); // Electric Blue/Teal
  static const Color accent = Color(0xFF64B5F6); // Light Blue

  // Neutrals - Light Mode
  static const Color background = Color(0xFFF8F9FE);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1A1C1E);
  static const Color textSecondary = Color(0xFF42474E);
  static const Color textTertiary = Color(0xFF72777F);

  // Neutrals - Dark Mode
  static const Color backgroundDark = Color(0xFF0B1019); // Deep Navy
  static const Color surfaceDark = Color(0xFF1A222E); // Dark Navy
  static const Color textPrimaryDark = Color(0xFFE2E2E6);
  static const Color textSecondaryDark = Color(0xFFC2C7CF);
  static const Color textTertiaryDark = Color(0xFF8E9199);

  // Functional Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFBA1A1A);
  static const Color warning = Color(0xFFFBBC05);
  static const Color info = Color(0xFF2196F3);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6200EE), Color(0xFF03DAC6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient violetGradient = LinearGradient(
    colors: [Color(0xFF6200EE), Color(0xFF9C27B0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
