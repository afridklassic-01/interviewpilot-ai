import 'package:flutter/material.dart';

import '../../models/interview.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';
import '../cards/app_card.dart';
import '../progress/progress_bars.dart';

/// LIVE INTERVIEW SIGNALS panel.
///
/// These are response-based performance indicators (coverage, structure,
/// engineering vocabulary), not emotion detection.
class LiveSignalsPanel extends StatelessWidget {
  const LiveSignalsPanel({super.key, required this.signals});

  final List<InterviewSignal> signals;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hoverable: false,
      padding: const EdgeInsets.all(AppTokens.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LIVE INTERVIEW SIGNALS', style: AppTypography.overline),
          const SizedBox(height: AppTokens.s3),
          for (final (i, signal) in signals.indexed) ...[
            SignalBar(name: signal.name, score: signal.score),
            if (i < signals.length - 1) const SizedBox(height: AppTokens.s4),
          ],
          const SizedBox(height: AppTokens.s4),
          Container(
            padding: const EdgeInsets.all(AppTokens.s3),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(AppTokens.r3),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: AppTokens.s2),
                Expanded(
                  child: Text(
                    'Indicators derived from your responses — coverage, '
                    'structure and engineering vocabulary.',
                    style: AppTypography.caption.copyWith(height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// TOPIC COVERAGE panel with question + curriculum coverage.
class TopicCoveragePanel extends StatelessWidget {
  const TopicCoveragePanel({
    super.key,
    required this.coverage,
    required this.answeredCount,
    required this.totalQuestions,
    required this.curriculumCovered,
  });

  final List<TopicCoverage> coverage;
  final int answeredCount;
  final int totalQuestions;
  final int curriculumCovered;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hoverable: false,
      padding: const EdgeInsets.all(AppTokens.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TOPIC COVERAGE', style: AppTypography.overline),
          const SizedBox(height: AppTokens.s4),
          for (final (i, c) in coverage.indexed) ...[
            _CoverageRow(c: c),
            if (i < coverage.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: AppColors.borderFaint),
              ),
          ],
          const SizedBox(height: AppTokens.s4),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Question coverage',
                  value: '$answeredCount / $totalQuestions',
                ),
              ),
              const SizedBox(width: AppTokens.s3),
              Expanded(
                child: _MetricTile(
                  label: 'Curriculum coverage',
                  value: '$curriculumCovered / 4+ days',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CoverageRow extends StatelessWidget {
  const _CoverageRow({required this.c});

  final TopicCoverage c;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (c.state) {
      CoverageState.covered => (Icons.check_rounded, AppColors.success),
      CoverageState.current => (Icons.arrow_right_alt_rounded, AppColors.primaryBright),
      CoverageState.upcoming => (Icons.circle_outlined, AppColors.textMuted),
    };

    return Row(
      children: [
        SizedBox(
          width: 18,
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: AppTokens.s2 + 2),
        Expanded(
          child: Text(
            c.topic,
            style: AppTypography.bodyStrong.copyWith(
              color: c.state == CoverageState.upcoming
                  ? AppColors.textMuted
                  : AppColors.textPrimary,
              fontWeight: c.state == CoverageState.current
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
        ),
        if (c.questionCount > 0)
          Text(
            '×${c.questionCount}',
            style: AppTypography.monoOverline,
          ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

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
          Text(
            value,
            style: AppTypography.mono.copyWith(
              fontSize: 16,
              color: AppColors.primaryBright,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.caption),
        ],
      ),
    );
  }
}
