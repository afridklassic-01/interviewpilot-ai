import 'package:flutter/material.dart';

import '../../app.dart';
import '../../mock/mock_interview.dart';
import '../../state/interview_session.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/common/app_background.dart';
import '../../widgets/common/app_top_nav.dart';
import '../../widgets/common/logo_mark.dart';
import '../../widgets/common/pilot_chip.dart';
import '../../widgets/common/reveal.dart';

/// Screen 1 — Landing.
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final ScrollController _scrollController = ScrollController();

  void _startInterview(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.interview);
  }

  void _seeHowItWorks() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: AppTokens.slow,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Start a session early so the interview screen feels instant.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = SessionScope.of(context);
      if (!session.isStarted && !_started) {
        _started = true;
        session.startInterview();
      }
    });

    return AppBackground(
      child: SafeArea(
        child: Column(
          children: [
            AppTopNav(
              onLogo: () {},
              actions: [
                NavCta(label: 'Start AI Interview', onTap: () => _startInterview(context)),
              ],
            ),
            Expanded(
              child: Scrollbar(
                controller: _scrollController,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1060),
                      child: Column(
                        children: [
                          const SizedBox(height: AppTokens.s12),
                          _Hero(onPrimary: () => _startInterview(context), onSecondary: _seeHowItWorks),
                          const SizedBox(height: AppTokens.s12),
                          _FlowDiagram(),
                          const SizedBox(height: AppTokens.s12),
                          _TrustSection(onStart: () => _startInterview(context)),
                          const SizedBox(height: AppTokens.s16),
                          Text(
                            'InterviewPilot AI — adaptive interviews grounded in your learning journey.',
                            style: AppTypography.caption,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppTokens.s8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _started = false;
}

class _Hero extends StatelessWidget {
  const _Hero({required this.onPrimary, required this.onSecondary});

  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Reveal(child: LogoMark(size: 58, showWordmark: false)),
        const SizedBox(height: AppTokens.s5),
        Reveal(
          delay: const Duration(milliseconds: 90),
          child: Text.rich(
            TextSpan(
              text: 'INTERVIEWPILOT',
              style: AppTypography.display.copyWith(
                fontSize: 52,
                letterSpacing: 2.5,
                fontWeight: FontWeight.w900,
              ),
              children: [
                TextSpan(
                  text: ' AI',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 46,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                    foreground: Paint()
                      ..shader = AppColors.brandGradient.createShader(
                        const Rect.fromLTWH(0, 0, 200, 60),
                      ),
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppTokens.s4),
        Reveal(
          delay: const Duration(milliseconds: 180),
          child: Text(
            'Your learning journey.\nYour technical interview.\nYour next breakthrough.',
            style: AppTypography.displaySmall.copyWith(
              fontSize: 26,
              height: 1.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppTokens.s5),
        Reveal(
          delay: const Duration(milliseconds: 270),
          child: Text(
            'An adaptive AI interviewer that understands what you learned,\n'
            'challenges your engineering decisions, and shows you what to improve.',
            style: AppTypography.bodyLarge.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppTokens.s8),
        Reveal(
          delay: const Duration(milliseconds: 360),
          child: Wrap(
            spacing: AppTokens.s4,
            runSpacing: AppTokens.s3,
            alignment: WrapAlignment.center,
            children: [
              AppButton(
                label: 'Start AI Interview',
                icon: Icons.play_arrow_rounded,
                size: ButtonSize.large,
                onPressed: onPrimary,
              ),
              AppButton(
                label: 'See How It Works',
                variant: ButtonVariant.secondary,
                size: ButtonSize.large,
                icon: Icons.expand_more_rounded,
                onPressed: onSecondary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FlowDiagram extends StatelessWidget {
  const _FlowDiagram();

  static const _steps = [
    (
      Icons.auto_stories_outlined,
      'LEARNING JOURNEY',
      'Your 31-day cohort becomes the interviewer’s context.',
    ),
    (
      Icons.person_search_outlined,
      'PERSONALIZED INTERVIEW',
      'Questions are built from what you actually learned.',
    ),
    (
      Icons.alt_route_rounded,
      'ADAPTIVE FOLLOW-UPS',
      'Every answer reshapes the next question.',
    ),
    (
      Icons.insights_outlined,
      'ENGINEERING INSIGHTS',
      'A report that maps exactly where you stand.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Reveal(
          child: Text('HOW THE INTERVIEW WORKS', style: AppTypography.overline),
        ),
        const SizedBox(height: AppTokens.s4),
        Reveal(
          delay: const Duration(milliseconds: 120),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontal = constraints.maxWidth >= 820;
              return horizontal ? _buildRow(context) : _buildColumn();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRow(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppTokens.s6),
      hoverable: false,
      child: Row(
        children: [
          for (var i = 0; i < _steps.length; i++) ...[
            Expanded(child: _FlowStep(step: _steps[i], index: i)),
            if (i < _steps.length - 1) const _FlowArrow(horizontal: true),
          ],
        ],
      ),
    );
  }

  Widget _buildColumn() {
    return Column(
      children: [
        for (var i = 0; i < _steps.length; i++) ...[
          _FlowStep(step: _steps[i], index: i, vertical: true),
          if (i < _steps.length - 1)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 2),
              child: _FlowArrow(horizontal: false),
            ),
        ],
      ],
    );
  }
}

class _FlowStep extends StatelessWidget {
  const _FlowStep({required this.step, required this.index, this.vertical = false});

  final (IconData, String, String) step;
  final int index;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final (icon, title, desc) = step;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: vertical ? 0 : AppTokens.s3,
        vertical: vertical ? AppTokens.s3 : 0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(AppTokens.r4),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 14,
                ),
              ],
            ),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
          const SizedBox(height: AppTokens.s3 + 2),
          Text(
            title,
            style: AppTypography.overline.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTokens.s2),
          Text(
            desc,
            style: AppTypography.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FlowArrow extends StatelessWidget {
  const _FlowArrow({required this.horizontal});

  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final icon = horizontal ? Icons.arrow_forward_rounded : Icons.arrow_downward_rounded;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontal ? AppTokens.s2 : 0,
        vertical: horizontal ? 0 : AppTokens.s1,
      ),
      child: Icon(
        icon,
        size: 16,
        color: AppColors.primary.withValues(alpha: 0.55),
      ),
    );
  }
}

class _TrustSection extends StatelessWidget {
  const _TrustSection({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppTokens.s6),
      gradient: LinearGradient(
        colors: [
          AppColors.surface,
          AppColors.primary.withValues(alpha: 0.05),
        ],
      ),
      child: Column(
        children: [
          Text('31-DAY AI ENGINEERING COHORT', style: AppTypography.overline),
          const SizedBox(height: AppTokens.s2),
          Text(
            'Built on real curriculum signals — days completed, missions, '
            'attempts, skipped topics.',
            style: AppTypography.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTokens.s5),
          Wrap(
            spacing: AppTokens.s2,
            runSpacing: AppTokens.s2,
            alignment: WrapAlignment.center,
            children: [
              for (final topic in MockInterviewData.topicOrder)
                PilotChip(
                  topic,
                  tone: PilotTone.neutral,
                  icon: Icons.check_circle_outline_rounded,
                ),
            ],
          ),
          const SizedBox(height: AppTokens.s6),
          AppButton(
            label: 'Start AI Interview',
            icon: Icons.play_arrow_rounded,
            size: ButtonSize.medium,
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}
