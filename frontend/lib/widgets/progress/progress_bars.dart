import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';

/// Horizontal gradient bar used for signals and skills.
class GradientBar extends StatelessWidget {
  const GradientBar({
    super.key,
    required this.value,
    this.gradient = AppColors.signalGradient,
    this.height = 8,
    this.trackColor,
    this.animate = true,
  });

  /// 0..1 fraction.
  final double value;
  final Gradient gradient;
  final double height;
  final Color? trackColor;
  final bool animate;

  Widget _buildBar(double widthFactor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.rFull),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Container(color: trackColor ?? AppColors.border),
            FractionallySizedBox(
              widthFactor: widthFactor,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(AppTokens.rFull),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fraction = value.clamp(0.0, 1.0);
    if (!animate) return _buildBar(fraction);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: fraction),
      duration: AppTokens.slow,
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => _buildBar(t),
    );
  }
}

/// Labeled signal row: name, score and gradient bar.
///
/// A null [score] renders a placeholder (—) used before the first backend
/// evaluation — no fabricated values are ever shown.
class SignalBar extends StatelessWidget {
  const SignalBar({
    super.key,
    required this.name,
    required this.score,
    this.delta,
    this.trailing,
  });

  final String name;
  final double? score;
  final double? delta;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final value = score;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(name, style: AppTypography.caption),
            ),
            ?trailing,
            const SizedBox(width: AppTokens.s2),
            if (value != null)
              Text(
                '${value.round()}%',
                style: AppTypography.monoOverline.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            else
              Text(
                '—',
                style: AppTypography.monoOverline.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppTokens.s1 + 2),
        Row(
          children: [
            Expanded(
              child: GradientBar(value: (value ?? 0) / 100),
            ),
            if (delta != null && delta != 0) ...[
              const SizedBox(width: AppTokens.s2),
              _DeltaChip(delta: delta!),
            ],
          ],
        ),
      ],
    );
  }
}

class _DeltaChip extends StatelessWidget {
  const _DeltaChip({required this.delta});

  final double delta;

  @override
  Widget build(BuildContext context) {
    final up = delta > 0;
    final color = up ? AppColors.success : AppColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppTokens.r2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 10,
            color: color,
          ),
          Text(
            '${delta.abs().round()}',
            style: AppTypography.monoOverline.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

/// Segmented question progress (████░░░░) used in the interview top bar.
class SegmentedProgress extends StatelessWidget {
  const SegmentedProgress({
    super.key,
    required this.total,
    required this.completed,
    this.current,
  });

  final int total;
  final int completed;

  /// Index of the active question (pulses), or null when idle.
  final int? current;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final isDone = i < completed;
        final isCurrent = i == current;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: i == total - 1 ? 0 : AppTokens.s1,
            ),
            child: AnimatedContainer(
              duration: AppTokens.medium,
              height: 5,
              decoration: BoxDecoration(
                gradient: isDone ? AppColors.brandGradient : null,
                color: isDone ? null : AppColors.border,
                borderRadius: BorderRadius.circular(AppTokens.rFull),
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.7),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        );
      }),
    );
  }
}
