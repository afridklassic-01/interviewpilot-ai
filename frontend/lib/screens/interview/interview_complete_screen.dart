import 'package:flutter/material.dart';

import '../../app.dart';
import '../../models/feedback.dart';
import '../../state/interview_session.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/charts/sparkline.dart';
import '../../widgets/common/app_background.dart';
import '../../widgets/common/confirm_dialog.dart';
import '../../widgets/common/pilot_chip.dart';
import '../../widgets/common/reveal.dart';
import '../../widgets/common/state_views.dart';
import '../../widgets/progress/progress_bars.dart';
import '../../widgets/progress/radial_score.dart';

/// Screen 4 — Interview complete.
class InterviewCompleteScreen extends StatefulWidget {
  const InterviewCompleteScreen({super.key});

  @override
  State<InterviewCompleteScreen> createState() =>
      _InterviewCompleteScreenState();
}

class _InterviewCompleteScreenState extends State<InterviewCompleteScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = SessionScope.of(context);
      if (session.report == null && session.hasSession) {
        session.loadReport();
      }
    });
  }

  void _retry(BuildContext context) {
    final session = SessionScope.of(context);
    final topic = session.currentTopic.isNotEmpty
        ? session.currentTopic
        : session.completedTopics.isNotEmpty
            ? session.completedTopics.last
            : null;
    if (topic != null) {
      session.retryTopic(topic);
    } else {
      session.reset();
    }
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.interview,
      (route) => route.settings.name == AppRoutes.landing,
    );
  }

  void _startNext(BuildContext context) {
    final session = SessionScope.of(context);
    session.startNextTopic();
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.interview,
      (route) => route.settings.name == AppRoutes.landing,
    );
  }

  Future<void> _resetProgress(BuildContext context) async {
    final session = SessionScope.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: 'Reset all topic progress?',
      message: 'This marks every interview topic as not started, so completed '
          'topics will be interviewed again on your next start. Your learning '
          'journey is not affected.',
      confirmLabel: 'Reset progress',
      cancelLabel: 'Cancel',
      destructive: true,
    );
    if (confirmed) {
      await session.resetAllProgress();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);

    return AppBackground(
      child: SafeArea(
        child: ListenableBuilder(
          listenable: session,
          builder: (context, _) {
            // Guards: no session / unfinished interview.
            if (!session.hasSession) {
              return _GuardEmpty(
                icon: Icons.question_answer_outlined,
                title: 'No interview found',
                message:
                    'Start an adaptive interview to unlock your engineering report.',
                onAction: () =>
                    Navigator.of(context).pushNamed(AppRoutes.interview),
                actionLabel: 'Start AI Interview',
              );
            }
            if (!session.isComplete) {
              return _GuardEmpty(
                icon: Icons.timelapse_rounded,
                title: 'Interview still in progress',
                message:
                    'You have ${session.remainingQuestions} '
                    'question(s) remaining. Continue where you left off.',
                onAction: () =>
                    Navigator.of(context).pushNamed(AppRoutes.interview),
                actionLabel: 'Continue Interview',
              );
            }
            if (session.report == null) {
              return const LoadingView(
                label: 'Compiling your results…',
                subtitle: 'Scoring dimensions across all of your answers.',
              );
            }

            final report = session.report!;
            return _CompleteContent(
              report: report,
              questionCount: session.questionCount,
              topicsCovered: session.completedTopics.length,
              nextTopic: session.nextIncompleteTopic,
              onRetry: () => _retry(context),
              onStartNext: () => _startNext(context),
              onReset: () => _resetProgress(context),
            );
          },
        ),
      ),
    );
  }
}

class _CompleteContent extends StatelessWidget {
  const _CompleteContent({
    required this.report,
    required this.questionCount,
    required this.topicsCovered,
    required this.nextTopic,
    required this.onRetry,
    required this.onStartNext,
    required this.onReset,
  });

  final InterviewReport report;
  final int questionCount;
  final int topicsCovered;

  /// Next incomplete topic, or null when every topic is complete.
  final String? nextTopic;
  final VoidCallback onRetry;
  final VoidCallback onStartNext;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final r = report;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.s6),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            children: [
              const SizedBox(height: AppTokens.s4),
              const Reveal(
                child: _CompleteBadge(),
              ),
              const SizedBox(height: AppTokens.s4),
              Reveal(
                delay: const Duration(milliseconds: 120),
                child: Text(
                  'Interview Complete',
                  style: AppTypography.display.copyWith(fontSize: 38),
                ),
              ),
              const SizedBox(height: AppTokens.s2),
              Reveal(
                delay: const Duration(milliseconds: 200),
                child: Text(
                  '$questionCount questions. $topicsCovered topics covered. '
                  '1 engineering profile.',
                  style: AppTypography.body,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppTokens.s2),
              Reveal(
                delay: const Duration(milliseconds: 240),
                child: Text(
                  nextTopic != null
                      ? 'Next up: $nextTopic'
                      : 'All curriculum topics complete — start a new round '
                          'anytime.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primaryBright,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppTokens.s6),
              Reveal(
                delay: const Duration(milliseconds: 280),
                child: AppCard(
                  hoverable: false,
                  padding: const EdgeInsets.all(AppTokens.s8),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.14),
                      AppColors.surface,
                    ],
                    stops: const [0, 0.6],
                  ),
                  child: Column(
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final size = constraints.maxWidth <= 0
                              ? 178.0
                              : (constraints.maxWidth * 0.55).clamp(120.0, 178.0);
                          return RadialScore(
                            value: r.overallScore,
                            size: size,
                            strokeWidth: 12,
                            label: 'OVERALL SCORE',
                            color: AppColors.primaryBright,
                          );
                        },
                      ),
                      const SizedBox(height: AppTokens.s4),
                      _FoundationBadge(score: r.overallScore),
                      const SizedBox(height: AppTokens.s6),
                      _DimensionBars(dimensions: r.dimensions),
                      const SizedBox(height: AppTokens.s6),
                      _TrendBlock(trend: r.trend),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.s8),
              Reveal(
                delay: const Duration(milliseconds: 360),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 720;
                    final viewReport = AppButton(
                      label: 'View Engineering Report',
                      icon: Icons.description_outlined,
                      size: ButtonSize.large,
                      expand: true,
                      onPressed: () =>
                          Navigator.of(context).pushNamed(AppRoutes.results),
                    );
                    final startNext = AppButton(
                      label: nextTopic != null ? 'Start Next Topic' : 'Start New Round',
                      variant: ButtonVariant.secondary,
                      icon: Icons.play_arrow_rounded,
                      size: ButtonSize.large,
                      onPressed: onStartNext,
                    );
                    if (wide) {
                      return Row(
                        children: [
                          Expanded(child: viewReport),
                          const SizedBox(width: AppTokens.s4),
                          startNext,
                        ],
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        viewReport,
                        const SizedBox(height: AppTokens.s3),
                        startNext,
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: AppTokens.s3),
              Reveal(
                delay: const Duration(milliseconds: 400),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppTokens.s3,
                  runSpacing: AppTokens.s2,
                  children: [
                    TextButton(
                      onPressed: onRetry,
                      child: const Text('Retry Interview'),
                    ),
                    TextButton(
                      onPressed: onReset,
                      child: const Text('Reset Progress'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.s8),
            ],
          ),
        ),
      ),
    );
  }
}

class _FoundationBadge extends StatelessWidget {
  const _FoundationBadge({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    final (label, tone) = switch (score) {
      >= 82 => ('Strong Technical Foundation', PilotTone.success),
      >= 65 => ('Solid Technical Foundation', PilotTone.info),
      _ => ('Foundation in Progress', PilotTone.warning),
    };
    return StatusBadge(
      label: label,
      tone: tone,
      icon: Icons.military_tech_rounded,
    );
  }
}

class _CompleteBadge extends StatelessWidget {
  const _CompleteBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 22,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(Icons.check_rounded, color: Colors.white, size: 30),
    );
  }
}

class _DimensionBars extends StatelessWidget {
  const _DimensionBars({required this.dimensions});

  final List<DimensionScore> dimensions;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final (i, d) in dimensions.indexed) ...[
          SignalBar(
            name: d.name,
            score: d.score,
            trailing: Text(
              '${d.score.round()}',
              style: AppTypography.mono.copyWith(
                color: AppColors.primaryBright,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (i < dimensions.length - 1) const SizedBox(height: AppTokens.s4),
        ],
      ],
    );
  }
}

class _TrendBlock extends StatelessWidget {
  const _TrendBlock({required this.trend});

  final List<double> trend;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppTokens.s4),
            decoration: BoxDecoration(
              color: AppColors.surfaceSunken,
              borderRadius: BorderRadius.circular(AppTokens.r4),
              border: Border.all(color: AppColors.borderFaint),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('IMPROVEMENT TREND', style: AppTypography.monoOverline),
                const SizedBox(height: AppTokens.s3),
                SizedBox(
                  height: 46,
                  child: Sparkline(data: trend),
                ),
                const SizedBox(height: AppTokens.s2),
                Text(
                  'Trending up across ${trend.length} '
                  'interview${trend.length == 1 ? '' : 's'}',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GuardEmpty extends StatelessWidget {
  const _GuardEmpty({
    required this.icon,
    required this.title,
    required this.message,
    required this.onAction,
    required this.actionLabel,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onAction;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTokens.s6),
      child: EmptyView(
        icon: icon,
        title: title,
        message: message,
        action: onAction,
        actionLabel: actionLabel,
      ),
    );
  }
}
