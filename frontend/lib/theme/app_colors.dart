import 'package:flutter/material.dart';

/// Central color palette for InterviewPilot AI.
///
/// A sophisticated dark, developer-tool aesthetic:
/// deep ink backgrounds, iris/violet primary, cyan secondary,
/// emerald success and soft amber warning accents.
class AppColors {
  AppColors._();

  // ---- Surfaces ----------------------------------------------------------
  static const Color ink = Color(0xFF06080F); // App background (deepest)
  static const Color inkSoft = Color(0xFF0A0E18); // Secondary background
  static const Color surface = Color(0xFF111624); // Card surface
  static const Color surfaceRaised = Color(0xFF182031); // Elevated surface
  static const Color surfaceSunken = Color(0xFF0C101C); // Input / well

  // ---- Borders -----------------------------------------------------------
  static const Color border = Color(0x14FFFFFF); // 8% white
  static const Color borderStrong = Color(0x26FFFFFF); // 15% white
  static const Color borderFaint = Color(0x0DFFFFFF); // 5% white

  // ---- Brand -------------------------------------------------------------
  static const Color primary = Color(0xFF7C6CFF); // Iris
  static const Color primaryBright = Color(0xFF9E8FFF); // Iris highlight
  static const Color primaryDeep = Color(0xFF5546E8); // Iris deep
  static const Color secondary = Color(0xFF2DD4BF); // Teal / cyan
  static const Color secondaryDim = Color(0xFF0E7C6F);

  // ---- Text --------------------------------------------------------------
  static const Color textPrimary = Color(0xFFF1F3FA);
  static const Color textSecondary = Color(0xFF9AA3B8);
  static const Color textMuted = Color(0xFF5F6B84);

  // ---- Status ------------------------------------------------------------
  static const Color success = Color(0xFF4ADE9C);
  static const Color warning = Color(0xFFF5B95C);
  static const Color danger = Color(0xFFF2737F);
  static const Color info = Color(0xFF63B3F8);

  // ---- Gradient defs -----------------------------------------------------
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B7BFF), Color(0xFF5A4BE8), Color(0xFF3E31C4)],
  );

  static const LinearGradient signalGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF7C6CFF), Color(0xFF2DD4BF)],
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF3DDC97), Color(0xFF1FA97C)],
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFF5B95C), Color(0xFFE08A3C)],
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFF2737F), Color(0xFFC0525E)],
  );

  /// Glass-like card fill: subtle white overlay from the top.
  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x0FFFFFFF), Color(0x04000000)],
    stops: [0.0, 1.0],
  );
}
