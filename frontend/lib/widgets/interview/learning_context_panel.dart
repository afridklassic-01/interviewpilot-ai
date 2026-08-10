import 'package:flutter/material.dart';

import '../../models/question.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';
import '../cards/app_card.dart';
import '../common/pilot_chip.dart';

/// Left panel — explains WHY the interviewer chose this topic, grounded in
/// the candidate's learning journey. Never reveals hidden reasoning.
class LearningContextPanel extends StatelessWidget {
  const LearningContextPanel({
    super.key,
    required this.question,
    this.signal,
    this.previousPerformance,
  });

  final InterviewQuestion question;
  final String? signal;
  final String? previousPerformance;

  @override
  Widget build(BuildContext context) {
    final isFollowUp = question.isFollowUp;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PanelLabel(label: 'LEARNING CONTEXT'),
        const SizedBox(height: AppTokens.s3),
        AppCard(
          padding: const EdgeInsets.all(AppTokens.s4),
          borderColor: AppColors.primary.withValues(alpha: 0.28),
          gradient: isFollowUp
              ? LinearGradient(
                  colors: [
                    AppColors.secondary.withValues(alpha: 0.08),
                    AppColors.surface,
                  ],
                )
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isFollowUp ? 'WHERE THIS CAME FROM' : 'WHY THIS TOPIC?',
                style: AppTypography.overline.copyWith(
                  color: isFollowUp ? AppColors.secondary : AppColors.primaryBright,
                ),
              ),
              const SizedBox(height: AppTokens.s2 + 2),
              Text(
                isFollowUp
                    ? 'Adaptively generated from your previous answer.'
                    : 'Selected from your completed learning journey.',
                style: AppTypography.body,
              ),
              const SizedBox(height: AppTokens.s4),
              if (isFollowUp) ...[
                Container(
                  padding: const EdgeInsets.all(AppTokens.s3),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTokens.r3),
                    border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            size: 13,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Based on your previous answer',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (question.basedOnAnswer != null &&
                          question.basedOnAnswer!.isNotEmpty) ...[
                        const SizedBox(height: AppTokens.s2),
                        Text(
                          '“${question.basedOnAnswer}”',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.s4),
              ],
              _ContextRow(
                label: 'Curriculum',
                value: question.curriculumDay == null
                    ? '—'
                    : 'Day ${question.curriculumDay} — ${question.curriculumTitle}',
              ),
              const SizedBox(height: AppTokens.s3),
              _ContextRow(
                label: 'Candidate signal',
                value: signal ?? 'No recorded signal',
                icon: Icons.flag_outlined,
                iconColor: AppColors.info,
              ),
              const SizedBox(height: AppTokens.s3),
              _ContextRow(
                label: 'Previous performance',
                value: previousPerformance ?? '—',
                icon: Icons.check_circle_outline_rounded,
                iconColor: AppColors.success,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.s4),
        const _PanelLabel(label: 'INTERVIEW'),
        const SizedBox(height: AppTokens.s3),
        AppCard(
          padding: const EdgeInsets.all(AppTokens.s4),
          hoverable: false,
          borderColor: AppColors.primary.withValues(alpha: 0.28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Difficulty', style: AppTypography.monoOverline),
                  ),
                  const SizedBox(width: AppTokens.s2),
                  PilotChip(
                    question.difficulty.label,
                    tone: PilotTone.primary,
                    icon: Icons.trending_up_rounded,
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.s3),
              Text(
                'Answer as you would to a senior engineer — structure, '
                'trade-offs and failure modes carry weight.',
                style: AppTypography.caption,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContextRow extends StatelessWidget {
  const _ContextRow({
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTypography.monoOverline),
        const SizedBox(height: AppTokens.s1),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Icon(icon, size: 13, color: iconColor),
              ),
              const SizedBox(width: AppTokens.s2),
            ],
            Expanded(
              child: Text(
                value,
                style: AppTypography.bodyStrong,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PanelLabel extends StatelessWidget {
  const _PanelLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 2,
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppTokens.s2),
        Text(label, style: AppTypography.overline),
      ],
    );
  }
}
