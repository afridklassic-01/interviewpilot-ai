/// Evaluation for a single answer, mirroring
/// `POST /api/interview/answer` response.
///
/// All numbers come from the backend (Hugging Face inference on FastAPI);
/// the frontend never fabricates scores.
class AnswerEvaluation {
  const AnswerEvaluation({
    required this.score,
    required this.technicalDepth,
    required this.communication,
    required this.problemSolving,
    required this.architecture,
    required this.isValid,
    required this.feedback,
    this.strengths = const [],
    this.missingConcepts = const [],
    this.nextQuestion,
    this.nextTopic,
    this.nextDifficulty,
    this.isFollowUp = false,
    this.followUpReason,
    this.answerQuality,
    this.curriculumDay,
    this.curriculumTitle,
  });

  final double score;

  /// Per-dimension scores 0..100 returned by the backend.
  final double technicalDepth;
  final double communication;
  final double problemSolving;
  final double architecture;

  /// False when the answer was off-topic / unusable.
  final bool isValid;

  /// Constructive evaluation text.
  final String feedback;

  final List<String> strengths;
  final List<String> missingConcepts;

  /// Next question text, or null when the interview is complete.
  final String? nextQuestion;
  final String? nextTopic;
  final String? nextDifficulty;

  /// True when [nextQuestion] was adaptively derived from the answer.
  final bool isFollowUp;
  final String? followUpReason;

  /// Backend-reported quality label (low/partial/good/strong/excellent).
  final String? answerQuality;

  /// Optional curriculum source forwarded for the next question.
  final String? curriculumDay;
  final String? curriculumTitle;

  double? dimensionFor(String name) {
    return switch (name) {
      'Technical Depth' => technicalDepth,
      'Communication' => communication,
      'Problem Solving' => problemSolving,
      'Architecture' => architecture,
      _ => null,
    };
  }

  AnswerEvaluation copyWith({
    String? nextQuestion,
    String? nextTopic,
    String? nextDifficulty,
    bool? isFollowUp,
    String? followUpReason,
    String? answerQuality,
    String? curriculumDay,
    String? curriculumTitle,
  }) {
    return AnswerEvaluation(
      score: score,
      technicalDepth: technicalDepth,
      communication: communication,
      problemSolving: problemSolving,
      architecture: architecture,
      isValid: isValid,
      feedback: feedback,
      strengths: strengths,
      missingConcepts: missingConcepts,
      nextQuestion: nextQuestion ?? this.nextQuestion,
      nextTopic: nextTopic ?? this.nextTopic,
      nextDifficulty: nextDifficulty ?? this.nextDifficulty,
      isFollowUp: isFollowUp ?? this.isFollowUp,
      followUpReason: followUpReason ?? this.followUpReason,
      answerQuality: answerQuality ?? this.answerQuality,
      curriculumDay: curriculumDay ?? this.curriculumDay,
      curriculumTitle: curriculumTitle ?? this.curriculumTitle,
    );
  }

  factory AnswerEvaluation.fromJson(Map<String, dynamic> json) {
    return AnswerEvaluation(
      score: (json['score'] as num?)?.toDouble() ?? 0,
      technicalDepth: (json['technical_depth'] as num?)?.toDouble() ?? 0,
      communication: (json['communication'] as num?)?.toDouble() ?? 0,
      problemSolving: (json['problem_solving'] as num?)?.toDouble() ?? 0,
      architecture: (json['architecture'] as num?)?.toDouble() ?? 0,
      isValid: json['is_valid'] as bool? ?? true,
      feedback: json['feedback'] as String? ?? '',
      strengths: _stringList(json['strengths']),
      missingConcepts: _stringList(json['missing_concepts']),
      nextQuestion: json['next_question'] as String?,
      nextTopic: json['next_topic'] as String?,
      nextDifficulty: json['next_difficulty'] as String?,
      isFollowUp: json['is_follow_up'] as bool? ?? false,
      followUpReason: json['follow_up_reason'] as String?,
      answerQuality: json['answer_quality'] as String?,
      curriculumDay: json['curriculum_day'] as String?,
      curriculumTitle: json['curriculum_title'] as String?,
    );
  }
}

/// One dimension of the final interview result.
class DimensionScore {
  const DimensionScore({required this.name, required this.score});

  final String name;
  final double score;

  factory DimensionScore.fromJson(Map<String, dynamic> json) {
    return DimensionScore(
      name: json['name'] as String? ?? 'Dimension',
      score: (json['score'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Constructive strength identified from the interview.
class InterviewStrength {
  const InterviewStrength({required this.title, required this.detail});

  final String title;
  final String detail;

  factory InterviewStrength.fromJson(Map<String, dynamic> json) {
    return InterviewStrength(
      title: json['title'] as String? ?? 'Strength',
      detail: json['detail'] as String? ?? '',
    );
  }
}

/// Constructive improvement area identified from the interview.
class ImprovementArea {
  const ImprovementArea({required this.title, required this.detail});

  final String title;
  final String detail;

  factory ImprovementArea.fromJson(Map<String, dynamic> json) {
    return ImprovementArea(
      title: json['title'] as String? ?? 'Improvement',
      detail: json['detail'] as String? ?? '',
    );
  }
}

/// One step of the personalized learning plan.
class NextStep {
  const NextStep({
    required this.title,
    required this.detail,
    this.type = NextStepType.review,
  });

  final String title;
  final String detail;
  final NextStepType type;

  factory NextStep.fromJson(Map<String, dynamic> json) {
    final type = switch (json['type'] as String?) {
      'practice' => NextStepType.practice,
      'retry' => NextStepType.retry,
      _ => NextStepType.review,
    };
    return NextStep(
      title: json['title'] as String? ?? 'Review',
      detail: json['detail'] as String? ?? '',
      type: type,
    );
  }
}

enum NextStepType { review, practice, retry }

/// Final professional recommendation.
class Recommendation {
  const Recommendation({
    required this.headline,
    required this.confidence,
    required this.explanation,
  });

  final String headline;

  /// e.g. "High"
  final String confidence;

  final String explanation;

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      headline: json['headline'] as String? ?? 'Review and retry',
      confidence: json['confidence'] as String? ?? 'Medium',
      explanation: json['explanation'] as String? ?? '',
    );
  }
}

/// The complete engineering report:
/// `GET /api/interview/{session_id}/feedback`.
class InterviewReport {
  const InterviewReport({
    required this.overallScore,
    required this.readinessPercent,
    required this.dimensions,
    required this.skillScores,
    required this.strengths,
    required this.improvements,
    required this.nextSteps,
    required this.recommendation,
    required this.trend,
    this.missingConcepts = const [],
    this.recommendedTopics = const [],
  });

  final double overallScore;

  /// 0..100 overall readiness shown on the report header.
  final double readinessPercent;

  final List<DimensionScore> dimensions;
  final Map<String, double> skillScores;
  final List<InterviewStrength> strengths;
  final List<ImprovementArea> improvements;
  final List<NextStep> nextSteps;
  final Recommendation recommendation;

  /// Improvement trend across interviews (oldest first).
  final List<double> trend;

  /// Concepts the candidate did not cover (aggregated from evaluations).
  final List<String> missingConcepts;

  /// Topics the report recommends reviewing next.
  final List<String> recommendedTopics;

  double get trendDelta {
    if (trend.length < 2) return 0;
    return trend.last - trend.first;
  }

  factory InterviewReport.fromJson(Map<String, dynamic> json) {
    final dims = (json['dimensions'] as List?)
            ?.map((e) => DimensionScore.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const <DimensionScore>[];
    return InterviewReport(
      overallScore: (json['overall_score'] as num?)?.toDouble() ?? 0,
      readinessPercent: (json['readiness_percent'] as num?)?.toDouble() ?? 0,
      dimensions: dims,
      skillScores: _numMap(json['skill_scores']),
      strengths: (json['strengths'] as List?)
              ?.map((e) => InterviewStrength.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <InterviewStrength>[],
      improvements: (json['improvements'] as List?)
              ?.map((e) => ImprovementArea.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ImprovementArea>[],
      nextSteps: (json['next_steps'] as List?)
              ?.map((e) => NextStep.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <NextStep>[],
      recommendation: json['recommendation'] is Map<String, dynamic>
          ? Recommendation.fromJson(
              json['recommendation'] as Map<String, dynamic>)
          : const Recommendation(
              headline: 'Review and retry',
              confidence: 'Medium',
              explanation: 'Complete the interview to unlock your report.',
            ),
      trend: _doubleList(json['trend']),
      missingConcepts: _stringList(json['missing_concepts']),
      recommendedTopics: _stringList(json['recommended_topics']),
    );
  }
}

// ---- JSON helpers ---------------------------------------------------------

List<String> _stringList(dynamic value) {
  if (value is! List) return const [];
  return value.whereType<String>().toList();
}

List<double> _doubleList(dynamic value) {
  if (value is! List) return const [];
  return value.whereType<num>().map((e) => e.toDouble()).toList();
}

Map<String, double> _numMap(dynamic value) {
  if (value is! Map) return const {};
  return value.map(
    (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
  );
}
