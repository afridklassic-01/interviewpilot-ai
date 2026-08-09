import 'package:flutter/material.dart';

import '../../app.dart';
import '../../models/feedback.dart';
import '../../state/interview_session.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/charts/radar_chart.dart';
import '../../widgets/charts/sparkline.dart';
import '../../widgets/common/app_background.dart';
import '../../widgets/common/app_top_nav.dart';
import '../../widgets/common/confirm_dialog.dart';
import '../../widgets/common/pilot_chip.dart';
import '../../widgets/common/state_views.dart';
import '../../widgets/progress/progress_bars.dart';
import '../../widgets/progress/radial_score.dart';

/// Screen 5 — Engineering report.
class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
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

  void _startNextTopic(BuildContext context) {
    final session = SessionScope.of(context);
    session.startNextTopic();
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.interview,
      (route) => route.settings.name == AppRoutes.landing,
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);

    return AppBackground(
      child: SafeArea(
        child: Column(
          children: [
            AppTopNav(
              onLogo: () => Navigator.of(context)
                  .pushNamedAndRemoveUntil(AppRoutes.landing, (r) => false),
              actions: [
                NavLink(
                  label: 'Dashboard',
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.dashboard),
                ),
                NavCta(
                  label: 'Retry Interview',
                  icon: Icons.refresh_rounded,
                  onTap: () => _retry(context),
                ),
              ],
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: session,
                builder: (context, _) {
                  if (!session.hasSession) {
                    return const Padding(
                      padding: EdgeInsets.all(AppTokens.s6),
                      child: EmptyView(
                        icon: Icons.description_outlined,
                        title: 'No report available',
                        message:
                            'Complete an interview to generate your engineering report.',
                      ),
                    );
                  }
                  if (!session.isComplete) {
                    return Padding(
                      padding: const EdgeInsets.all(AppTokens.s6),
                      child: EmptyView(
                        icon: Icons.timelapse_rounded,
                        title: 'Interview still in progress',
                        message: 'Finish the interview to unlock your report.',
                        action: () =>
                            Navigator.of(context).pushNamed(AppRoutes.interview),
                        actionLabel: 'Continue Interview',
                      ),
                    );
                  }
                  if (session.report == null) {
                    return const LoadingView(
                      label: 'Generating your engineering report…',
                    );
                  }
                  return _ReportBody(
                    candidateName: session.candidate?.name ?? 'Alex',
                    report: session.report!,
                    onReview: () =>
                        Navigator.of(context).pushNamed(AppRoutes.review),
                    onRetry: () => _retry(context),
                    onStartNext: () => _startNextTopic(context),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({
    required this.candidateName,
    required this.report,
    required this.onReview,
    required this.onRetry,
    required this.onStartNext,
  });

  final String candidateName;
  final InterviewReport report;
  final VoidCallback onReview;
  final VoidCallback onRetry;
  final VoidCallback onStartNext;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.s6),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReportHeader(candidateName: candidateName, report: report),
              const SizedBox(height: AppTokens.s5),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 960;
                  final radar = _RadarCard(report: report);
                  final profile = _ReadinessCard(report: report, onReview: onReview);
                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: radar),
                        const SizedBox(width: AppTokens.s5),
                        Expanded(flex: 6, child: profile),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      radar,
                      const SizedBox(height: AppTokens.s5),
                      profile,
                    ],
                  );
                },
              ),
              const SizedBox(height: AppTokens.s5),
              _StrengthsSection(report: report),
              if (report.missingConcepts.isNotEmpty ||
                  report.recommendedTopics.isNotEmpty) ...[
                const SizedBox(height: AppTokens.s5),
                _GapsSection(report: report),
              ],
              const SizedBox(height: AppTokens.s5),
              _NextMovesSection(
                report: report,
                onRetry: onRetry,
                onStartNext: onStartNext,
              ),
              const SizedBox(height: AppTokens.s5),
              _RecommendationCard(report: report),
              const SizedBox(height: AppTokens.s8),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportHeader extends StatelessWidget {
  const _ReportHeader({required this.candidateName, required this.report});

  final String candidateName;
  final InterviewReport report;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 640;
        final info = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ENGINEERING INTERVIEW REPORT',
                style: AppTypography.overline),
            const SizedBox(height: AppTokens.s2),
            Text(
              'Technical assessment',
              style: AppTypography.displaySmall,
            ),
            const SizedBox(height: AppTokens.s3),
            Wrap(
              spacing: AppTokens.s5,
              runSpacing: AppTokens.s2,
              children: [
                _Meta(label: 'Candidate', value: candidateName),
                _Meta(
                  label: 'Interview',
                  value: 'AI Engineering Technical Assessment',
                ),
              ],
            ),
          ],
        );
        final score = RadialScore(
          value: report.readinessPercent,
          size: narrow ? 84 : 108,
          strokeWidth: 8,
          label: 'READINESS',
        );
        if (narrow) {
          // Stack vertically so the fixed-size ring can never overflow.
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              info,
              const SizedBox(height: AppTokens.s4),
              score,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: info),
            const SizedBox(width: AppTokens.s4),
            score,
          ],
        );
      },
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTypography.monoOverline),
        const SizedBox(height: 3),
        Text(value, style: AppTypography.bodyStrong),
      ],
    );
  }
}

class _RadarCard extends StatelessWidget {
  const _RadarCard({required this.report});

  final InterviewReport report;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hoverable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SKILL PROFILE', style: AppTypography.overline),
          const SizedBox(height: AppTokens.s2),
          Text('Measured across your interview responses.',
              style: AppTypography.caption),
          const SizedBox(height: AppTokens.s4),
          Center(
            child: RadarChart(
              labels: report.skillScores.keys.toList(),
              values: report.skillScores.values.toList(),
            ),
          ),
          const SizedBox(height: AppTokens.s4),
          Wrap(
            spacing: AppTokens.s2,
            runSpacing: AppTokens.s2,
            children: [
              for (final entry in report.skillScores.entries)
                PilotChip(
                  '${entry.key} ${entry.value.round()}',
                  tone: entry.value >= 80
                      ? PilotTone.success
                      : entry.value >= 65
                          ? PilotTone.info
                          : PilotTone.warning,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard({required this.report, required this.onReview});

  final InterviewReport report;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primary.withValues(alpha: 0.1),
          AppColors.surface,
        ],
        stops: const [0, 0.55],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PERFORMANCE DIMENSIONS', style: AppTypography.overline),
          const SizedBox(height: AppTokens.s4),
          for (final (i, d) in report.dimensions.indexed) ...[
            SignalBar(name: d.name, score: d.score),
            if (i < report.dimensions.length - 1)
              const SizedBox(height: AppTokens.s4),
          ],
          const SizedBox(height: AppTokens.s5),
          Container(
            padding: const EdgeInsets.all(AppTokens.s4),
            decoration: BoxDecoration(
              color: AppColors.surfaceSunken,
              borderRadius: BorderRadius.circular(AppTokens.r4),
              border: Border.all(color: AppColors.borderFaint),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'IMPROVEMENT TREND',
                        style: AppTypography.monoOverline,
                        softWrap: true,
                      ),
                    ),
                    const SizedBox(width: AppTokens.s2),
                    PilotChip(
                      '${report.trendDelta >= 0 ? '+' : ''}${report.trendDelta.round()} pts',
                      tone: report.trendDelta >= 0 ? PilotTone.success : PilotTone.danger,
                      icon: report.trendDelta >= 0
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s3),
                SizedBox(height: 40, child: Sparkline(data: report.trend)),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s5),
          AppButton(
            label: 'Review All Questions',
            variant: ButtonVariant.secondary,
            icon: Icons.fact_check_outlined,
            expand: true,
            onPressed: onReview,
          ),
        ],
      ),
    );
  }
}

class _StrengthsSection extends StatelessWidget {
  const _StrengthsSection({required this.report});

  final InterviewReport report;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(icon: Icons.bolt_rounded, label: 'STRENGTHS'),
        const SizedBox(height: AppTokens.s4),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final cards = [
              for (final s in report.strengths) _StrengthCard(strength: s),
              for (final a in report.improvements) _ImproveCard(area: a),
            ];
            if (wide) {
              return Row(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    Expanded(child: cards[i]),
                    if (i < cards.length - 1)
                      const SizedBox(width: AppTokens.s4),
                  ],
                ],
              );
            }
            return Column(
              children: [
                for (final (i, c) in cards.indexed) ...[
                  c,
                  if (i < cards.length - 1) const SizedBox(height: AppTokens.s4),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _StrengthCard extends StatelessWidget {
  const _StrengthCard({required this.strength});

  final InterviewStrength strength;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      gradient: LinearGradient(
        colors: [AppColors.success.withValues(alpha: 0.08), AppColors.surface],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  size: 18, color: AppColors.success),
              const SizedBox(width: AppTokens.s2 + 2),
              Expanded(
                child: Text('STRENGTH', style: AppTypography.monoOverline),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s3),
          Text(strength.title, style: AppTypography.title),
          const SizedBox(height: AppTokens.s2),
          Text(strength.detail, style: AppTypography.body),
        ],
      ),
    );
  }
}

class _ImproveCard extends StatelessWidget {
  const _ImproveCard({required this.area});

  final ImprovementArea area;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      gradient: LinearGradient(
        colors: [AppColors.warning.withValues(alpha: 0.07), AppColors.surface],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.track_changes_rounded,
                  size: 18, color: AppColors.warning),
              const SizedBox(width: AppTokens.s2 + 2),
              Expanded(
                child: Text('TO IMPROVE', style: AppTypography.monoOverline),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s3),
          Text(area.title, style: AppTypography.title),
          const SizedBox(height: AppTokens.s2),
          Text(area.detail, style: AppTypography.body),
        ],
      ),
    );
  }
}

class _NextMovesSection extends StatelessWidget {
  const _NextMovesSection({
    required this.report,
    required this.onRetry,
    required this.onStartNext,
  });

  final InterviewReport report;
  final VoidCallback onRetry;
  final VoidCallback onStartNext;

  Future<void> _startPlan(BuildContext context) async {
    await showConfirmDialog(
      context,
      title: 'Improvement plan started',
      message:
          'Your next 3 moves were added to your learning plan. '
          'The dashboard will now prioritize MCP and production systems.',
      confirmLabel: 'Great',
      cancelLabel: 'Not now',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hoverable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('PERSONALIZED NEXT STEPS', style: AppTypography.overline)),
              PilotChip('Your next 3 moves', tone: PilotTone.primary),
            ],
          ),
          const SizedBox(height: AppTokens.s4),
          Text('Your next 3 moves', style: AppTypography.headline),
          const SizedBox(height: AppTokens.s5),
          for (final (i, step) in report.nextSteps.indexed) ...[
            _NextStepTile(index: i + 1, step: step),
            if (i < report.nextSteps.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppTokens.s4),
                child: Divider(height: 1, color: AppColors.borderFaint),
              ),
          ],
          const SizedBox(height: AppTokens.s5),
          AppButton(
            label: 'Start Improvement Plan',
            icon: Icons.flag_rounded,
            size: ButtonSize.large,
            expand: true,
            onPressed: () => _startPlan(context),
          ),
          const SizedBox(height: AppTokens.s3),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 720;
              final session = SessionScope.of(context);
              final startNext = AppButton(
                label: session.hasNextTopic ? 'Start Next Topic' : 'Start New Round',
                icon: Icons.play_arrow_rounded,
                size: ButtonSize.large,
                expand: true,
                onPressed: onStartNext,
              );
              final retry = AppButton(
                label: 'Retry Interview',
                variant: ButtonVariant.secondary,
                icon: Icons.refresh_rounded,
                size: ButtonSize.large,
                onPressed: onRetry,
              );
              if (wide) {
                return Row(
                  children: [
                    Expanded(child: startNext),
                    const SizedBox(width: AppTokens.s4),
                    retry,
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  startNext,
                  const SizedBox(height: AppTokens.s3),
                  retry,
                ],
              );
            },
          ),
          const SizedBox(height: AppTokens.s3),
          Center(
            child: TextButton(
              onPressed: () => _resetProgress(context),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textMuted,
                textStyle: AppTypography.caption,
              ),
              child: const Text('Reset all topic progress'),
            ),
          ),
        ],
      ),
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
      if (context.mounted) {
        // Progress now lives on the dashboard — take the user there.
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.dashboard,
          (route) => route.isFirst,
        );
      }
    }
  }
}

class _NextStepTile extends StatelessWidget {
  const _NextStepTile({required this.index, required this.step});

  final int index;
  final NextStep step;

  @override
  Widget build(BuildContext context) {
    final (icon, tone) = switch (step.type) {
      NextStepType.review => (Icons.menu_book_outlined, PilotTone.info),
      NextStepType.practice => (Icons.construction_outlined, PilotTone.warning),
      NextStepType.retry => (Icons.refresh_rounded, PilotTone.success),
    };

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$index',
            style: AppTypography.mono.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppTokens.s4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(step.title, style: AppTypography.bodyStrong),
              const SizedBox(height: 2),
              Text(step.detail, style: AppTypography.body),
            ],
          ),
        ),
        const SizedBox(width: AppTokens.s3),
        PilotChip(
          step.type.name.toUpperCase(),
          tone: tone,
          icon: icon,
        ),
      ],
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.report});

  final InterviewReport report;

  @override
  Widget build(BuildContext context) {
    final rec = report.recommendation;
    return AppCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.secondary.withValues(alpha: 0.1),
          AppColors.surface,
        ],
        stops: const [0, 0.5],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AI RECOMMENDATION', style: AppTypography.overline),
          const SizedBox(height: AppTokens.s4),
          Text('INTERVIEW READINESS', style: AppTypography.monoOverline),
          const SizedBox(height: AppTokens.s2),
          Text(rec.headline, style: AppTypography.headline),
          const SizedBox(height: AppTokens.s3),
          StatusBadge(
            label: 'Confidence: ${rec.confidence}',
            tone: rec.confidence.toLowerCase() == 'high'
                ? PilotTone.success
                : PilotTone.warning,
            icon: Icons.verified_rounded,
          ),
          const SizedBox(height: AppTokens.s4),
          Text(rec.explanation, style: AppTypography.body),
        ],
      ),
    );
  }
}

/// Backend-reported missing concepts + recommended review topics.
class _GapsSection extends StatelessWidget {
  const _GapsSection({required this.report});

  final InterviewReport report;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hoverable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MISSING CONCEPTS', style: AppTypography.overline),
          const SizedBox(height: AppTokens.s3),
          if (report.missingConcepts.isEmpty)
            Text('No major gaps detected.', style: AppTypography.body)
          else
            Wrap(
              spacing: AppTokens.s2,
              runSpacing: AppTokens.s2,
              children: [
                for (final concept in report.missingConcepts)
                  PilotChip(
                    concept,
                    tone: PilotTone.warning,
                    icon: Icons.warning_amber_rounded,
                  ),
              ],
            ),
          const SizedBox(height: AppTokens.s5),
          Text('RECOMMENDED TOPICS', style: AppTypography.overline),
          const SizedBox(height: AppTokens.s3),
          Wrap(
            spacing: AppTokens.s2,
            runSpacing: AppTokens.s2,
            children: [
              for (final topic in report.recommendedTopics)
                PilotChip(
                  topic,
                  tone: PilotTone.info,
                  icon: Icons.auto_stories_outlined,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primaryBright),
        const SizedBox(width: AppTokens.s2),
        Text(label, style: AppTypography.overline),
      ],
    );
  }
}
