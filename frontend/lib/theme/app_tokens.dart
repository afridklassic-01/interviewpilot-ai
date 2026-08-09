import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Design tokens: spacing, radius, motion, shadows.
class AppTokens {
  AppTokens._();

  // Spacing scale (4pt base)
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s8 = 32;
  static const double s10 = 40;
  static const double s12 = 48;
  static const double s16 = 64;

  // Radius
  static const double r2 = 6;
  static const double r3 = 10;
  static const double r4 = 14;
  static const double r5 = 18;
  static const double r6 = 24;
  static const double rFull = 999;

  // Motion
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration medium = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 420);

  // Layout
  static const double pageMaxWidth = 1200;
  static const double navHeight = 64;
  static const double panelWidth = 300;
  static const double leftPanelWidth = 264;

  // Shadows
  static List<BoxShadow> get cardShadow => const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 24,
          offset: Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get glowShadow => const [
        BoxShadow(
          color: Color(0x557C6CFF),
          blurRadius: 32,
          offset: Offset(0, 4),
        ),
      ];
}

/// Shared gradient + glass decoration helpers.
class AppDecor {
  AppDecor._();

  /// Frosted glass surface used for cards.
  static BoxDecoration glass({
    Color? color,
    double radius = AppTokens.r5,
    Border? border,
    Gradient? gradient,
    List<BoxShadow>? shadow,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.surface,
      gradient: gradient,
      borderRadius: BorderRadius.circular(radius),
      border: border ?? Border.all(color: AppColors.border),
      boxShadow: shadow ?? AppTokens.cardShadow,
    );
  }

  /// Elevated glass surface (hovered cards).
  static BoxDecoration glassRaised({double radius = AppTokens.r5, Gradient? gradient}) {
    return BoxDecoration(
      color: AppColors.surfaceRaised,
      gradient: gradient,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.borderStrong),
      boxShadow: [
        const BoxShadow(
          color: Color(0x337C6CFF),
          blurRadius: 28,
          offset: Offset(0, 10),
        ),
        AppTokens.cardShadow.first,
      ],
    );
  }

  /// Subtle inset well for editors / code-like surfaces.
  static BoxDecoration well({double radius = AppTokens.r4}) {
    return BoxDecoration(
      color: AppColors.surfaceSunken,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.borderFaint),
    );
  }
}
