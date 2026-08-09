import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Ambient background: deep ink surface, two soft gradient glows and a
/// faint engineering dot-grid. All decorative layers ignore pointers.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.ink),
      child: Stack(
        children: [
          // Primary glow — iris, top-left.
          Positioned(
            top: -220,
            left: -160,
            child: _Glow(
              size: 620,
              color: AppColors.primary.withValues(alpha: 0.14),
            ),
          ),
          // Secondary glow — teal, bottom-right.
          Positioned(
            bottom: -240,
            right: -180,
            child: _Glow(
              size: 560,
              color: AppColors.secondary.withValues(alpha: 0.07),
            ),
          ),
          // Fine dot grid.
          Positioned.fill(
            child: CustomPaint(painter: _GridPainter()),
          ),
          // Material ancestor so descendants (TextField, InkWell, …) work
          // without a Scaffold.
          Material(
            type: MaterialType.transparency,
            child: child,
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 36.0;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.028)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final cols = (size.width / spacing).ceil() + 1;
    final rows = (size.height / spacing).ceil() + 1;
    for (var x = 0; x < cols; x++) {
      for (var y = 0; y < rows; y++) {
        final dx = x * spacing + ((y % 2) * spacing * 0.5);
        canvas.drawCircle(Offset(dx, y * spacing), 0.7, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
