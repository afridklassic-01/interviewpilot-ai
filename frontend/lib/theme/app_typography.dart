import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography system for InterviewPilot AI.
///
/// Uses the bundled Roboto family for UI text and the system monospace
/// stack for engineering/metrics accents, creating a professional
/// developer-tool voice with strong hierarchy.
class AppTypography {
  AppTypography._();

  static const String _ui = 'Roboto';
  static const String _mono = 'monospace';

  // ---- Display -----------------------------------------------------------
  static const TextStyle display = TextStyle(
    fontFamily: _ui,
    fontSize: 44,
    height: 1.08,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: _ui,
    fontSize: 32,
    height: 1.12,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    color: AppColors.textPrimary,
  );

  // ---- Headings ----------------------------------------------------------
  static const TextStyle headline = TextStyle(
    fontFamily: _ui,
    fontSize: 24,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  static const TextStyle title = TextStyle(
    fontFamily: _ui,
    fontSize: 18,
    height: 1.25,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
    color: AppColors.textPrimary,
  );

  static const TextStyle subtitle = TextStyle(
    fontFamily: _ui,
    fontSize: 15,
    height: 1.4,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );

  // ---- Body --------------------------------------------------------------
  static const TextStyle body = TextStyle(
    fontFamily: _ui,
    fontSize: 14,
    height: 1.55,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontFamily: _ui,
    fontSize: 14,
    height: 1.5,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _ui,
    fontSize: 16,
    height: 1.55,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  // ---- Caption / micro ---------------------------------------------------
  static const TextStyle caption = TextStyle(
    fontFamily: _ui,
    fontSize: 12,
    height: 1.4,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: AppColors.textMuted,
  );

  static const TextStyle overline = TextStyle(
    fontFamily: _ui,
    fontSize: 11,
    height: 1.3,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.6,
    color: AppColors.textMuted,
  );

  // ---- Mono (engineering accents) ----------------------------------------
  static const TextStyle mono = TextStyle(
    fontFamily: _mono,
    fontSize: 14,
    height: 1.5,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle monoLarge = TextStyle(
    fontFamily: _mono,
    fontSize: 40,
    height: 1.0,
    fontWeight: FontWeight.w600,
    letterSpacing: -1.0,
    color: AppColors.textPrimary,
  );

  static const TextStyle monoOverline = TextStyle(
    fontFamily: _mono,
    fontSize: 11,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.4,
    color: AppColors.textMuted,
  );
}

/// Convenience helpers used by screens to build text quickly.
extension TypographyX on BuildContext {
  TextStyle get textDisplay => AppTypography.display;
  TextStyle get textDisplaySmall => AppTypography.displaySmall;
  TextStyle get textHeadline => AppTypography.headline;
  TextStyle get textTitle => AppTypography.title;
  TextStyle get textSubtitle => AppTypography.subtitle;
  TextStyle get textBody => AppTypography.body;
  TextStyle get textBodyStrong => AppTypography.bodyStrong;
  TextStyle get textBodyLarge => AppTypography.bodyLarge;
  TextStyle get textCaption => AppTypography.caption;
  TextStyle get textOverline => AppTypography.overline;
  TextStyle get textMono => AppTypography.mono;
  TextStyle get textMonoLarge => AppTypography.monoLarge;
  TextStyle get textMonoOverline => AppTypography.monoOverline;
}
