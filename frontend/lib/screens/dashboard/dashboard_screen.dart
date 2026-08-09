import 'package:flutter/material.dart';

import '../../app.dart';
import '../../mock/mock_curriculum.dart';
import '../../mock/mock_interview.dart';
import '../../models/candidate.dart';
import '../../models/curriculum.dart';
import '../../state/interview_session.dart';
import '../../state/topic_progress.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/charts/sparkline.dart';
import '../../widgets/common/app_background.dart';
import '../../widgets/common/app_top_nav.dart';
import '../../widgets/common/confirm_dialog.dart';
import '../../widgets/common/pilot_chip.dart';
import '../../widgets/common/state_views.dart';
import '../../widgets/progress/progress_bars.dart';
import '../../widgets/progress/radial_score.dart';

/// Screen 2 — Candidate dashboard.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SessionScope.of(context).loadCandidate();
    });
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  void _startInterview(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.interview);
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: SafeArea(
        child: Column(
          children: [
            AppTopNav(
              onLogo: () => Navigator.of(context).pushNamed(AppRoutes.landing),
              actions: [
                NavLink(
                  label: 'Dashboard',
                  onTap: () {},
                ),
                NavCta(
                  label: 'Start AI Interview',
                  onTap: () => _startInterview(context),
                ),
              ],
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: SessionScope.of(context),
                builder: (context, _) {
                  final session = SessionScope.of(context);
                  final candidate = session.candidate;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTokens.s6),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1080),
                        child: candidate == null
                            ? const _DashboardSkeleton()
                            : _DashboardContent(
                                candidate: candidate,
                                greeting: _greeting,
                                session: session,
                                onStart: () => _startInterview(context),
                              ),
                      ),
                    ),
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

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.candidate,
    required this.greeting,
    required this.session,
    required this.onStart,
  });

  final Candidate candidate;
  final String greeting;
  final InterviewSession session;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(candidate: candidate, greeting: greeting, onStart: onStart),
        const SizedBox(height: AppTokens.s6),
        _TopicProgressCard(session: session),
        const SizedBox(height: AppTokens.s5),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final topCards = [
              _ReadinessCard(candidate: candidate),
              _InsightCard(candidate: candidate, onStart: onStart),
            ];
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 5, child: topCards[0]),
                  const SizedBox(width: AppTokens.s5),
                  Expanded(flex: 6, child: topCards[1]),
                ],
              );
            }
            return Column(
              children: [
                topCards[0],
                const SizedBox(height: AppTokens.s5),
                topCards[1],
              ],
            );
          },
        ),
        const SizedBox(height: AppTokens.s5),
        _JourneyCard(candidate: candidate),
        const SizedBox(height: AppTokens.s5),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final bottomCards = [
              _SkillsCard(candidate: candidate),
              _PerformanceCard(candidate: candidate),
            ];
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: bottomCards[0]),
                  const SizedBox(width: AppTokens.s5),
                  Expanded(flex: 5, child: bottomCards[1]),
                ],
              );
            }
            return Column(
              children: [
                bottomCards[0],
                const SizedBox(height: AppTokens.s5),
                bottomCards[1],
              ],
            );
          },
        ),
        const SizedBox(height: AppTokens.s8),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.candidate,
    required this.greeting,
    required this.onStart,
  });

  final Candidate candidate;
  final String greeting;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      gradient: AppColors.brandGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'A',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTokens.s3),
                  Text(
                    '$greeting, ${candidate.name}',
                    style: AppTypography.headline,
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.s2),
              Text(
                'Ready to test your engineering depth?',
                style: AppTypography.body.copyWith(fontSize: 15),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Persisted interview-topic progression: NOT_STARTED / IN_PROGRESS /
/// COMPLETED. A completed topic is skipped by the next normal interview.
class _TopicProgressCard extends StatelessWidget {
  const _TopicProgressCard({required this.session});

  final InterviewSession session;

  Future<void> _resetProgress(BuildContext context) async {
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
    final order = MockInterviewData.topicOrder;
    final completed = session.completedTopics.length;
    return AppCard(
      hoverable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('INTERVIEW TOPIC PROGRESS',
                    style: AppTypography.overline),
              ),
              PilotChip(
                '$completed/${order.length} complete',
                tone: PilotTone.info,
                icon: Icons.flag_outlined,
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s2),
          Text(
            'Topics stay complete after finishing their 8-question interview '
            '— your next interview starts the next topic automatically.',
            style: AppTypography.caption,
          ),
          const SizedBox(height: AppTokens.s4),
          Wrap(
            spacing: AppTokens.s2,
            runSpacing: AppTokens.s2,
            children: [
              for (final topic in order) _topicChip(topic),
            ],
          ),
          const SizedBox(height: AppTokens.s4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _resetProgress(context),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textMuted,
                textStyle: AppTypography.caption,
              ),
              child: const Text('Reset Progress'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topicChip(String topic) {
    final status = session.topicStatus(topic);
    final (tone, icon) = switch (status) {
      TopicStatus.completed =>
        (PilotTone.success, Icons.check_circle_rounded),
      TopicStatus.inProgress =>
        (PilotTone.primary, Icons.play_circle_outline_rounded),
      TopicStatus.notStarted =>
        (PilotTone.neutral, Icons.circle_outlined),
    };
    return PilotChip('$topic · ${status.label}', tone: tone, icon: icon);
  }
}

class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard({required this.candidate});

  final Candidate candidate;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primary.withValues(alpha: 0.14),
          AppColors.surface,
        ],
        stops: const [0, 0.55],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('INTERVIEW READINESS', style: AppTypography.overline),
          const SizedBox(height: AppTokens.s5),
          Row(
            children: [
              RadialScore(
                value: candidate.readinessScore,
                size: 132,
                label: 'READY',
              ),
              const SizedBox(width: AppTokens.s5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Based on your learning journey and previous interview '
                      'performance.',
                      style: AppTypography.body,
                    ),
                    const SizedBox(height: AppTokens.s4),
                    _StatPill(
                      icon: Icons.auto_stories_outlined,
                      label: '${candidate.stats.daysCompleted}/${candidate.stats.daysTotal} days',
                    ),
                    const SizedBox(height: AppTokens.s2),
                    _StatPill(
                      icon: Icons.psychology_outlined,
                      label: '6 skills measured',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.candidate, required this.onStart});

  final Candidate candidate;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.secondary.withValues(alpha: 0.09),
          AppColors.surface,
        ],
        stops: const [0, 0.5],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppTokens.r3),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 17,
                  color: AppColors.primaryBright,
                ),
              ),
              const SizedBox(width: AppTokens.s3),
              Text('AI INTERVIEW INSIGHT', style: AppTypography.overline),
            ],
          ),
          const SizedBox(height: AppTokens.s4),
          Text('Your next interview should focus on:',
              style: AppTypography.body),
          const SizedBox(height: AppTokens.s2),
          Wrap(
            spacing: AppTokens.s2,
            runSpacing: AppTokens.s2,
            children: const [
              PilotChip('MCP', tone: PilotTone.warning, icon: Icons.bolt_rounded),
              PilotChip('Production AI Systems', tone: PilotTone.warning),
            ],
          ),
          const SizedBox(height: AppTokens.s4),
          Container(
            padding: const EdgeInsets.all(AppTokens.s3),
            decoration: BoxDecoration(
              color: AppColors.surfaceSunken,
              borderRadius: BorderRadius.circular(AppTokens.r3),
              border: Border.all(color: AppColors.borderFaint),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.psychology_outlined,
                  size: 16,
                  color: AppColors.info,
                ),
                const SizedBox(width: AppTokens.s2 + 2),
                Expanded(
                  child: Text(
                    'You have strong theoretical understanding but fewer '
                    'completed practical missions in these areas.',
                    style: AppTypography.body,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s5),
          AppButton(
            label: 'Start Personalized Interview',
            icon: Icons.play_arrow_rounded,
            expand: true,
            size: ButtonSize.large,
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}

class _JourneyCard extends StatelessWidget {
  const _JourneyCard({required this.candidate});

  final Candidate candidate;

  @override
  Widget build(BuildContext context) {
    final stats = candidate.stats;
    return AppCard(
      hoverable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('YOUR LEARNING JOURNEY', style: AppTypography.overline),
          const SizedBox(height: AppTokens.s4),
          Row(
            children: [
              _JourneyStat(label: '31 Days', value: '${stats.daysTotal}', tone: PilotTone.neutral),
              _JourneyStat(label: 'Completed', value: '${stats.daysCompleted}', tone: PilotTone.success),
              _JourneyStat(label: 'Skipped', value: '${stats.daysSkipped}', tone: PilotTone.danger),
              _JourneyStat(label: 'Needs Review', value: '${stats.daysNeedsReview}', tone: PilotTone.warning),
            ],
          ),
          const SizedBox(height: AppTokens.s6),
          const _MilestoneStrip(),
        ],
      ),
    );
  }
}

class _JourneyStat extends StatelessWidget {
  const _JourneyStat({required this.label, required this.value, required this.tone});

  final String label;
  final String value;
  final PilotTone tone;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTypography.monoLarge.copyWith(fontSize: 30),
          ),
          const SizedBox(height: 2),
          Text(label.toUpperCase(), style: AppTypography.monoOverline),
          const SizedBox(height: 6),
          Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [tone.foreground, tone.foreground.withValues(alpha: 0.15)],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneStrip extends StatelessWidget {
  const _MilestoneStrip();

  @override
  Widget build(BuildContext context) {
    final milestones = MockCurriculum.milestones;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < milestones.length; i++) ...[
            _Milestone(milestone: milestones[i]),
            if (i < milestones.length - 1)
              Container(
                width: 64,
                height: 2,
                margin: const EdgeInsets.only(top: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      milestones[i].status == DayStatus.skipped
                          ? AppColors.textMuted.withValues(alpha: 0.2)
                          : AppColors.primary.withValues(alpha: 0.5),
                      milestones[i + 1].status == DayStatus.skipped
                          ? AppColors.textMuted.withValues(alpha: 0.2)
                          : AppColors.primary.withValues(alpha: 0.5),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Milestone extends StatelessWidget {
  const _Milestone({required this.milestone});

  final JourneyMilestone milestone;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (milestone.status) {
      DayStatus.completed => (Icons.check_rounded, AppColors.textSecondary),
      DayStatus.strong => (Icons.check_circle_rounded, AppColors.success),
      DayStatus.needsReview => (Icons.autorenew_rounded, AppColors.warning),
      DayStatus.skipped => (Icons.remove_rounded, AppColors.danger),
      DayStatus.upcoming => (Icons.circle_outlined, AppColors.textMuted),
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.45), width: 1.2),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(height: AppTokens.s2),
        Text(
          'Day ${milestone.day}',
          style: AppTypography.monoOverline.copyWith(color: color),
        ),
        const SizedBox(height: 2),
        Text(milestone.label, style: AppTypography.caption),
      ],
    );
  }
}

class _SkillsCard extends StatelessWidget {
  const _SkillsCard({required this.candidate});

  final Candidate candidate;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hoverable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('SKILL INTELLIGENCE', style: AppTypography.overline),
              const Spacer(),
              PilotChip(
                'Estimated from curriculum signals',
                tone: PilotTone.neutral,
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s5),
          for (final (i, skill) in candidate.skills.indexed) ...[
            _SkillRow(skill: skill),
            if (i < candidate.skills.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppTokens.s3),
                child: Divider(height: 1, color: AppColors.borderFaint),
              ),
          ],
        ],
      ),
    );
  }
}

class _SkillRow extends StatelessWidget {
  const _SkillRow({required this.skill});

  final SkillProficiency skill;

  @override
  Widget build(BuildContext context) {
    final tone = switch (skill.score) {
      >= 80 => PilotTone.success,
      >= 65 => PilotTone.info,
      _ => PilotTone.warning,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(skill.name, style: AppTypography.bodyStrong),
            const Spacer(),
            Text(
              '${skill.score.round()}%',
              style: AppTypography.mono.copyWith(color: tone.foreground),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s2),
        GradientBar(
          value: skill.score / 100,
          gradient: LinearGradient(
            colors: [tone.foreground, tone.foreground.withValues(alpha: 0.4)],
          ),
        ),
        if (skill.summary != null) ...[
          const SizedBox(height: AppTokens.s1 + 2),
          Text(skill.summary!, style: AppTypography.caption),
        ],
      ],
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  const _PerformanceCard({required this.candidate});

  final Candidate candidate;

  @override
  Widget build(BuildContext context) {
    final prev = candidate.previousInterview;
    return AppCard(
      hoverable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('RECENT PERFORMANCE', style: AppTypography.overline),
          const SizedBox(height: AppTokens.s4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${prev.score.round()}',
                style: AppTypography.monoLarge.copyWith(
                  fontSize: 46,
                  color: AppColors.primaryBright,
                ),
              ),
              Text(
                ' / 100',
                style: AppTypography.mono.copyWith(color: AppColors.textMuted),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.s2,
                  vertical: AppTokens.s1,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTokens.r2),
                ),
                child: Row(
                  children: [
                    Icon(
                      prev.trendDelta >= 0
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 14,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${prev.trendDelta >= 0 ? '+' : ''}${prev.trendDelta.round()}',
                      style: AppTypography.monoOverline.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Text('Last interview score', style: AppTypography.caption),
          const SizedBox(height: AppTokens.s4),
          SizedBox(
            height: 46,
            child: Sparkline(data: [...prev.trend, candidate.readinessScore]),
          ),
          const SizedBox(height: AppTokens.s5),
          Row(
            children: [
              Expanded(
                child: _PerfPill(
                  icon: Icons.local_fire_department_outlined,
                  label: 'Strongest',
                  value: prev.strongestTopic,
                  tone: PilotTone.success,
                ),
              ),
              const SizedBox(width: AppTokens.s3),
              Expanded(
                child: _PerfPill(
                  icon: Icons.flag_outlined,
                  label: 'Weakest',
                  value: prev.weakestTopic,
                  tone: PilotTone.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PerfPill extends StatelessWidget {
  const _PerfPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final String value;
  final PilotTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s3),
      decoration: BoxDecoration(
        color: AppColors.surfaceSunken,
        borderRadius: BorderRadius.circular(AppTokens.r3),
        border: Border.all(color: AppColors.borderFaint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: tone.foreground),
              const SizedBox(width: 6),
              Text(label.toUpperCase(), style: AppTypography.monoOverline),
            ],
          ),
          const SizedBox(height: AppTokens.s2),
          Text(value, style: AppTypography.bodyStrong),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: AppTokens.s2),
        Text(label, style: AppTypography.bodyStrong.copyWith(fontSize: 13)),
      ],
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonBox(width: 260, height: 28),
        const SizedBox(height: 8),
        const SkeletonBox(width: 320, height: 14),
        const SizedBox(height: AppTokens.s6),
        Row(
          children: [
            Expanded(
              child: AppCard(
                hoverable: false,
                child: Column(
                  children: [
                    const SkeletonBox(height: 12, width: 160),
                    const SizedBox(height: AppTokens.s5),
                    Row(
                      children: [
                        const SkeletonBox(width: 110, height: 110, shape: BoxShape.circle),
                        const SizedBox(width: AppTokens.s5),
                        Expanded(
                          child: Column(
                            children: const [
                              SkeletonBox(height: 12),
                              SizedBox(height: 10),
                              SkeletonBox(height: 12, width: 180),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s5),
        AppCard(
          hoverable: false,
          child: Column(
            children: const [
              SkeletonBox(height: 12, width: 200),
              SizedBox(height: 24),
              SkeletonBox(height: 14),
              SizedBox(height: 10),
              SkeletonBox(height: 14, width: 260),
              SizedBox(height: 24),
              SkeletonBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }
}
