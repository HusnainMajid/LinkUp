import 'package:flutter/material.dart';

/// Centralized design constants for LinkUp
class AppSizes {
  // Spacing system
  static const double p4 = 4.0;
  static const double p8 = 8.0;
  static const double p12 = 12.0;
  static const double p16 = 16.0;
  static const double p20 = 20.0;
  static const double p24 = 24.0;
  static const double p32 = 32.0;
  static const double p40 = 40.0;
  static const double p48 = 48.0;

  // Corner Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusExtraLarge = 24.0;
  static const double radiusFull = 100.0;

  // Icon Sizes
  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;

  // Button Heights
  static const double buttonHeight = 56.0;
  static const double buttonHeightSmall = 40.0;

  // Avatar Sizes
  static const double avatarSmall = 32.0;
  static const double avatarMedium = 48.0;
  static const double avatarLarge = 64.0;
  static const double avatarExtraLarge = 96.0;

  // Card Elevation
  static const double elevationSmall = 2.0;
  static const double elevationMedium = 4.0;

  // Animation Durations
  static const Duration durationFast = Duration(milliseconds: 200);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);
}

/// Gap widgets for consistent spacing
class Gap {
  static const w4 = SizedBox(width: AppSizes.p4);
  static const w8 = SizedBox(width: AppSizes.p8);
  static const w12 = SizedBox(width: AppSizes.p12);
  static const w16 = SizedBox(width: AppSizes.p16);
  static const w20 = SizedBox(width: AppSizes.p20);
  static const w24 = SizedBox(width: AppSizes.p24);
  static const w32 = SizedBox(width: AppSizes.p32);
  static const w48 = SizedBox(width: AppSizes.p48);

  static const h4 = SizedBox(height: AppSizes.p4);
  static const h8 = SizedBox(height: AppSizes.p8);
  static const h12 = SizedBox(height: AppSizes.p12);
  static const h16 = SizedBox(height: AppSizes.p16);
  static const h20 = SizedBox(height: AppSizes.p20);
  static const h24 = SizedBox(height: AppSizes.p24);
  static const h32 = SizedBox(height: AppSizes.p32);
  static const h48 = SizedBox(height: AppSizes.p48);
}
