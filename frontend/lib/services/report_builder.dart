import '../models/feedback.dart';
import '../models/question.dart';

/// Aggregates the recorded backend evaluations into a final engineering
/// report. Used in mock mode and as a graceful fallback when the backend's
/// `/feedback` endpoint is not yet available.
///
/// All numbers are real: they come from the evaluations returned by the
/// backend (or the mock backend) for each answer — nothing is fabricated.
class ReportBuilder {
  ReportBuilder._();

  static double _mean(Iterable<double> values) {
    final list = values.toList();
    if (list.isEmpty) return 0;
    return list.reduce((a, b) => a + b) / list.length;
  }

  static InterviewReport build({
    required List<AnswerEvaluation> evaluations,
    required List<InterviewQuestion> questions,
    required List<CandidateAnswer> answers,
    List<double> previousTrend = const [],
  }) {
    // If nothing was evaluated, return a neutral placeholder report.
    if (evaluations.isEmpty) {
      return _emptyReport();
    }

    final overall =
        _mean(evaluations.map((e) => e.score)).roundToDouble();

    final dimensions = [
      DimensionScore(
        name: 'Technical Depth',
        score: _mean(evaluations.map((e) => e.technicalDepth)),
      ),
      DimensionScore(
        name: 'Communication',
        score: _mean(evaluations.map((e) => e.communication)),
      ),
      DimensionScore(
        name: 'Problem Solving',
        score: _mean(evaluations.map((e) => e.problemSolving)),
      ),
      DimensionScore(
        name: 'Architecture',
        score: _mean(evaluations.map((e) => e.architecture)),
      ),
    ];

    // Skill scores grouped by topic (topics with at least one evaluation).
    final perTopic = <String, List<double>>{};
    for (var i = 0; i < questions.length && i < evaluations.length; i++) {
      perTopic
          .putIfAbsent(questions[i].topic, () => [])
          .add(evaluations[i].score);
    }
    final skillScores = <String, double>{
      for (final entry in perTopic.entries)
        entry.key: _mean(entry.value),
    };

    // Strengths: de-duplicated, most frequently cited first.
    final strengthCounts = <String, int>{};
    final strengthDetail = <String, String>{};
    for (final e in evaluations) {
      for (final s in e.strengths) {
        strengthCounts[s] = (strengthCounts[s] ?? 0) + 1;
        strengthDetail[s] = e.feedback;
      }
    }
    final orderedStrengths = strengthCounts.keys.toList()
      ..sort((a, b) => strengthCounts[b]!.compareTo(strengthCounts[a]!));
    final strengths = [
      for (final s in orderedStrengths.take(4))
        InterviewStrength(
          title: s,
          detail: strengthDetail[s] ?? 'Demonstrated consistently in the interview.',
        ),
    ];

    // Missing concepts: de-duplicated across evaluations.
    final missingSet = <String>{};
    for (final e in evaluations) {
      missingSet.addAll(e.missingConcepts);
    }
    final missingConcepts = missingSet.take(6).toList();

    // Recommended topics: lowest-scoring covered topics.
    final rankedTopics = skillScores.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final recommendedTopics =
        rankedTopics.take(3).map((e) => e.key).toList();

    final improvements = [
      for (final concept in missingConcepts.take(3))
        ImprovementArea(
          title: concept,
          detail: 'Addressed in ${recommendedTopics.isNotEmpty ? recommendedTopics.first : 'the interview'} — '
              'review this concept before the next round.',
        ),
    ];

    final nextSteps = [
      for (final topic in recommendedTopics.take(2))
        NextStep(
          title: 'Review $topic',
          detail: 'Revisit the fundamentals and one hands-on build.',
          type: NextStepType.review,
        ),
      if (recommendedTopics.isNotEmpty)
        NextStep(
          title: 'Practice',
          detail: 'Design a production system around ${recommendedTopics.first}.',
          type: NextStepType.practice,
        ),
    ];

    final (headline, confidence) = switch (overall) {
      >= 82 => ('Ready for another technical round', 'High'),
      >= 65 => ('Solid foundation — sharpen the gaps', 'Medium'),
      _ => ('Keep building — the gaps are addressable', 'Low'),
    };

    final recommendation = Recommendation(
      headline: headline,
      confidence: confidence,
      explanation:
          'Across ${evaluations.length} evaluated answer(s) the profile shows '
          '${_labelFor(overall)}. Focus areas are concrete and addressable '
          'before the next round.',
    );

    return InterviewReport(
      overallScore: overall,
      readinessPercent: overall,
      dimensions: dimensions,
      skillScores: skillScores,
      strengths: strengths,
      improvements: improvements,
      nextSteps: nextSteps,
      recommendation: recommendation,
      trend: [...previousTrend, overall],
      missingConcepts: missingConcepts,
      recommendedTopics: recommendedTopics,
    );
  }

  static String _labelFor(double score) {
    if (score >= 82) return 'consistent depth in your strongest areas';
    if (score >= 65) return 'good coverage with clear room to grow';
    return 'early-stage fluency that will tighten with practice';
  }

  static InterviewReport _emptyReport() {
    return InterviewReport(
      overallScore: 0,
      readinessPercent: 0,
      dimensions: const [
        DimensionScore(name: 'Technical Depth', score: 0),
        DimensionScore(name: 'Communication', score: 0),
        DimensionScore(name: 'Problem Solving', score: 0),
        DimensionScore(name: 'Architecture', score: 0),
      ],
      skillScores: const {},
      strengths: const [],
      improvements: const [],
      nextSteps: const [],
      recommendation: const Recommendation(
        headline: 'Complete the interview to see your report',
        confidence: '—',
        explanation: 'Answer at least one question to generate a profile.',
      ),
      trend: const [],
    );
  }
}
