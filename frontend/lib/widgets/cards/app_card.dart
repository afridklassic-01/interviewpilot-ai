import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';

/// Glass card with optional hover elevation and tap handling.
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTokens.s5),
    this.onTap,
    this.hoverable = true,
    this.radius = AppTokens.r5,
    this.gradient,
    this.color,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final bool hoverable;
  final double radius;
  final Gradient? gradient;
  final Color? color;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final elevated = _hovered && widget.hoverable;

    final decoration = BoxDecoration(
      color: widget.color ?? AppColors.surface,
      gradient: widget.gradient,
      borderRadius: BorderRadius.circular(widget.radius),
      border: Border.all(
        color: elevated ? AppColors.primary.withValues(alpha: 0.35) : AppColors.border,
      ),
      boxShadow: elevated
          ? [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.14),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
              ...AppTokens.cardShadow,
            ]
          : AppTokens.cardShadow,
    );

    final content = AnimatedContainer(
      duration: AppTokens.medium,
      curve: Curves.easeOut,
      transform: elevated ? Matrix4.translationValues(0, -2, 0) : null,
      padding: widget.padding,
      decoration: decoration,
      child: widget.child,
    );

    if (widget.onTap == null) return content;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Semantics(
        button: true,
        child: GestureDetector(onTap: widget.onTap, child: content),
      ),
    );
  }
}
