import 'package:flutter/material.dart';

import '../../models/question.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';

/// Visual tone shared by chips and badges.
enum PilotTone {
  neutral,
  primary,
  success,
  warning,
  danger,
  info,
  accent;

  Color get foreground => switch (this) {
        PilotTone.neutral => AppColors.textSecondary,
        PilotTone.primary => AppColors.primaryBright,
        PilotTone.success => AppColors.success,
        PilotTone.warning => AppColors.warning,
        PilotTone.danger => AppColors.danger,
        PilotTone.info => AppColors.info,
        PilotTone.accent => AppColors.secondary,
      };

  Color get background => switch (this) {
        PilotTone.neutral => Colors.white.withValues(alpha: 0.05),
        PilotTone.primary => AppColors.primary.withValues(alpha: 0.14),
        PilotTone.success => AppColors.success.withValues(alpha: 0.12),
        PilotTone.warning => AppColors.warning.withValues(alpha: 0.12),
        PilotTone.danger => AppColors.danger.withValues(alpha: 0.12),
        PilotTone.info => AppColors.info.withValues(alpha: 0.12),
        PilotTone.accent => AppColors.secondary.withValues(alpha: 0.12),
      };

  Color get border => switch (this) {
        PilotTone.neutral => AppColors.borderStrong,
        PilotTone.primary => AppColors.primary.withValues(alpha: 0.4),
        PilotTone.success => AppColors.success.withValues(alpha: 0.35),
        PilotTone.warning => AppColors.warning.withValues(alpha: 0.35),
        PilotTone.danger => AppColors.danger.withValues(alpha: 0.35),
        PilotTone.info => AppColors.info.withValues(alpha: 0.35),
        PilotTone.accent => AppColors.secondary.withValues(alpha: 0.35),
      };
}

/// Small pill used for topics, expected-focus and neutral labels.
class PilotChip extends StatelessWidget {
  const PilotChip(
    this.label, {
    super.key,
    this.tone = PilotTone.neutral,
    this.icon,
    this.onTap,
    this.selected = false,
  });

  final String label;
  final PilotTone tone;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final content = AnimatedContainer(
      duration: AppTokens.fast,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s3,
        vertical: AppTokens.s1 + 2,
      ),
      decoration: BoxDecoration(
        color: selected ? tone.foreground.withValues(alpha: 0.16) : tone.background,
        borderRadius: BorderRadius.circular(AppTokens.rFull),
        border: Border.all(
          color: selected ? tone.foreground : tone.border,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: tone.foreground),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: tone.foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: content),
    );
  }
}

/// Status badge with a leading dot, used for assessments and states.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.tone,
    this.icon,
    this.compact = false,
  });

  final String label;
  final PilotTone tone;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : AppTokens.s3,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(AppTokens.rFull),
        border: Border.all(color: tone.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(icon, size: compact ? 11 : 13, color: tone.foreground)
          else
            Container(
              width: compact ? 6 : 7,
              height: compact ? 6 : 7,
              decoration: BoxDecoration(
                color: tone.foreground,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: tone.foreground.withValues(alpha: 0.6),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: tone.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

/// Maps an assessment level to a badge.
StatusBadge assessmentBadge(AssessmentLevel level, {bool compact = false}) {
  return switch (level) {
    AssessmentLevel.strong => StatusBadge(
        label: 'Strong',
        tone: PilotTone.success,
        icon: Icons.check_circle_outline_rounded,
        compact: compact,
      ),
    AssessmentLevel.good => StatusBadge(
        label: 'Good',
        tone: PilotTone.info,
        icon: Icons.trending_up_rounded,
        compact: compact,
      ),
    AssessmentLevel.needsImprovement => StatusBadge(
        label: 'Needs improvement',
        tone: PilotTone.warning,
        icon: Icons.build_circle_outlined,
        compact: compact,
      ),
  };
}
