import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Hexagonal radar chart for the skill profile.
///
/// The chart is responsive: it sizes itself to the available width (never
/// exceeding [maxSize]) so it can never push a card outside the viewport.
/// Long axis labels are shortened on the canvas — the full topic names stay
/// visible in the chips rendered next to the chart.
class RadarChart extends StatelessWidget {
  const RadarChart({
    super.key,
    required this.labels,
    required this.values,
    this.maxSize = 300,
  });

  final List<String> labels;
  final List<double> values;

  /// Largest chart size; the actual size follows the available width.
  final double maxSize;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        final size = available <= 0
            ? maxSize
            : math.min(available, maxSize);
        return SizedBox(
          width: size,
          height: size * 0.92,
          child: CustomPaint(
            painter: _RadarPainter(
              labels: labels,
              values: values,
              chartSize: size,
            ),
          ),
        );
      },
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.labels,
    required this.values,
    required this.chartSize,
  });

  final List<String> labels;
  final List<double> values;
  final double chartSize;

  /// Shortens a label to at most ~2 words / ~16 chars so adjacent axes on a
  /// small chart never overlap. Full names are shown in chips beside/under
  /// the chart.
  static String _short(String label) {
    final words = label.split(' ');
    var out = '';
    for (final word in words) {
      if (out.isNotEmpty && '$out $word'.length > 16) break;
      out = out.isEmpty ? word : '$out $word';
    }
    if (out == label) return label;
    return '$out…';
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 4);
    final radius = math.min(size.width, size.height) / 2 - 30;
    final n = labels.length;
    if (n == 0 || radius <= 20) return;

    Offset point(int i, double r) {
      final angle = -math.pi / 2 + (i * 2 * math.pi / n);
      return center + Offset(math.cos(angle) * r, math.sin(angle) * r);
    }

    // Grid rings.
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.06);
    for (var ring = 1; ring <= 4; ring++) {
      final path = Path();
      for (var i = 0; i < n; i++) {
        final p = point(i, radius * ring / 4);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Axis lines.
    final axisPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.1);
    for (var i = 0; i < n; i++) {
      canvas.drawLine(center, point(i, radius), axisPaint);
    }

    // Data polygon (fill).
    final dataPath = Path();
    final dataPoints = <Offset>[];
    for (var i = 0; i < n; i++) {
      final r = radius * (values[i].clamp(0.0, 100.0) / 100);
      final p = point(i, r);
      dataPoints.add(p);
      if (i == 0) {
        dataPath.moveTo(p.dx, p.dy);
      } else {
        dataPath.lineTo(p.dx, p.dy);
      }
    }
    dataPath.close();

    canvas.drawPath(
      dataPath,
      Paint()
        ..style = PaintingStyle.fill
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.45),
            AppColors.secondary.withValues(alpha: 0.2),
          ],
        ).createShader(dataPath.getBounds()),
    );

    // Data outline.
    canvas.drawPath(
      dataPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColors.primaryBright,
    );

    // Vertex dots.
    final dotPaint = Paint()..color = Colors.white;
    for (final p in dataPoints) {
      canvas.drawCircle(p, 3, dotPaint);
    }

    // Labels — shortened and center-aligned so they never push the chart
    // (or the page) outside the viewport.
    final maxLabelWidth = math.max(radius * 0.85, 40.0);
    for (var i = 0; i < n; i++) {
      final p = point(i, radius + 16);
      final tp = TextPainter(
        text: TextSpan(
          text: _short(labels[i]),
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: maxLabelWidth);
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) =>
      oldDelegate.labels != labels ||
      oldDelegate.values != values ||
      oldDelegate.chartSize != chartSize;
}
