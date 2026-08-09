import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Compact trend sparkline with gradient area fill.
class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.data,
    this.height = 44,
    this.color = AppColors.success,
    this.showEndDot = true,
    this.minPadding = 6,
  });

  final List<double> data;
  final double height;
  final Color color;
  final bool showEndDot;
  final double minPadding;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(double.infinity, height),
      painter: _SparklinePainter(
        data: data,
        color: color,
        showEndDot: showEndDot,
        minPadding: minPadding,
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.data,
    required this.color,
    required this.showEndDot,
    required this.minPadding,
  });

  final List<double> data;
  final Color color;
  final bool showEndDot;
  final double minPadding;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2 || size.width <= 0) return;

    final lo = data.reduce(math.min) - minPadding;
    final hi = data.reduce(math.max) + minPadding;
    final span = math.max(hi - lo, 1);

    Offset pointAt(int i) {
      final x = i * size.width / (data.length - 1);
      final y = size.height - ((data[i] - lo) / span) * size.height;
      return Offset(x, y.clamp(0.0, size.height));
    }

    final path = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (var i = 1; i < data.length; i++) {
      final p = pointAt(i);
      path.lineTo(p.dx, p.dy);
    }

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: [color, color.withValues(alpha: 0.6)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, line);

    // Area fill.
    final area = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    if (showEndDot) {
      final last = pointAt(data.length - 1);
      canvas.drawCircle(
        last,
        3.4,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        last,
        2,
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.color != color;
}
