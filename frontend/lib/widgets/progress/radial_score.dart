import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';

/// Animated radial score ring with a center value and label.
class RadialScore extends StatefulWidget {
  const RadialScore({
    super.key,
    required this.value,
    this.size = 150,
    this.strokeWidth = 10,
    this.label,
    this.subLabel,
    this.suffix = '%',
    this.color = AppColors.primary,
    this.duration = const Duration(milliseconds: 900),
  });

  /// 0..100.
  final double value;
  final double size;
  final double strokeWidth;
  final String? label;
  final String? subLabel;
  final String suffix;
  final Color color;
  final Duration duration;

  @override
  State<RadialScore> createState() => _RadialScoreState();
}

class _RadialScoreState extends State<RadialScore>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..forward();

  late final Animation<double> _anim = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void didUpdateWidget(covariant RadialScore oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final v = widget.value * _anim.value;
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _RadialPainter(
              value: v / 100,
              color: widget.color,
              strokeWidth: widget.strokeWidth,
              trackColor: AppColors.border,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text.rich(
                    TextSpan(
                      text: '${v.round()}',
                      style: AppTypography.monoLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: widget.size * 0.27,
                      ),
                      children: [
                        TextSpan(
                          text: widget.suffix,
                          style: AppTypography.mono.copyWith(
                            color: AppColors.textMuted,
                            fontSize: widget.size * 0.11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.label != null) ...[
                    const SizedBox(height: AppTokens.s1),
                    Text(
                      widget.label!,
                      style: AppTypography.overline.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (widget.subLabel != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.subLabel!,
                      style: AppTypography.caption,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RadialPainter extends CustomPainter {
  const _RadialPainter({
    required this.value,
    required this.color,
    required this.strokeWidth,
    required this.trackColor,
  });

  final double value;
  final Color color;
  final double strokeWidth;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(colors: [color, color.withValues(alpha: 0.55)])
          .createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * value,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _RadialPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.color != color;
}
