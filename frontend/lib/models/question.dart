/// Difficulty of an interview question.
enum Difficulty {
  midLevel('Mid-level'),
  senior('Senior-level'),
  staff('Staff-level');

  const Difficulty(this.label);
  final String label;

  /// Parses a backend label (e.g. "Senior-level") into an enum value.
  static Difficulty fromLabel(String? label) {
    if (label == null) return Difficulty.senior;
    final l = label.toLowerCase();
    if (l.contains('mid') || l.contains('junior')) return Difficulty.midLevel;
    if (l.contains('staff')) return Difficulty.staff;
    return Difficulty.senior;
  }
}

/// How the candidate performed on a question.
enum AssessmentLevel {
  strong('Strong'),
  good('Good'),
  needsImprovement('Needs improvement');

  const AssessmentLevel(this.label);
  final String label;
}

/// An interview question asked by the adaptive interviewer.
class InterviewQuestion {
  const InterviewQuestion({
    required this.id,
    required this.topic,
    required this.prompt,
    required this.difficulty,
    this.expectedFocus = const [],
    this.curriculumDay,
    this.curriculumTitle,
    this.isFollowUp = false,
    this.basedOnAnswer,
  });

  final String id;
  final String topic;

  /// The question text shown to the candidate.
  final String prompt;

  final Difficulty difficulty;

  /// Areas the interviewer expects the answer to cover (NOT a rubric/answer).
  final List<String> expectedFocus;

  /// Curriculum source: e.g. "Day 12 — Retrieval-Augmented Generation".
  final String? curriculumDay;
  final String? curriculumTitle;

  /// True when this question was adaptively generated from the previous answer.
  final bool isFollowUp;

  /// Optional quote of the candidate phrase this follow-up derives from.
  final String? basedOnAnswer;

  InterviewQuestion copyWith({
    bool? isFollowUp,
    String? basedOnAnswer,
  }) {
    return InterviewQuestion(
      id: id,
      topic: topic,
      prompt: prompt,
      difficulty: difficulty,
      expectedFocus: expectedFocus,
      curriculumDay: curriculumDay,
      curriculumTitle: curriculumTitle,
      isFollowUp: isFollowUp ?? this.isFollowUp,
      basedOnAnswer: basedOnAnswer ?? this.basedOnAnswer,
    );
  }
}

/// A candidate's recorded answer for a question.
class CandidateAnswer {
  const CandidateAnswer({
    required this.questionId,
    required this.text,
    this.assessment = AssessmentLevel.strong,
    this.score = 0,
    this.praise,
    this.whatToImprove,
    this.isFollowUpTriggered = false,
    this.strengths = const [],
    this.missingConcepts = const [],
    this.feedback,
  });

  final String questionId;
  final String text;
  final AssessmentLevel assessment;
  final double score;

  /// Short constructive note (kept for compatibility with existing UIs).
  final String? praise;
  final String? whatToImprove;
  final bool isFollowUpTriggered;

  /// Backend-reported strengths for this specific answer.
  final List<String> strengths;

  /// Backend-reported missing concepts for this specific answer.
  final List<String> missingConcepts;

  /// Full backend feedback text for this answer.
  final String? feedback;
}
