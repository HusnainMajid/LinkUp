import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF4F8CFF); // Premium Blue
  static const Color secondary = Color(0xFF7C5CFF); // Premium Purple
  static const Color accent = Color(0xFF00D2FF);

  // Neutrals - Dark Mode (Premium Night)
  static const Color backgroundDark = Color(0xFF0D1117); // Deepest Navy
  static const Color surfaceDark = Color(0xFF161B22); // Primary Surface
  static const Color cardDark = Color(0xFF21262D); // Card Surface
  static const Color elevatedDark = Color(0xFF30363D); // Elevated Surface
  
  static const Color textPrimaryDark = Color(0xFFF0F6FC);
  static const Color textSecondaryDark = Color(0xFF8B949E);
  static const Color textTertiaryDark = Color(0xFF6E7681);

  // Neutrals - Light Mode (Clean Canvas)
  static const Color background = Color(0xFFF6F8FA);
  static const Color surface = Colors.white;
  static const Color card = Colors.white;
  static const Color textPrimary = Color(0xFF1F2328);
  static const Color textSecondary = Color(0xFF57606A);
  static const Color textTertiary = Color(0xFF6E7681);

  // Functional Colors
  static const Color success = Color(0xFF238636);
  static const Color error = Color(0xFFDA3633);
  static const Color warning = Color(0xFFD29922);
  static const Color info = Color(0xFF2F81F7);

  static const Color primaryLight = Color(0xFFBB86FC);

  // Premium Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4F8CFF), Color(0xFF7C5CFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF161B22), Color(0xFF0D1117)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF4F8CFF), Color(0xFF39D353)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient violetGradient = LinearGradient(
    colors: [Color(0xFF6200EE), Color(0xFF9C27B0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

