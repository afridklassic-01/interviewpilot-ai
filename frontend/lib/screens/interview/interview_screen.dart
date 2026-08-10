import 'package:flutter/material.dart';

import '../../app.dart';
import '../../mock/mock_curriculum.dart';
import '../../models/candidate.dart';
import '../../models/interview.dart';
import '../../models/question.dart';
import '../../state/interview_session.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';
import '../../widgets/common/app_background.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/common/confirm_dialog.dart';
import '../../widgets/common/logo_mark.dart';
import '../../widgets/common/pilot_chip.dart';
import '../../widgets/common/state_views.dart';
import '../../widgets/interview/answer_editor.dart';
import '../../widgets/interview/evaluation_card.dart';
import '../../widgets/interview/interviewer_panel.dart';
import '../../widgets/interview/learning_context_panel.dart';
import '../../widgets/interview/live_signals_panel.dart';
import '../../widgets/interview/question_card.dart';
import '../../widgets/progress/progress_bars.dart';

/// Screen 3 — the interview.
///
/// Desktop:  [learning context | interviewer + question + editor | live intelligence]
/// Mobile:   learning context -> main panel -> live signals -> topic coverage,
///           stacked in that order (expandable).
class InterviewScreen extends StatefulWidget {
  const InterviewScreen({super.key});

  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen> {
  bool _mobileContextOpen = true;
  bool _mobileSignalsOpen = false;
  InterviewSession? _session;
  bool _completedNavigated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = SessionScope.of(context);
    if (_session != session) {
      _session?.removeListener(_onSessionChanged);
      _session = session;
      _completedNavigated = false;
      session.addListener(_onSessionChanged);
      // Only run on first attach: this callback must not re-fire when the
      // session notifies (InheritedNotifier re-runs didChangeDependencies
      // on every notifyListeners, e.g. when the interview completes).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Ensure a session exists when arriving directly at /interview.
        if (!session.isStarted) {
          session.startInterview();
        } else if (session.isComplete) {
          // "Start AI Interview" again after a finished session: begin the
          // next incomplete topic. Completed topics are never restarted
          // automatically.
          session.startInterview();
        }
      });
    }
  }

  @override
  void dispose() {
    _session?.removeListener(_onSessionChanged);
    super.dispose();
  }

  /// Interview finished -> move to the completion screen (only once).
  void _onSessionChanged() {
    final session = _session;
    if (session != null &&
        session.isComplete &&
        mounted &&
        !_completedNavigated) {
      _completedNavigated = true;
      Navigator.of(context).pushReplacementNamed(AppRoutes.interviewComplete);
    }
  }

  Future<void> _confirmLeave(BuildContext context) async {
    final session = SessionScope.of(context);
    final active = session.status == InterviewStatus.waitingForAnswer ||
        session.status == InterviewStatus.submittingAnswer ||
        session.status == InterviewStatus.evaluating ||
        session.status == InterviewStatus.showingFollowUp;
    if (!active) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final navigator = Navigator.of(context);
    final leave = await showConfirmDialog(
      context,
      title: 'Leave active interview?',
      message:
          'Your answers in this session will be lost, and this topic will '
          'restart from question 1 next time. Completed topics and your '
          'progress are kept. Are you sure you want to exit?',
      confirmLabel: 'Leave interview',
      cancelLabel: 'Keep interviewing',
      destructive: true,
    );
    if (leave) {
      session.reset();
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final candidate = session.candidate;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave(context);
      },
      child: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              const _InterviewTopBar(),
              Expanded(
                child: ListenableBuilder(
                  listenable: session,
                  builder: (context, _) {
                    final question = session.currentQuestion;
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 1080;
                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(AppTokens.s5),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1440),
                              child: wide
                                  ? _desktopLayout(context, session, candidate, question)
                                  : _mobileLayout(context, session, candidate, question),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Layouts -----------------------------------------------------------

  Widget _desktopLayout(
    BuildContext context,
    InterviewSession session,
    Candidate? candidate,
    InterviewQuestion? question,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: AppTokens.leftPanelWidth,
          child: _panelScroll(
            child: question == null
                ? const SizedBox.shrink()
                : LearningContextPanel(
                    question: question,
                    signal: _curriculumSignal(question),
                    previousPerformance: _previousPerformance(candidate, question),
                  ),
          ),
        ),
        const SizedBox(width: AppTokens.s5),
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: _centerColumn(context, session, question),
          ),
        ),
        const SizedBox(width: AppTokens.s5),
        SizedBox(
          width: AppTokens.panelWidth,
          child: _panelScroll(
            child: Column(
              children: [
                LiveSignalsPanel(signals: session.signals),
                const SizedBox(height: AppTokens.s4),
                TopicCoveragePanel(
                  coverage: session.coverage,
                  answeredCount: session.answeredCount,
                  totalQuestions: session.totalQuestions,
                  curriculumCovered: _curriculumCovered(session),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _mobileLayout(
    BuildContext context,
    InterviewSession session,
    Candidate? candidate,
    InterviewQuestion? question,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1) Learning context (stacked first on mobile).
        _PanelToggle(
          label: 'Learning Context',
          icon: Icons.menu_book_outlined,
          open: _mobileContextOpen,
          onTap: () => setState(() {
            _mobileContextOpen = !_mobileContextOpen;
            if (_mobileContextOpen) _mobileSignalsOpen = false;
          }),
        ),
        AnimatedSize(
          duration: AppTokens.medium,
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: _mobileContextOpen && question != null
              ? Padding(
                  padding: const EdgeInsets.only(top: AppTokens.s4),
                  child: LearningContextPanel(
                    question: question,
                    signal: _curriculumSignal(question),
                    previousPerformance: _previousPerformance(candidate, question),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: AppTokens.s4),
        // 2) Main interview panel.
        _centerColumn(context, session, question),
        const SizedBox(height: AppTokens.s4),
        // 3) Live signals + topic coverage.
        _PanelToggle(
          label: 'Interview Intelligence',
          icon: Icons.monitor_heart_outlined,
          open: _mobileSignalsOpen,
          onTap: () => setState(() {
            _mobileSignalsOpen = !_mobileSignalsOpen;
            if (_mobileSignalsOpen) _mobileContextOpen = false;
          }),
        ),
        AnimatedSize(
          duration: AppTokens.medium,
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: _mobileSignalsOpen
              ? Padding(
                  padding: const EdgeInsets.only(top: AppTokens.s4),
                  child: Column(
                    children: [
                      LiveSignalsPanel(signals: session.signals),
                      const SizedBox(height: AppTokens.s4),
                      TopicCoveragePanel(
                        coverage: session.coverage,
                        answeredCount: session.answeredCount,
                        totalQuestions: session.totalQuestions,
                        curriculumCovered: _curriculumCovered(session),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _panelScroll({required Widget child}) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 720),
      child: SingleChildScrollView(child: child),
    );
  }

  // ---- Center column -----------------------------------------------------

  Widget _centerColumn(
    BuildContext context,
    InterviewSession session,
    InterviewQuestion? question,
  ) {
    final status = session.status;

    final (statusText, thinking) = switch (status) {
      InterviewStatus.idle => ('Ready to begin', false),
      InterviewStatus.loadingQuestion => ('Preparing your interview…', true),
      InterviewStatus.waitingForAnswer => ('Ready for your answer', false),
      InterviewStatus.submittingAnswer => ('Analyzing your response...', true),
      InterviewStatus.evaluating => (
          session.lastEvaluation?.isFollowUp == true
              ? 'Preparing your follow-up...'
              : 'Response evaluated',
          false,
        ),
      InterviewStatus.showingFollowUp =>
        ('Follow-up based on your previous answer', false),
      InterviewStatus.completed => ('Finalizing your engineering report…', true),
      InterviewStatus.error => ('Connection issue', false),
    };

    final wide = MediaQuery.of(context).size.width >= 1080;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InterviewerHeader(status: statusText, thinking: thinking),
        const SizedBox(height: AppTokens.s4),
        AnimatedSwitcher(
          duration: AppTokens.medium,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.02, 0.02),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: _phaseContent(
            key: ValueKey('${status.name}-${session.questionNumber}'),
            status: status,
            session: session,
            question: question,
            wide: wide,
          ),
        ),
      ],
    );
  }

  Widget _phaseContent({
    required Key key,
    required InterviewStatus status,
    required InterviewSession session,
    required InterviewQuestion? question,
    required bool wide,
  }) {
    return KeyedSubtree(
      key: key,
      child: switch (status) {
        InterviewStatus.idle || InterviewStatus.loadingQuestion =>
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppTokens.s12),
            child: LoadingView(
              label: 'Building your adaptive interview…',
              subtitle: 'The backend is preparing your first question from '
                  'your learning journey.',
            ),
          ),
        InterviewStatus.error => Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTokens.s8),
            child: _ErrorPanel(
              submitError: session.isSubmitError,
              message: session.error,
              onRetry: session.retryLastAction,
              onBackToDashboard: () => _backToDashboard(context),
            ),
          ),
        InterviewStatus.submittingAnswer || InterviewStatus.waitingForAnswer ||
        InterviewStatus.showingFollowUp =>
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (question != null) ...[
                QuestionCard(
                  question: question,
                  index: session.questionNumber - 1,
                  total: session.totalQuestions,
                ),
                const SizedBox(height: AppTokens.s4),
              ],
              if (status == InterviewStatus.submittingAnswer)
                const _EvaluatingPanel()
              else if (question != null)
                AnswerEditor(
                  key: ValueKey('editor-${session.questionNumber}'),
                  onSubmit: session.submitAnswer,
                  enabled: status == InterviewStatus.waitingForAnswer ||
                      status == InterviewStatus.showingFollowUp,
                  busy: false,
                  autofocus: wide,
                ),
            ],
          ),
        InterviewStatus.evaluating => Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTokens.s3),
            child: EvaluationCard(
              evaluation: session.lastEvaluation!,
              onContinue: session.continueToNext,
              continueLabel: session.awaitingCompletion
                  ? 'Complete Interview'
                  : 'Continue to Question ${session.questionNumber + 1}',
            ),
          ),
        InterviewStatus.completed => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppTokens.s12),
            child: LoadingView(
              label: 'Scoring your responses…',
              subtitle: 'Generating your engineering report.',
            ),
          ),
      },
    );
  }

  void _backToDashboard(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.dashboard,
      (route) => route.isFirst,
    );
  }

  // ---- Context helpers ---------------------------------------------------

  String? _curriculumSignal(InterviewQuestion q) {
    final day = int.tryParse(q.curriculumDay ?? '');
    return day == null ? null : MockCurriculum.byDay(day)?.signal;
  }

  String? _previousPerformance(Candidate? candidate, InterviewQuestion q) {
    if (candidate == null) return null;
    final skill = candidate.skillBy(q.topic);
    if (skill == null) return null;
    if (skill.score >= 80) return 'Strong';
    if (skill.score >= 65) return 'Good';
    return 'Needs review';
  }

  int _curriculumCovered(InterviewSession session) {
    return session.coverage
        .where((c) => c.state == CoverageState.covered)
        .length;
  }
}

// ---- Error panel ----------------------------------------------------------

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({
    required this.submitError,
    required this.message,
    required this.onRetry,
    required this.onBackToDashboard,
  });

  final bool submitError;
  final String? message;
  final VoidCallback onRetry;
  final VoidCallback onBackToDashboard;

  @override
  Widget build(BuildContext context) {
    final title = submitError
        ? "Couldn't evaluate your answer."
        : 'Interview service unavailable';
    final detail = submitError
        ? (message ?? 'The backend did not respond while evaluating your '
            'answer. Your answer is safe and will be resubmitted.')
        : (message ?? 'Check that the FastAPI backend is running and try '
            'again.');

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(AppTokens.s6),
        decoration: AppDecor.glass(radius: AppTokens.r5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: AppColors.danger,
                size: 24,
              ),
            ),
            const SizedBox(height: AppTokens.s4),
            Text(title, style: AppTypography.title, textAlign: TextAlign.center),
            const SizedBox(height: AppTokens.s2),
            Text(
              detail,
              style: AppTypography.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.s6),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: submitError ? 'Retry Answer' : 'Retry',
                    icon: Icons.refresh_rounded,
                    expand: true,
                    onPressed: onRetry,
                  ),
                ),
                const SizedBox(width: AppTokens.s3),
                AppButton(
                  label: 'Back to Dashboard',
                  variant: ButtonVariant.ghost,
                  icon: Icons.dashboard_outlined,
                  onPressed: onBackToDashboard,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Top bar -------------------------------------------------------------

class _InterviewTopBar extends StatelessWidget {
  const _InterviewTopBar();

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);

    return Container(
      height: AppTokens.navHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.s6),
      decoration: const BoxDecoration(
        color: Color(0x66070B14),
        border: Border(bottom: BorderSide(color: AppColors.borderFaint)),
      ),
      child: ListenableBuilder(
        listenable: session,
        builder: (context, _) {
          final question = session.currentQuestion;
          final status = session.status;
          final hasSession = session.hasSession &&
              status != InterviewStatus.loadingQuestion &&
              status != InterviewStatus.idle;
          return Row(
            children: [
              const LogoMark(size: 26, showWordmark: true),
              const SizedBox(width: AppTokens.s5),
              Container(
                width: 1,
                height: 22,
                color: AppColors.borderStrong,
              ),
              const SizedBox(width: AppTokens.s5),
              const Text('Technical Interview', style: AppTypography.title),
              const SizedBox(width: AppTokens.s4),
              // Right-side cluster scrolls horizontally so the bar can never
              // overflow on narrow viewports (exit stays pinned right).
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasSession) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTokens.s3,
                            vertical: AppTokens.s1 + 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSunken,
                            borderRadius: BorderRadius.circular(AppTokens.r2),
                          ),
                          child: Text(
                            'Question ${session.questionNumber} / ${session.totalQuestions}',
                            style: AppTypography.monoOverline.copyWith(
                              color: AppColors.primaryBright,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTokens.s4),
                        SizedBox(
                          width: 160,
                          child: SegmentedProgress(
                            total: session.totalQuestions,
                            completed: session.answeredCount,
                            current:
                                status == InterviewStatus.waitingForAnswer ||
                                        status == InterviewStatus.showingFollowUp ||
                                        status == InterviewStatus.submittingAnswer
                                    ? session.questionNumber - 1
                                    : null,
                          ),
                        ),
                        const SizedBox(width: AppTokens.s4),
                      ],
                      if (question != null) ...[
                        PilotChip(
                          question.topic,
                          tone: question.isFollowUp
                              ? PilotTone.accent
                              : PilotTone.info,
                          icon: question.isFollowUp
                              ? Icons.auto_awesome_rounded
                              : Icons.category_outlined,
                        ),
                        const SizedBox(width: AppTokens.s2),
                        if (MediaQuery.of(context).size.width >= 560) ...[
                          PilotChip(
                            question.difficulty.label,
                            tone: PilotTone.primary,
                            icon: Icons.trending_up_rounded,
                          ),
                          const SizedBox(width: AppTokens.s3),
                        ],
                      ],
                      IconButton(
                        onPressed: () {
                          final s = SessionScope.of(context);
                          _confirmLeaveFromBar(context, s);
                        },
                        tooltip: 'End interview',
                        icon: const Icon(
                          Icons.logout_rounded,
                          size: 18,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

Future<void> _confirmLeaveFromBar(BuildContext context, InterviewSession s) async {
  final active = s.status == InterviewStatus.waitingForAnswer ||
      s.status == InterviewStatus.submittingAnswer ||
      s.status == InterviewStatus.evaluating ||
      s.status == InterviewStatus.showingFollowUp;
  if (!active) {
    if (context.mounted) Navigator.of(context).pop();
    return;
  }
  final navigator = Navigator.of(context);
  final leave = await showConfirmDialog(
    context,
    title: 'Leave active interview?',
    message:
        'Your answers in this session will be lost, and this topic will '
        'restart from question 1 next time. Completed topics and your '
        'progress are kept. Are you sure you want to exit?',
    confirmLabel: 'Leave interview',
    cancelLabel: 'Keep interviewing',
    destructive: true,
  );
  if (leave) {
    s.reset();
    if (context.mounted) navigator.pop();
  }
}

// ---- Analyzing indicator ------------------------------------------------

class _EvaluatingPanel extends StatelessWidget {
  const _EvaluatingPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s5),
      decoration: AppDecor.glass(radius: AppTokens.r5),
      child: Column(
        children: [
          const _PulseRow(),
          const SizedBox(height: AppTokens.s4),
          Text(
            'Analyzing your response...',
            style: AppTypography.title,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTokens.s2),
          Text(
            'Scoring technical depth, communication, problem solving and '
            'architecture — then deciding your next question.',
            style: AppTypography.body,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PulseRow extends StatefulWidget {
  const _PulseRow();

  @override
  State<_PulseRow> createState() => _PulseRowState();
}

class _PulseRowState extends State<_PulseRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final phase = (_controller.value * 2 + i * 0.35) % 1;
            final scale = 0.6 + 0.4 * (1 - (phase - 0.5).abs() * 2).clamp(0.0, 1.0);
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: const BoxDecoration(
                  gradient: AppColors.brandGradient,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _PanelToggle extends StatelessWidget {
  const _PanelToggle({
    required this.label,
    required this.icon,
    required this.open,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: label,
      icon: open ? Icons.keyboard_arrow_up_rounded : icon,
      variant: open ? ButtonVariant.secondary : ButtonVariant.ghost,
      size: ButtonSize.medium,
      expand: true,
      onPressed: onTap,
    );
  }
}
