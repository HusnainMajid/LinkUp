import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF4F8CFF); // Premium Blue
  static const Color primaryLight = Color(0xFFBB86FC); // Kept for compatibility
  static const Color secondary = Color(0xFF7C5CFF); // Premium Purple
  static const Color accent = Color(0xFF64B5F6);

  // Neutrals - Dark Mode (Hero Experience)
  static const Color backgroundDark = Color(0xFF0B0F14); // Deepest Navy
  static const Color surfaceDark = Color(0xFF111720); // Primary Surface
  static const Color cardDark = Color(0xFF171F2A); // Card Surface
  static const Color elevatedDark = Color(0xFF1C2633); // Elevated Surface
  
  static const Color textPrimaryDark = Color(0xFFF5F7FA);
  static const Color textSecondaryDark = Color(0xFFA4ADBA);
  static const Color textTertiaryDark = Color(0xFF6F7A89);

  // Neutrals - Light Mode
  static const Color background = Color(0xFFF8F9FB);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1A1C1E);
  static const Color textSecondary = Color(0xFF42474E);
  static const Color textTertiary = Color(0xFF72777F);

  // Functional Colors
  static const Color success = Color(0xFF35D07F);
  static const Color error = Color(0xFFFF5C6C);
  static const Color warning = Color(0xFFFBBC05);
  static const Color info = Color(0xFF4F8CFF);

  // Premium Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4F8CFF), Color(0xFF7C5CFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF1A2333), Color(0xFF111720)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF4F8CFF), Color(0xFF35D07F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient violetGradient = LinearGradient(
    colors: [Color(0xFF6200EE), Color(0xFF9C27B0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
