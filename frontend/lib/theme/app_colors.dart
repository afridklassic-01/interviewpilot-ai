import 'package:flutter/material.dart';

/// Central color palette for InterviewPilot AI.
///
/// A professional, modern AI/SaaS dark theme: deep navy backgrounds,
/// charcoal/slate cards, indigo + blue accents with a violet highlight,
/// muted slate text, and red reserved for destructive actions.
/// Green survives only as a semantic success indicator.
class AppColors {
  AppColors._();

  // ---- Surfaces ----------------------------------------------------------
  static const Color ink = Color(0xFF070B14); // App background (deepest)
  static const Color inkSoft = Color(0xFF0B1020); // Secondary background
  static const Color surface = Color(0xFF111827); // Card surface
  static const Color surfaceRaised = Color(0xFF151B2B); // Elevated surface
  static const Color surfaceSunken = Color(0xFF0D1320); // Input / well

  // ---- Borders -----------------------------------------------------------
  static const Color border = Color(0xFF263047); // Subtle 1px card border
  static const Color borderStrong = Color(0x26FFFFFF); // 15% white
  static const Color borderFaint = Color(0x0DFFFFFF); // 5% white

  // ---- Brand -------------------------------------------------------------
  static const Color primary = Color(0xFF6366F1); // Indigo accent
  static const Color primaryBright = Color(0xFF818CF8); // Indigo highlight
  static const Color primaryDeep = Color(0xFF4F46E5); // Indigo deep
  static const Color secondary = Color(0xFF3B82F6); // Blue accent
  static const Color secondaryDim = Color(0xFF1E40AF);
  static const Color highlight = Color(0xFF8B5CF6); // Violet highlight

  // ---- Text --------------------------------------------------------------
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // ---- Status ------------------------------------------------------------
  static const Color success = Color(0xFF34D399); // Semantic — positive only
  static const Color warning = Color(0xFFF5B95C);
  static const Color danger = Color(0xFFEF4444); // Destructive actions only
  static const Color info = Color(0xFF63B3F8);

  // ---- Gradient defs -----------------------------------------------------
  /// Brand: violet → indigo → deep indigo (logos, primary buttons, avatars).
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1), Color(0xFF4F46E5)],
  );

  /// Signal/score bars: indigo → blue.
  static const LinearGradient signalGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF818CF8), Color(0xFF3B82F6)],
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFF5B95C), Color(0xFFE08A3C)],
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
  );

  /// Glass-like card fill: subtle white overlay from the top.
  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x0FFFFFFF), Color(0x04000000)],
    stops: [0.0, 1.0],
  );
}
