import 'package:flutter/material.dart';

import '../../models/question.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';
import '../cards/app_card.dart';
import '../common/pilot_chip.dart';

/// The current interview question with expected-focus hints.
///
/// The "expected focus" chips hint at the areas a senior answer covers —
/// they never reveal the correct answer.
class QuestionCard extends StatelessWidget {
  const QuestionCard({
    super.key,
    required this.question,
    required this.index,
    required this.total,
  });

  final InterviewQuestion question;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    final isFollowUp = question.isFollowUp;

    return AppCard(
      hoverable: false,
      radius: AppTokens.r5 + 2,
      gradient: isFollowUp
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.secondary.withValues(alpha: 0.1),
                AppColors.surface,
                AppColors.primary.withValues(alpha: 0.05),
              ],
              stops: const [0, 0.45, 1],
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wrap keeps the topic chip from overflowing the card on narrow
          // widths: it drops to its own line instead of clipping.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppTokens.s2,
            runSpacing: AppTokens.s2,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.s2 + 2,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppTokens.r2),
                ),
                child: Text(
                  'QUESTION ${index + 1} / $total',
                  style: AppTypography.monoOverline.copyWith(
                    color: AppColors.primaryBright,
                  ),
                ),
              ),
              PilotChip(
                question.topic,
                tone: isFollowUp ? PilotTone.accent : PilotTone.neutral,
                icon: isFollowUp
                    ? Icons.auto_awesome_rounded
                    : Icons.category_outlined,
              ),
            ],
          ),
          if (isFollowUp) ...[
            const SizedBox(height: AppTokens.s4),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.s3,
                vertical: AppTokens.s2,
              ),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTokens.r3),
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.link_rounded,
                    size: 14,
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
            ),
          ],
          if (question.basedOnAnswer != null &&
              question.basedOnAnswer!.isNotEmpty) ...[
            const SizedBox(height: AppTokens.s2),
            Text(
              '“${question.basedOnAnswer}”',
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: AppTokens.s4),
          Text(question.prompt, style: AppTypography.bodyLarge.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            height: 1.6,
          )),
          const SizedBox(height: AppTokens.s5),
          Text('Expected focus', style: AppTypography.monoOverline),
          const SizedBox(height: AppTokens.s2),
          Wrap(
            spacing: AppTokens.s2,
            runSpacing: AppTokens.s2,
            children: [
              for (final focus in question.expectedFocus)
                PilotChip(
                  focus,
                  tone: PilotTone.primary,
                  icon: Icons.horizontal_rule_rounded,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
