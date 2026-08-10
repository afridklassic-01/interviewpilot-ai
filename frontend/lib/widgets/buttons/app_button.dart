import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';

enum ButtonVariant { primary, secondary, ghost, danger }

enum ButtonSize { large, medium, small }

/// Reusable button with hover glow, press scale, focus ring and a
/// built-in loading state.
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.loading = false,
    this.expand = false,
    this.tooltip,
  });

  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final IconData? icon;
  final bool loading;
  final bool expand;
  final String? tooltip;

  bool get enabled => onPressed != null && !loading;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  double get _scale {
    if (_pressed) return 0.97;
    if (_hovered) return 1.015;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final isPrimary = widget.variant == ButtonVariant.primary;
    final isDanger = widget.variant == ButtonVariant.danger;
    final bg = isPrimary
        ? AppColors.brandGradient
        : isDanger
            ? AppColors.dangerGradient
            : null;
    final fg = isPrimary || isDanger
        ? Colors.white
        : widget.variant == ButtonVariant.secondary
            ? AppColors.primaryBright
            : AppColors.textSecondary;

    final (hPadding, vPadding, fontSize) = switch (widget.size) {
      ButtonSize.large => (AppTokens.s5, 14.0, 15.0),
      ButtonSize.medium => (AppTokens.s4, 10.0, 14.0),
      ButtonSize.small => (AppTokens.s3, 7.0, 12.5),
    };

    final border = switch (widget.variant) {
      ButtonVariant.secondary => Border.all(
          color: _hovered
              ? AppColors.primary.withValues(alpha: 0.65)
              : AppColors.primary.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ButtonVariant.ghost => Border.all(color: AppColors.borderStrong),
      _ => Border.all(color: Colors.white.withValues(alpha: 0.12)),
    };

    Widget button = AnimatedScale(
      scale: _scale,
      duration: AppTokens.fast,
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: AppTokens.medium,
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
        decoration: BoxDecoration(
          gradient: bg,
          borderRadius: BorderRadius.circular(AppTokens.r3 + 2),
          border: border,
          boxShadow: _hovered && widget.enabled
              ? [
                  BoxShadow(
                    color: isPrimary
                        ? AppColors.primary.withValues(alpha: 0.22)
                        : AppColors.primary.withValues(alpha: 0.14),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment:
              widget.expand ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            if (widget.loading) ...[
              SizedBox(
                width: fontSize + 2,
                height: fontSize + 2,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: fg,
                ),
              ),
              const SizedBox(width: 10),
            ] else if (widget.icon != null) ...[
              Icon(widget.icon, size: fontSize + 2, color: fg),
              const SizedBox(width: 8),
            ],
            Text(
              widget.label,
              style: AppTypography.bodyStrong.copyWith(
                color: fg,
                fontSize: fontSize,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: widget.enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.enabled ? widget.onPressed : null,
        child: Semantics(
          button: true,
          enabled: widget.enabled,
          label: widget.label,
          child: Focus(
            onFocusChange: (v) => setState(() => _focused = v),
            child: Container(
              foregroundDecoration: _focused
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTokens.r3 + 2),
                      border: Border.all(
                        color: AppColors.primaryBright,
                        width: 2,
                      ),
                    )
                  : null,
              child: widget.tooltip != null
                  ? Tooltip(message: widget.tooltip!, child: button)
                  : button,
            ),
          ),
        ),
      ),
    );
  }
}
