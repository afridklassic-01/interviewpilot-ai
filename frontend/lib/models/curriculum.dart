/// State of a curriculum day relative to the candidate's learning journey.
enum DayStatus {
  completed,
  strong,
  needsReview,
  skipped,
  upcoming;

  bool get isComplete => this == completed || this == strong;
}

/// A single day in the 31-day AI engineering cohort.
class CurriculumDay {
  const CurriculumDay({
    required this.day,
    required this.title,
    required this.topic,
    this.status = DayStatus.upcoming,
    this.missionsCompleted = 0,
    this.missionsTotal = 1,
    this.signal,
  });

  final int day;
  final String title;
  final String topic;
  final DayStatus status;
  final int missionsCompleted;
  final int missionsTotal;

  /// Optional human-readable learning signal (e.g. "Completed mission successfully").
  final String? signal;

  bool get isStrong => status == DayStatus.strong;
  bool get needsReview => status == DayStatus.needsReview;
  bool get isSkipped => status == DayStatus.skipped;
}

/// A named milestone on the visual journey (Day 1 -> Day 31).
class JourneyMilestone {
  const JourneyMilestone({
    required this.day,
    required this.label,
    required this.status,
    this.notes,
  });

  final int day;
  final String label;
  final DayStatus status;
  final String? notes;
}
