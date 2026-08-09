import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';
import '../buttons/app_button.dart';

/// Skeleton block that gently pulses while data loads.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.radius = 8,
    this.shape = BoxShape.rectangle,
  });

  final double width;
  final double height;
  final double radius;
  final BoxShape shape;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.45, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          shape: widget.shape,
          color: AppColors.surfaceRaised,
          borderRadius:
              widget.shape == BoxShape.rectangle ? BorderRadius.circular(widget.radius) : null,
        ),
      ),
    );
  }
}

/// Centered labeled loading state with the brand spinner.
class LoadingView extends StatelessWidget {
  const LoadingView({
    super.key,
    this.label = 'Loading…',
    this.subtitle,
  });

  final String label;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 42,
            height: 42,
            child: CustomPaint(
              painter: _BrandSpinnerPainter(),
            ),
          ),
          const SizedBox(height: AppTokens.s5),
          Text(label, style: AppTypography.title),
          if (subtitle != null) ...[
            const SizedBox(height: AppTokens.s2),
            Text(
              subtitle!,
              style: AppTypography.body,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _BrandSpinnerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = AppColors.border;
    canvas.drawCircle(size.center(Offset.zero), size.width / 2 - 2, track);

    final sweep = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..shader = AppColors.brandGradient.createShader(
        Rect.fromCircle(center: size.center(Offset.zero), radius: size.width),
      );
    canvas.drawArc(
      Rect.fromCircle(
        center: size.center(Offset.zero),
        radius: size.width / 2 - 2,
      ),
      0,
      1.6 * 3.14159,
      false,
      sweep,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Error state with retry action.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    this.title = 'Something went wrong',
    this.message = 'The service did not respond. Please try again.',
    this.onRetry,
    this.compact = false,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        padding: EdgeInsets.all(compact ? AppTokens.s4 : AppTokens.s6),
        decoration: AppDecor.glass(radius: AppTokens.r5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: AppColors.danger,
                size: 24,
              ),
            ),
            const SizedBox(height: AppTokens.s4),
            Text(title, style: AppTypography.title),
            const SizedBox(height: AppTokens.s2),
            Text(
              message,
              style: AppTypography.body,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppTokens.s5),
              AppButton(
                label: 'Retry',
                icon: Icons.refresh_rounded,
                onPressed: onRetry,
                variant: ButtonVariant.secondary,
              ),
            ],
          ],
        ),
      ),
    );
    return compact ? content : Padding(padding: const EdgeInsets.all(AppTokens.s6), child: content);
  }
}

/// Empty state with optional action.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.actionLabel,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? action;
  final String? actionLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTokens.r4),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: AppColors.primaryBright, size: 26),
            ),
            const SizedBox(height: AppTokens.s5),
            Text(title, style: AppTypography.headline, textAlign: TextAlign.center),
            const SizedBox(height: AppTokens.s2 + 2),
            Text(
              message,
              style: AppTypography.body,
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: AppTokens.s6),
              AppButton(
                label: actionLabel ?? 'Get started',
                onPressed: action,
                size: ButtonSize.large,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
