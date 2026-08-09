import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';
import '../buttons/app_button.dart';
import 'logo_mark.dart';

/// Default top navigation chrome used across non-interview screens.
class AppTopNav extends StatelessWidget {
  const AppTopNav({
    super.key,
    this.actions = const [],
    this.onLogo,
  });

  final List<Widget> actions;
  final VoidCallback? onLogo;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppTokens.navHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.s6),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderFaint),
        ),
      ),
      child: Row(
        children: [
          LogoMark(onTap: onLogo, size: 30),
          const SizedBox(width: AppTokens.s4),
          // The action cluster scrolls horizontally so the nav can never
          // overflow on narrow viewports (logo stays pinned left).
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: actions,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small text link used inside nav actions.
class NavLink extends StatelessWidget {
  const NavLink({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s3,
            vertical: AppTokens.s2,
          ),
          child: Text(
            label,
            style: AppTypography.bodyStrong.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// CTA button used in nav bars.
class NavCta extends StatelessWidget {
  const NavCta({
    super.key,
    required this.label,
    this.onTap,
    this.icon = Icons.play_arrow_rounded,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: label,
      icon: icon,
      size: ButtonSize.small,
      onPressed: onTap,
    );
  }
}
