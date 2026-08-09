import 'package:flutter/material.dart';

import '../../app.dart';
import '../../models/question.dart';
import '../../state/interview_session.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/common/app_background.dart';
import '../../widgets/common/app_top_nav.dart';
import '../../widgets/common/pilot_chip.dart';
import '../../widgets/common/state_views.dart';

/// Screen 6 — Question review.
///
/// Each question expands to reveal the candidate's answer, the observable
/// assessment and a constructive improvement hint. Hidden reasoning is
/// never exposed.
class QuestionReviewScreen extends StatefulWidget {
  const QuestionReviewScreen({super.key});

  @override
  State<QuestionReviewScreen> createState() => _QuestionReviewScreenState();
}

class _QuestionReviewScreenState extends State<QuestionReviewScreen> {
  final Set<String> _expanded = {};

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
                  label: 'Report',
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.results),
                ),
              ],
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: session,
                builder: (context, _) {
                  if (!session.hasSession || !session.isComplete) {
                    return const Padding(
                      padding: EdgeInsets.all(AppTokens.s6),
                      child: EmptyView(
                        icon: Icons.fact_check_outlined,
                        title: 'No questions to review',
                        message:
                            'Complete an interview to review every question '
                            'and your performance on it.',
                      ),
                    );
                  }

                  final questions = session.previousQuestions;
                  final answers = session.previousAnswers;
                  final rows = _zip(questions, answers);
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTokens.s6),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 860),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'QUESTION REVIEW',
                                        style: AppTypography.overline,
                                      ),
                                      SizedBox(height: AppTokens.s2),
                                      Text(
                                        'Every question, answered and assessed',
                                        style: AppTypography.headline,
                                      ),
                                    ],
                                  ),
                                ),
                                PilotChip(
                                  '${answers.length} answered',
                                  tone: PilotTone.success,
                                  icon: Icons.check_circle_outline_rounded,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTokens.s2),
                            Text(
                              'Assessments are based on observable interview '
                              'performance — coverage, structure and engineering '
                              'depth.',
                              style: AppTypography.caption,
                            ),
                            const SizedBox(height: AppTokens.s5),
                            for (final row in rows) ...[
                              _ReviewTile(
                                row: row,
                                expanded: _expanded.contains(row.question.id),
                                onToggle: () => setState(() {
                                  if (!_expanded.remove(row.question.id)) {
                                    _expanded.add(row.question.id);
                                  }
                                }),
                              ),
                              const SizedBox(height: AppTokens.s3),
                            ],
                            const SizedBox(height: AppTokens.s4),
                            Center(
                              child: Text(
                                '1 engineering profile · 4+ curriculum areas · '
                                'assessed without hidden reasoning',
                                style: AppTypography.caption,
                              ),
                            ),
                            const SizedBox(height: AppTokens.s8),
                          ],
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

  List<({InterviewQuestion question, CandidateAnswer? answer})> _zip(
    List<InterviewQuestion> questions,
    List<CandidateAnswer> answers,
  ) {
    return [
      for (final q in questions)
        (
          question: q,
          answer: _answerFor(answers, q.id),
        ),
    ];
  }

  CandidateAnswer? _answerFor(List<CandidateAnswer> answers, String id) {
    for (final a in answers) {
      if (a.questionId == id) return a;
    }
    return null;
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({
    required this.row,
    required this.expanded,
    required this.onToggle,
  });

  final ({InterviewQuestion question, CandidateAnswer? answer}) row;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final q = row.question;
    final a = row.answer;

    return AppCard(
      hoverable: false,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Collapsed header.
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Semantics(
              button: true,
              label: 'Review question ${q.id}',
              child: InkWell(
                onTap: onToggle,
                child: Padding(
                  padding: const EdgeInsets.all(AppTokens.s4),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: AppColors.brandGradient,
                          borderRadius: BorderRadius.circular(AppTokens.r3),
                        ),
                        child: Text(
                          q.id.toUpperCase().replaceFirst('Q', ''),
                          style: AppTypography.mono.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTokens.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    _shortLabel(q.prompt),
                                    style: AppTypography.bodyStrong,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (q.isFollowUp) ...[
                                  const SizedBox(width: AppTokens.s2),
                                  const Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 13,
                                    color: AppColors.secondary,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${q.topic} · ${q.difficulty.label}'
                              '${q.curriculumDay != null ? ' · Day ${q.curriculumDay}' : ''}',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppTokens.s3),
                      if (a != null)
                        assessmentBadge(a.assessment, compact: true)
                      else
                        const PilotChip('Unanswered', tone: PilotTone.danger),
                      const SizedBox(width: AppTokens.s2),
                      AnimatedRotation(
                        turns: expanded ? 0.5 : 0,
                        duration: AppTokens.medium,
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: AppTokens.medium,
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: expanded
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(
                      AppTokens.s4,
                      AppTokens.s2,
                      AppTokens.s4,
                      AppTokens.s5,
                    ),
                    child: _DetailBody(question: q, answer: a),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  String _shortLabel(String prompt) {
    final first = prompt.split(RegExp(r'[.?!]')).first.trim();
    return first.length > 64 ? '${first.substring(0, 61)}…' : first;
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.question, required this.answer});

  final InterviewQuestion question;
  final CandidateAnswer? answer;

  @override
  Widget build(BuildContext context) {
    final a = answer; // Local so null promotion applies inside the branches.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1, color: AppColors.borderFaint),
        const SizedBox(height: AppTokens.s4),
        if (question.isFollowUp) ...[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.s3,
              vertical: AppTokens.s2,
            ),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTokens.r3),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 13,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Adaptive follow-up from your previous answer',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s4),
        ],
        _Block(label: 'QUESTION', child: Text(question.prompt, style: AppTypography.bodyLarge)),
        const SizedBox(height: AppTokens.s4),
        _Block(
          label: 'TOPIC',
          child: Text(question.topic, style: AppTypography.bodyStrong),
        ),
        const SizedBox(height: AppTokens.s4),
        if (a == null)
          const _Block(
            label: 'ANSWER',
            child: Text('This question was not answered.', style: AppTypography.body),
          )
        else ...[
          _Block(
            label: 'CANDIDATE ANSWER',
            child: Text(a.text, style: AppTypography.bodyLarge.copyWith(height: 1.7)),
          ),
          const SizedBox(height: AppTokens.s4),
          Row(
            children: [
              Expanded(
                child: _Block(
                  label: 'PERFORMANCE ASSESSMENT',
                  child: Row(
                    children: [
                      assessmentBadge(a.assessment),
                      const SizedBox(width: AppTokens.s2 + 2),
                      Text(
                        '${a.score.round()}/100',
                        style: AppTypography.monoOverline.copyWith(
                          color: AppColors.primaryBright,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (a.strengths.isNotEmpty) ...[
            const SizedBox(height: AppTokens.s4),
            _Block(
              label: 'STRENGTHS',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final s in a.strengths)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppTokens.s1),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 15,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: AppTokens.s2),
                          Expanded(
                            child: Text(s, style: AppTypography.body),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (a.missingConcepts.isNotEmpty) ...[
            const SizedBox(height: AppTokens.s4),
            _Block(
              label: 'MISSING CONCEPTS',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final m in a.missingConcepts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppTokens.s1),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 15,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: AppTokens.s2),
                          Expanded(
                            child: Text(m, style: AppTypography.body),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (a.feedback != null || a.praise != null) ...[
            const SizedBox(height: AppTokens.s4),
            _Block(
              label: 'INTERVIEWER NOTE',
              child: Text(
                a.feedback ?? a.praise!,
                style: AppTypography.body,
              ),
            ),
          ],
          if (a.whatToImprove != null) ...[
            const SizedBox(height: AppTokens.s4),
            _Block(
              label: 'WHAT TO IMPROVE',
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.track_changes_rounded,
                    size: 15,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: AppTokens.s2),
                  Expanded(
                    child: Text(
                      a.whatToImprove!,
                      style: AppTypography.body,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.monoOverline),
        const SizedBox(height: AppTokens.s2),
        child,
      ],
    );
  }
}
