import 'curriculum.dart';

/// Aggregated learning statistics for the candidate's cohort journey.
class LearningStats {
  const LearningStats({
    required this.daysTotal,
    required this.daysCompleted,
    required this.daysSkipped,
    required this.daysNeedsReview,
  });

  final int daysTotal;
  final int daysCompleted;
  final int daysSkipped;
  final int daysNeedsReview;

  int get daysRemaining => daysTotal - daysCompleted - daysSkipped;

  double get completionRatio =>
      daysTotal == 0 ? 0 : daysCompleted / daysTotal;
}

/// A single measured skill with an estimated proficiency score.
class SkillProficiency {
  const SkillProficiency({
    required this.name,
    required this.score,
    this.shortName,
    this.summary,
  });

  final String name;

  /// 0..100 estimated proficiency from the learning journey.
  final double score;

  /// Short label used in compact UIs (e.g. radar chart).
  final String? shortName;

  /// One-line explanation of why this score was derived.
  final String? summary;

  String get displayShort => shortName ?? name;

  factory SkillProficiency.fromJson(Map<String, dynamic> json) {
    return SkillProficiency(
      name: json['name'] as String? ?? 'Skill',
      score: (json['score'] as num?)?.toDouble() ?? 0,
      shortName: json['short_name'] as String?,
      summary: json['summary'] as String?,
    );
  }
}

/// Snapshot of the previous interview performance.
class PreviousInterview {
  const PreviousInterview({
    required this.score,
    required this.strongestTopic,
    required this.weakestTopic,
    required this.trend,
  });

  final double score;
  final String strongestTopic;
  final String weakestTopic;

  /// Historical interview scores, oldest first (used for trend sparkline).
  final List<double> trend;

  double get trendDelta {
    if (trend.length < 2) return 0;
    return trend.last - trend.first;
  }
}

/// The full candidate profile consumed by the dashboard and the interviewer.
class Candidate {
  const Candidate({
    required this.id,
    required this.name,
    required this.cohortName,
    required this.stats,
    required this.skills,
    required this.previousInterview,
    required this.journey,
    this.readinessOverride,
  });

  final String id;
  final String name;
  final String cohortName;
  final LearningStats stats;
  final List<SkillProficiency> skills;
  final PreviousInterview previousInterview;

  /// Ordered journey milestones (Day 1 -> Day 31).
  final List<JourneyMilestone> journey;

  /// Explicit readiness used while the backend formula is being tuned.
  final double? readinessOverride;

  /// Estimated overall readiness derived from journey + prior performance.
  double get readinessScore {
    if (readinessOverride != null) return readinessOverride!;
    final skillAvg = skills.isEmpty
        ? 0
        : skills.map((s) => s.score).reduce((a, b) => a + b) / skills.length;
    final momentum = previousInterview.trend.isEmpty
        ? 0
        : (previousInterview.trend.last - previousInterview.trend.first);
    return ((skillAvg * 0.5) + (stats.completionRatio * 100 * 0.25) +
            (previousInterview.score * 0.15) + momentum)
        .clamp(0, 100);
  }

  SkillProficiency? skillBy(String name) {
    for (final s in skills) {
      if (s.name.toLowerCase() == name.toLowerCase()) return s;
    }
    return null;
  }

  /// Parses a backend candidate payload. Missing fields degrade gracefully
  /// so the UI never crashes against a partial backend response.
  factory Candidate.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] is Map<String, dynamic>
        ? json['stats'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final prev = json['previous_interview'] is Map<String, dynamic>
        ? json['previous_interview'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final skills = (json['skills'] as List?)
            ?.map((e) => SkillProficiency.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const <SkillProficiency>[];
    final trend = (prev['trend'] as List?)
            ?.whereType<num>()
            .map((e) => e.toDouble())
            .toList() ??
        const <double>[];
    return Candidate(
      id: json['id'] as String? ?? 'candidate',
      name: json['name'] as String? ?? 'Candidate',
      cohortName: json['cohort_name'] as String? ?? 'AI Engineering Cohort',
      stats: LearningStats(
        daysTotal: (stats['days_total'] as num?)?.toInt() ?? 31,
        daysCompleted: (stats['days_completed'] as num?)?.toInt() ?? 0,
        daysSkipped: (stats['days_skipped'] as num?)?.toInt() ?? 0,
        daysNeedsReview: (stats['days_needs_review'] as num?)?.toInt() ?? 0,
      ),
      skills: skills,
      previousInterview: PreviousInterview(
        score: (prev['score'] as num?)?.toDouble() ?? 0,
        strongestTopic: prev['strongest_topic'] as String? ?? '—',
        weakestTopic: prev['weakest_topic'] as String? ?? '—',
        trend: trend,
      ),
      journey: const [],
    );
  }
}
