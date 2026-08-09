import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';
import '../common/pilot_chip.dart';

/// AI interviewer header: avatar, name, live status and thinking animation.
class InterviewerHeader extends StatelessWidget {
  const InterviewerHeader({
    super.key,
    required this.status,
    this.thinking = false,
    this.statusTone = PilotTone.neutral,
  });

  final String status;
  final bool thinking;
  final PilotTone statusTone;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Avatar(thinking: thinking),
        const SizedBox(width: AppTokens.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('InterviewPilot', style: AppTypography.title),
                  const SizedBox(width: AppTokens.s2),
                  PilotChip('AI', tone: PilotTone.primary, icon: Icons.bolt_rounded),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  if (thinking)
                    const _ThinkingDots()
                  else
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: AppTokens.medium,
                      child: Text(
                        status,
                        key: ValueKey('$status-$thinking'),
                        style: AppTypography.caption.copyWith(
                          color: statusTone.foreground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.thinking});

  final bool thinking;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppTokens.medium,
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(
              alpha: thinking ? 0.5 : 0.3,
            ),
            blurRadius: thinking ? 20 : 12,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            'AI',
            style: AppTypography.mono.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          if (thinking)
            const Positioned(
              right: 3,
              bottom: 3,
              child: _StatusDot(),
            ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatefulWidget {
  const _StatusDot();

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.3, end: 1.0).animate(_controller),
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: AppColors.success,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.ink, width: 1.5),
        ),
      ),
    );
  }
}

class _ThinkingDots extends StatefulWidget {
  const _ThinkingDots();

  @override
  State<_ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<_ThinkingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (_controller.value * 3 - i).clamp(0.0, 1.0);
            final opacity = 0.25 + 0.75 * (1 - (phase - 0.5).abs() * 2).clamp(0.0, 1.0);
            return Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryBright.withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
