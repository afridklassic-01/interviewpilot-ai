import 'package:flutter/widgets.dart';

import '../models/candidate.dart';
import '../models/feedback.dart';
import '../models/interview.dart';
import '../models/question.dart';
import '../mock/mock_candidate.dart';
import '../mock/mock_interview.dart';
import '../services/interview_api_service.dart';
import '../services/report_builder.dart';
import 'topic_progress.dart';

/// App-wide interview session controller.
///
/// Owns the candidate profile, the live adaptive-interview state and the
/// final report, and drives the status state machine consumed by every
/// screen. All interview data comes from [InterviewApiService] (mock or
/// real FastAPI backend) — the UI never hard-codes questions, scores or
/// progression.
class InterviewSession extends ChangeNotifier {
  InterviewSession({InterviewApiService? api})
      : _api = api ?? createInterviewApiService();

  final InterviewApiService _api;

  Candidate? _candidate;
  InterviewReport? _report;

  // ---- Backend-driven interview state ------------------------------------
  String? _sessionId;
  InterviewQuestion? _currentQuestion;
  InterviewQuestion? _pendingNext;
  bool _pendingIsFollowUp = false;

  int _questionNumber = 0;
  int _totalQuestions = 8;
  String _currentTopic = '';
  String _difficulty = '';
  String _candidateAnswer = '';

  InterviewStatus _status = InterviewStatus.idle;
  String? _error;
  AnswerEvaluation? _lastEvaluation;
  bool _started = false;

  // ---- Accumulated history ------------------------------------------------
  final List<InterviewQuestion> _previousQuestions = [];
  final List<CandidateAnswer> _previousAnswers = [];
  final List<AnswerEvaluation> _evaluations = [];
  final Set<int> _coveredCurriculumDays = {};

  /// Persisted per-topic progress (survives refresh).
  final TopicProgressStore _topicProgress = TopicProgressStore();

  /// Topic explicitly chosen by the user (retry / start next topic) that
  /// the next [startInterview] call must use.
  String? _pendingTopic;

  // ---- Getters -----------------------------------------------------------
  Candidate? get candidate => _candidate;
  InterviewReport? get report => _report;
  String? get sessionId => _sessionId;
  InterviewQuestion? get currentQuestion => _currentQuestion;
  InterviewStatus get status => _status;
  String? get error => _error;
  AnswerEvaluation? get lastEvaluation => _lastEvaluation;

  /// True once [startInterview] has been invoked (in-flight, done or failed).
  bool get isStarted => _started;
  bool get hasSession => _sessionId != null;
  bool get isComplete => _status == InterviewStatus.completed;
  bool get isUnfinished =>
      _sessionId != null &&
      _status != InterviewStatus.completed &&
      _status != InterviewStatus.error;

  // ---- Position / progress ------------------------------------------------
  /// 1-based number of the current question.
  int get questionNumber => _questionNumber;
  int get totalQuestions => _totalQuestions;

  /// Total question count (kept for compatibility with existing screens).
  int get questionCount => _totalQuestions;
  String get currentTopic => _currentTopic;
  String get difficultyLabel => _difficulty;

  /// 0-based index of the current question (kept for compatibility).
  int get currentIndex => _questionNumber - 1;

  /// Number of evaluated answers so far.
  int get answeredCount => _evaluations.length;
  int get remainingQuestions => (totalQuestions - answeredCount).clamp(0, totalQuestions);

  /// True when the displayed question is the final one.
  bool get isLastQuestion => _questionNumber >= _totalQuestions;

  /// True while the final evaluation card is shown (awaiting "Complete").
  bool get awaitingCompletion =>
      _status == InterviewStatus.evaluating && _pendingNext == null;

  /// True when the last failure happened while submitting an answer
  /// (distinguishes "couldn't evaluate" from "service unavailable").
  bool get isSubmitError =>
      _status == InterviewStatus.error && _candidateAnswer.trim().isNotEmpty;

  // ---- History -------------------------------------------------------------
  List<InterviewQuestion> get previousQuestions =>
      List.unmodifiable(_previousQuestions);
  List<CandidateAnswer> get previousAnswers => List.unmodifiable(_previousAnswers);
  List<AnswerEvaluation> get evaluations => List.unmodifiable(_evaluations);
  List<int> get coveredCurriculumDays => List.unmodifiable(_coveredCurriculumDays.toList()..sort());
  /// Topics whose full interview has been finished (persisted across
  /// sessions — a completed topic is never restarted automatically).
  List<String> get completedTopics => [
        for (final t in MockInterviewData.topicOrder)
          if (_topicProgress.statusOf(t) == TopicStatus.completed) t,
      ];

  /// Persisted status of a topic (NOT_STARTED / IN_PROGRESS / COMPLETED).
  TopicStatus topicStatus(String topic) => _topicProgress.statusOf(topic);

  Map<String, TopicStatus> get topicStatuses => _topicProgress.statuses;

  /// First topic in curriculum order that is not yet COMPLETED — the topic
  /// the next normal interview uses. Null when everything is complete.
  String? get nextIncompleteTopic {
    for (final t in MockInterviewData.topicOrder) {
      if (_topicProgress.statusOf(t) != TopicStatus.completed) return t;
    }
    return null;
  }

  bool get hasNextTopic => nextIncompleteTopic != null;

  String get firstTopic => MockInterviewData.topicOrder.isNotEmpty
      ? MockInterviewData.topicOrder.first
      : 'RAG';
  String get candidateAnswer => _candidateAnswer;
  String? get followUpReason => _lastEvaluation?.followUpReason;

  /// Backend-driven dimension scores, accumulated across evaluations.
  /// Null before the first evaluation — the UI shows placeholders.
  List<InterviewSignal> get signals {
    const names = [
      'Technical Depth',
      'Communication',
      'Problem Solving',
      'Architecture',
    ];
    if (_evaluations.isEmpty) {
      return [for (final n in names) InterviewSignal(name: n, score: null)];
    }
    return [
      for (final n in names)
        InterviewSignal(
          name: n,
          score: _evaluations
                  .map((e) => e.dimensionFor(n) ?? 0)
                  .reduce((a, b) => a + b) /
              _evaluations.length,
        ),
    ];
  }

  /// Topic coverage derived from persisted progress + the current topic.
  List<TopicCoverage> get coverage {
    final current = _currentTopic;
    final topics = <String>[...MockInterviewData.topicOrder];
    if (current.isNotEmpty && !topics.contains(current)) topics.add(current);
    return [
      for (final t in topics)
        TopicCoverage(
          topic: t,
          state: _topicProgress.statusOf(t) == TopicStatus.completed
              ? CoverageState.covered
              : (t == current
                  ? CoverageState.current
                  : CoverageState.upcoming),
          questionCount: _topicProgress.statusOf(t) == TopicStatus.completed
              ? 8
              : (t == current ? _evaluations.length : 0),
        ),
    ];
  }

  // ---- Candidate ---------------------------------------------------------
  Future<void> loadCandidate() async {
    await _loadCandidateOrFallback();
    notifyListeners();
  }

  /// Loads the candidate profile; falls back to the mock profile when the
  /// backend profile endpoint is unreachable or not yet implemented.
  Future<void> _loadCandidateOrFallback() async {
    if (_candidate != null) return;
    try {
      _candidate = await _api.fetchCandidate(MockCandidate.id);
    } catch (_) {
      _candidate = MockCandidate.data; // Offline fallback keeps demo alive.
    }
  }

  // ---- Start --------------------------------------------------------------
  /// Calls `POST /api/interview/start` and loads the first question for the
  /// selected topic.
  ///
  /// Topic resolution order:
  ///   1. explicit [topic] (retry / start-next-topic actions),
  ///   2. [_pendingTopic] set by [retryTopic] / [startNextTopic],
  ///   3. the next INCOMPLETE topic in curriculum order (normal start),
  ///   4. the first topic when everything is already complete.
  ///
  /// A normal start NEVER resets completed topics — it simply skips them.
  Future<void> startInterview({String? topic, String focus = ''}) async {
    await _topicProgress.ensureLoaded();
    final target = topic ?? _pendingTopic ?? nextIncompleteTopic ?? firstTopic;
    _pendingTopic = null;

    // A new interview clears the previous session's working state but keeps
    // the persisted topic progress (completed topics are never lost).
    _sessionId = null;
    _currentQuestion = null;
    _pendingNext = null;
    _questionNumber = 0;
    _totalQuestions = 8;
    _candidateAnswer = '';
    _lastEvaluation = null;
    _report = null;
    _previousQuestions.clear();
    _previousAnswers.clear();
    _evaluations.clear();
    _coveredCurriculumDays.clear();

    _started = true;
    _status = InterviewStatus.loadingQuestion;
    _error = null;
    notifyListeners();
    try {
      // The candidate profile is best-effort: a missing /candidate endpoint
      // must never block the interview start endpoint.
      await _loadCandidateOrFallback();
      final start = await _api.startInterview(
        candidateId: _candidate?.id ?? MockCandidate.id,
        focus: focus.isEmpty ? MockInterviewData.focus : focus,
        topic: target,
      );
      _sessionId = start.sessionId;
      _totalQuestions = start.totalQuestions > 0 ? start.totalQuestions : 8;
      _currentTopic = start.topic;
      _difficulty = start.difficulty;
      _currentQuestion = _questionFromStart(start);
      _questionNumber = start.questionNumber;
      _pendingNext = null;
      await _topicProgress.set(_currentTopic, TopicStatus.inProgress);
      _status = InterviewStatus.waitingForAnswer;
    } catch (e) {
      _status = InterviewStatus.error;
      _error = 'Interview service unavailable. Check that the backend is '
          'running and reachable.';
      debugPrint('startInterview failed: $e');
    }
    notifyListeners();
  }

  // ---- Answer submission ---------------------------------------------------
  /// Sends the answer to `POST /api/interview/answer`, then shows the
  /// evaluation. Does NOT auto-advance: the candidate reviews the feedback
  /// and continues (or completes) explicitly.
  Future<void> submitAnswer(String text) async {
    final q = _currentQuestion;
    if (q == null) return;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    // Re-entry is also allowed from the error state when retrying a failed
    // submission (the candidate's answer is preserved for the retry).
    final isRetry = _status == InterviewStatus.error && _candidateAnswer.isNotEmpty;
    if (_status != InterviewStatus.waitingForAnswer &&
        _status != InterviewStatus.showingFollowUp &&
        !isRetry) {
      return;
    }

    _candidateAnswer = trimmed;
    _status = InterviewStatus.submittingAnswer;
    _error = null;
    notifyListeners();

    try {
      final ev = await _api.submitAnswer(
        sessionId: _sessionId!,
        question: q.prompt,
        answer: trimmed,
        topic: q.topic,
        questionNumber: _questionNumber,
        difficulty: q.difficulty.label,
        expectedFocus: q.expectedFocus,
      );

      _recordEvaluation(q, ev);

      // The backend decides whether there is a next question and whether it
      // is an adaptive follow-up.
      if (ev.nextQuestion != null && !isLastQuestion) {
        _pendingNext = _questionFromEvaluation(ev);
        _pendingIsFollowUp = ev.isFollowUp;
        _status = InterviewStatus.evaluating;
      } else {
        // Interview complete — stay on the evaluation card with "Complete".
        _pendingNext = null;
        _status = InterviewStatus.evaluating;
      }
      _candidateAnswer = '';
    } catch (e) {
      _status = InterviewStatus.error;
      _error = "Couldn't evaluate your answer.";
      debugPrint('submitAnswer failed: $e');
    }
    notifyListeners();
  }

  void _recordEvaluation(InterviewQuestion q, AnswerEvaluation ev) {
    _lastEvaluation = ev;
    _previousQuestions.add(q);
    _previousAnswers.add(CandidateAnswer(
      questionId: q.id,
      text: _candidateAnswer.trim(),
      assessment: _levelFor(ev.score),
      score: ev.score,
      praise: ev.feedback,
      whatToImprove: _improveHint(ev),
      isFollowUpTriggered: ev.isFollowUp,
      strengths: ev.strengths,
      missingConcepts: ev.missingConcepts,
      feedback: ev.feedback,
    ));
    _evaluations.add(ev);
    final day = int.tryParse(q.curriculumDay ?? '');
    if (day != null) _coveredCurriculumDays.add(day);
  }

  /// Moves from the evaluation review to the next question, or completes.
  void continueToNext() {
    if (_status != InterviewStatus.evaluating) return;
    if (awaitingCompletion || _pendingNext == null) {
      completeInterview();
      return;
    }
    _currentQuestion = _pendingNext;
    _pendingNext = null;
    _currentTopic = _currentQuestion?.topic ?? _currentTopic;
    _questionNumber += 1;
    _status =
        _pendingIsFollowUp ? InterviewStatus.showingFollowUp : InterviewStatus.waitingForAnswer;
    _pendingIsFollowUp = false;
    notifyListeners();
  }

  /// Calls `POST /api/interview/complete` and moves to the completed state.
  ///
  /// Finishing the full question run marks the CURRENT topic COMPLETED and
  /// persists it, so a normal "Start Interview" moves on to the next
  /// incomplete topic instead of repeating this one.
  Future<void> completeInterview() async {
    if (_status != InterviewStatus.evaluating &&
        _status != InterviewStatus.showingFollowUp &&
        _status != InterviewStatus.waitingForAnswer) {
      return;
    }
    try {
      await _api.completeInterview(_sessionId!);
    } catch (_) {
      // Completion notification failure must not block the success moment.
    }
    await _topicProgress.ensureLoaded();
    if (_currentTopic.isNotEmpty) {
      await _topicProgress.set(_currentTopic, TopicStatus.completed);
    }
    _status = InterviewStatus.completed;
    notifyListeners();
    await loadReport();
  }

  /// Loads the authoritative report from `GET /api/interview/{id}/feedback`;
  /// falls back to aggregating the recorded evaluations locally.
  Future<void> loadReport() async {
    InterviewReport? backend;
    try {
      backend = await _api.getFeedback(_sessionId!);
    } catch (_) {
      backend = null;
    }
    _report = backend ?? _buildLocalReport();
    notifyListeners();
  }

  InterviewReport _buildLocalReport() => ReportBuilder.build(
        evaluations: _evaluations,
        questions: _previousQuestions,
        answers: _previousAnswers,
        previousTrend: _candidate?.previousInterview.trend ?? const [],
      );

  /// Retries the last failed action (answer submission or interview start).
  void retryLastAction() {
    if (isSubmitError) {
      final pending = _candidateAnswer;
      if (pending.isNotEmpty) {
        submitAnswer(pending);
      }
    } else if (_status == InterviewStatus.error) {
      startInterview(
        topic: _currentTopic.isEmpty ? null : _currentTopic,
      );
    }
  }

  // ---- Topic actions -------------------------------------------------------
  /// Explicitly restarts the given (typically just-completed) topic.
  ///
  /// "Retry Interview" — intentionally repeats a topic; it does not reset
  /// any other progress.
  void retryTopic(String topic) {
    _pendingTopic = topic;
    reset();
  }

  /// Moves to the next incomplete topic (or the first topic when every
  /// topic is complete). "Start Next Topic".
  void startNextTopic() {
    _pendingTopic = nextIncompleteTopic ?? firstTopic;
    reset();
  }

  /// Explicitly wipes ALL topic progress ("Reset Progress") and the current
  /// session. Normal interview starts never do this.
  Future<void> resetAllProgress() async {
    _pendingTopic = null;
    await _topicProgress.ensureLoaded();
    await _topicProgress.clear();
    reset();
  }

  // ---- Reset ---------------------------------------------------------------
  /// Clears the current session only. Persisted topic progress and any
  /// user-chosen pending topic are intentionally kept.
  void reset() {
    _sessionId = null;
    _currentQuestion = null;
    _pendingNext = null;
    _questionNumber = 0;
    _totalQuestions = 8;
    _currentTopic = '';
    _difficulty = '';
    _candidateAnswer = '';
    _status = InterviewStatus.idle;
    _error = null;
    _lastEvaluation = null;
    _report = null;
    _started = false;
    _previousQuestions.clear();
    _previousAnswers.clear();
    _evaluations.clear();
    _coveredCurriculumDays.clear();
    notifyListeners();
  }

  // ---- Helpers -------------------------------------------------------------
  InterviewQuestion _questionFromStart(InterviewStartData start) {
    return InterviewQuestion(
      id: 'q${start.questionNumber}',
      topic: start.topic,
      prompt: start.question,
      difficulty: Difficulty.fromLabel(start.difficulty),
      expectedFocus: start.expectedFocus,
      curriculumDay: start.curriculumDay,
      curriculumTitle: start.curriculumTitle,
    );
  }

  InterviewQuestion _questionFromEvaluation(AnswerEvaluation ev) {
    return InterviewQuestion(
      id: 'q${_questionNumber + 1}${ev.isFollowUp ? '-followup' : ''}',
      topic: ev.nextTopic ?? _currentTopic,
      prompt: ev.nextQuestion ?? '',
      difficulty: Difficulty.fromLabel(ev.nextDifficulty),
      expectedFocus: const [],
      isFollowUp: ev.isFollowUp,
      basedOnAnswer: ev.isFollowUp ? (ev.followUpReason ?? _lastEvaluation?.followUpReason) : null,
      curriculumDay: ev.curriculumDay ?? _currentQuestion?.curriculumDay,
      curriculumTitle: ev.curriculumTitle ?? _currentQuestion?.curriculumTitle,
    );
  }

  static AssessmentLevel _levelFor(double score) {
    if (score >= 82) return AssessmentLevel.strong;
    if (score >= 64) return AssessmentLevel.good;
    return AssessmentLevel.needsImprovement;
  }

  static String _improveHint(AnswerEvaluation ev) {
    if (ev.missingConcepts.isEmpty) {
      return 'Keep this depth; extend answers to operational and cost trade-offs.';
    }
    return 'Add: ${ev.missingConcepts.take(2).join(', ')}.';
  }
}

/// Exposes the shared [InterviewSession] to the widget tree.
class SessionScope extends InheritedNotifier<InterviewSession> {
  const SessionScope({
    super.key,
    required InterviewSession session,
    required super.child,
  }) : super(notifier: session);

  static InterviewSession of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SessionScope>();
    assert(scope != null, 'SessionScope not found in the widget tree');
    return scope!.notifier!;
  }
}
