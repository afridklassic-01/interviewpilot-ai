import 'package:flutter/material.dart';

import '../../models/feedback.dart';
import '../../models/question.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';
import '../buttons/app_button.dart';
import '../cards/app_card.dart';
import '../common/pilot_chip.dart';
import '../progress/progress_bars.dart';
import '../progress/radial_score.dart';

/// Shown after an answer: the backend's evaluation with score, dimension
/// bars, strengths, missing concepts and feedback — plus the adaptive
/// follow-up preview when the backend generated one.
class EvaluationCard extends StatelessWidget {
  const EvaluationCard({
    super.key,
    required this.evaluation,
    required this.onContinue,
    required this.continueLabel,
  });

  final AnswerEvaluation evaluation;
  final VoidCallback onContinue;
  final String continueLabel;

  @override
  Widget build(BuildContext context) {
    final ev = evaluation;
    final hasFollowUp = ev.isFollowUp && ev.nextQuestion != null;

    return AppCard(
      hoverable: false,
      radius: AppTokens.r5 + 2,
      gradient: hasFollowUp
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.secondary.withValues(alpha: 0.09),
                AppColors.surface,
              ],
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppTokens.s2,
            runSpacing: AppTokens.s2,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Wrap(
                spacing: AppTokens.s2,
                runSpacing: AppTokens.s2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  assessmentBadge(_levelFor(ev.score)),
                  if (ev.answerQuality != null &&
                      ev.answerQuality!.isNotEmpty)
                    PilotChip(
                      ev.answerQuality!,
                      tone: PilotTone.info,
                      icon: Icons.verified_outlined,
                    ),
                ],
              ),
              Text('ANSWER EVALUATION', style: AppTypography.monoOverline),
            ],
          ),
          const SizedBox(height: AppTokens.s4),
          // Score + per-dimension bars.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              RadialScore(
                value: ev.score,
                size: 96,
                strokeWidth: 9,
                label: 'SCORE',
                suffix: '',
                color: AppColors.primaryBright,
              ),
              const SizedBox(width: AppTokens.s5),
              Expanded(
                child: Column(
                  children: [
                    SignalBar(
                      name: 'Technical Depth',
                      score: ev.technicalDepth,
                      trailing: _mono(ev.technicalDepth),
                    ),
                    const SizedBox(height: AppTokens.s3),
                    SignalBar(
                      name: 'Communication',
                      score: ev.communication,
                      trailing: _mono(ev.communication),
                    ),
                    const SizedBox(height: AppTokens.s3),
                    SignalBar(
                      name: 'Problem Solving',
                      score: ev.problemSolving,
                      trailing: _mono(ev.problemSolving),
                    ),
                    const SizedBox(height: AppTokens.s3),
                    SignalBar(
                      name: 'Architecture',
                      score: ev.architecture,
                      trailing: _mono(ev.architecture),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s5),
          if (ev.strengths.isNotEmpty) ...[
            Text('STRENGTHS', style: AppTypography.monoOverline),
            const SizedBox(height: AppTokens.s2),
            for (final s in ev.strengths) ...[
              _Bullet(
                icon: Icons.check_circle_rounded,
                color: AppColors.success,
                text: s,
              ),
              const SizedBox(height: AppTokens.s1 + 2),
            ],
            const SizedBox(height: AppTokens.s4),
          ],
          if (ev.missingConcepts.isNotEmpty) ...[
            Text('NEEDS IMPROVEMENT', style: AppTypography.monoOverline),
            const SizedBox(height: AppTokens.s2),
            for (final m in ev.missingConcepts) ...[
              _Bullet(
                icon: Icons.warning_amber_rounded,
                color: AppColors.warning,
                text: m,
              ),
              const SizedBox(height: AppTokens.s1 + 2),
            ],
            const SizedBox(height: AppTokens.s4),
          ],
          Text('FEEDBACK', style: AppTypography.monoOverline),
          const SizedBox(height: AppTokens.s2),
          Text(
            ev.feedback,
            style: AppTypography.bodyLarge.copyWith(height: 1.6),
          ),
          if (hasFollowUp) ...[
            const SizedBox(height: AppTokens.s5),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTokens.s4),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTokens.r4),
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
                        size: 15,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'Based on your previous answer',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  if (ev.followUpReason != null) ...[
                    const SizedBox(height: AppTokens.s2),
                    Text(
                      '“${ev.followUpReason}”',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppTokens.s3),
                  Text(
                    ev.nextQuestion!,
                    style: AppTypography.bodyStrong.copyWith(
                      fontSize: 15,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppTokens.s5),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: continueLabel,
                  variant: ButtonVariant.primary,
                  size: ButtonSize.large,
                  expand: true,
                  icon: Icons.arrow_forward_rounded,
                  onPressed: onContinue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mono(double score) => Text(
        '${score.round()}',
        style: AppTypography.monoOverline.copyWith(
          color: AppColors.primaryBright,
          fontWeight: FontWeight.w700,
        ),
      );

  static AssessmentLevel _levelFor(double score) {
    if (score >= 82) return AssessmentLevel.strong;
    if (score >= 64) return AssessmentLevel.good;
    return AssessmentLevel.needsImprovement;
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: AppTokens.s2),
        Expanded(
          child: Text(
            text,
            style: AppTypography.body.copyWith(height: 1.5),
          ),
        ),
      ],
    );
  }
}
