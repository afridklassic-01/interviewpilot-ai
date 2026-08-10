import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';

/// InterviewPilot brand mark: a stylized "interview radar" glyph.
class LogoMark extends StatelessWidget {
  const LogoMark({
    super.key,
    this.size = 34,
    this.showWordmark = true,
    this.onTap,
  });

  final double size;
  final bool showWordmark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.32),
            blurRadius: size * 0.42,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _RadarGlyphPainter(color: Colors.white),
        size: Size.square(size),
      ),
    );

    final wordmark = showWordmark
        ? Padding(
            padding: const EdgeInsets.only(left: AppTokens.s3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('InterviewPilot', style: AppTypography.title),
                SizedBox(width: 6),
                ShaderMask(
                  shaderCallback: (bounds) => AppColors.brandGradient
                      .createShader(bounds),
                  child: Text(
                    'AI',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          )
        : const SizedBox.shrink();

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [mark, wordmark],
    );

    if (onTap == null) return content;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      ),
    );
  }
}

/// Draws three concentric radar arcs + a center pulse dot.
class _RadarGlyphPainter extends CustomPainter {
  const _RadarGlyphPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 * 0.62;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.95);

    // Arcs at 3 radii.
    for (var i = 1; i <= 3; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * i / 3),
        -math.pi * 0.85,
        math.pi * 1.5,
        false,
        stroke..color = color.withValues(alpha: i == 3 ? 0.95 : 0.55),
      );
    }

    // Sweep line.
    canvas.drawLine(
      center,
      center + Offset(math.cos(-0.3) * radius, math.sin(-0.3) * radius),
      stroke..color = color.withValues(alpha: 0.8),
    );

    // Center dot.
    canvas.drawCircle(
      center,
      size.width * 0.09,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _RadarGlyphPainter oldDelegate) => false;
}
