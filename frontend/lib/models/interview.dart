/// Lifecycle status of an interview session, driven by backend responses.
enum InterviewStatus {
  /// No interview has been started yet.
  idle,

  /// A question is being fetched from the backend (`POST /interview/start`
  /// or the next question after an answer).
  loadingQuestion,

  /// A question is displayed and the candidate is expected to answer.
  waitingForAnswer,

  /// The answer has been sent; the backend is evaluating it.
  submittingAnswer,

  /// The evaluation arrived and is displayed for review.
  evaluating,

  /// An adaptive follow-up question (derived from the previous answer) is
  /// displayed and awaiting an answer.
  showingFollowUp,

  /// All questions completed; the report can be generated.
  completed,

  /// Something went wrong; the UI offers a retry.
  error,
}

/// A live interview-performance indicator.
///
/// Scores are accumulated from the backend evaluations. Before the first
/// answer is evaluated, [score] is null and the UI shows a placeholder.
class InterviewSignal {
  const InterviewSignal({required this.name, this.score});

  final String name;
  final double? score;

  InterviewSignal copyWith({double? score}) =>
      InterviewSignal(name: name, score: score ?? this.score);
}

/// Coverage state of a curriculum topic within the interview.
enum CoverageState { covered, current, upcoming }

class TopicCoverage {
  const TopicCoverage({
    required this.topic,
    required this.state,
    this.questionCount = 0,
  });

  final String topic;
  final CoverageState state;
  final int questionCount;
}

/// Response of `POST /api/interview/start`.
///
/// The backend decides the first question and the total interview length;
/// the frontend never hard-codes the progression.
class InterviewStartData {
  const InterviewStartData({
    required this.sessionId,
    required this.questionNumber,
    required this.totalQuestions,
    required this.topic,
    required this.difficulty,
    required this.question,
    this.expectedFocus = const [],
    this.curriculumDay,
    this.curriculumTitle,
  });

  final String sessionId;
  final int questionNumber;
  final int totalQuestions;
  final String topic;
  final String difficulty;
  final String question;

  /// Areas the interviewer expects the answer to cover (NOT a rubric).
  final List<String> expectedFocus;

  /// Optional curriculum source (e.g. "12" -> "Day 12 — RAG").
  final String? curriculumDay;
  final String? curriculumTitle;

  factory InterviewStartData.fromJson(Map<String, dynamic> json) {
    return InterviewStartData(
      sessionId: json['session_id'] as String? ?? '',
      questionNumber: (json['question_number'] as num?)?.toInt() ?? 1,
      totalQuestions: (json['total_questions'] as num?)?.toInt() ?? 8,
      topic: json['topic'] as String? ?? 'General AI Systems',
      difficulty: json['difficulty'] as String? ?? 'Senior-level',
      question: json['question'] as String? ?? '',
      expectedFocus: _stringList(json['expected_focus']),
      curriculumDay: json['curriculum_day'] as String?,
      curriculumTitle: json['curriculum_title'] as String?,
    );
  }
}

/// Snapshot of the current interview state, mirroring
/// `GET /api/interview/{session_id}`.
class InterviewSessionData {
  const InterviewSessionData({
    required this.sessionId,
    required this.questionNumber,
    required this.totalQuestions,
    required this.topic,
    required this.difficulty,
    required this.question,
    this.status = InterviewStatus.waitingForAnswer,
    this.isFollowUp = false,
    this.basedOnAnswer,
  });

  final String sessionId;
  final int questionNumber;
  final int totalQuestions;
  final String topic;
  final String difficulty;
  final String question;
  final InterviewStatus status;
  final bool isFollowUp;
  final String? basedOnAnswer;

  factory InterviewSessionData.fromJson(Map<String, dynamic> json) {
    final status = switch (json['status'] as String?) {
      'loading' => InterviewStatus.loadingQuestion,
      'waiting_for_answer' => InterviewStatus.waitingForAnswer,
      'submitting' => InterviewStatus.submittingAnswer,
      'evaluating' => InterviewStatus.evaluating,
      'showing_follow_up' => InterviewStatus.showingFollowUp,
      'completed' => InterviewStatus.completed,
      _ => InterviewStatus.waitingForAnswer,
    };
    return InterviewSessionData(
      sessionId: json['session_id'] as String? ?? '',
      questionNumber: (json['question_number'] as num?)?.toInt() ?? 1,
      totalQuestions: (json['total_questions'] as num?)?.toInt() ?? 8,
      topic: json['topic'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? 'Senior-level',
      question: json['question'] as String? ?? '',
      status: status,
      isFollowUp: json['is_follow_up'] as bool? ?? false,
      basedOnAnswer: json['based_on_answer'] as String?,
    );
  }
}

List<String> _stringList(dynamic value) {
  if (value is! List) return const [];
  return value.whereType<String>().toList();
}
