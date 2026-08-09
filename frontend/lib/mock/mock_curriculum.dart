import '../models/curriculum.dart';

/// Mock 31-day cohort curriculum (relevant days exposed to the UI).
class MockCurriculum {
  MockCurriculum._();

  static const List<CurriculumDay> days = [
    CurriculumDay(
      day: 1,
      title: 'LLM Foundations',
      topic: 'Foundations',
      status: DayStatus.completed,
      missionsCompleted: 1,
      missionsTotal: 1,
      signal: 'Completed mission successfully',
    ),
    CurriculumDay(
      day: 7,
      title: 'Prompt Engineering',
      topic: 'Prompt Engineering',
      status: DayStatus.strong,
      missionsCompleted: 3,
      missionsTotal: 3,
      signal: 'Strong prompt design patterns',
    ),
    CurriculumDay(
      day: 12,
      title: 'Retrieval-Augmented Generation',
      topic: 'RAG',
      status: DayStatus.strong,
      missionsCompleted: 2,
      missionsTotal: 2,
      signal: 'Completed mission successfully',
    ),
    CurriculumDay(
      day: 15,
      title: 'Vector Databases',
      topic: 'Vector Databases',
      status: DayStatus.needsReview,
      missionsCompleted: 1,
      missionsTotal: 2,
      signal: 'One mission left incomplete',
    ),
    CurriculumDay(
      day: 18,
      title: 'MCP Architecture',
      topic: 'MCP',
      status: DayStatus.needsReview,
      missionsCompleted: 1,
      missionsTotal: 2,
      signal: 'Theory strong, mission incomplete',
    ),
    CurriculumDay(
      day: 24,
      title: 'Agentic AI',
      topic: 'Agentic AI',
      status: DayStatus.needsReview,
      missionsCompleted: 2,
      missionsTotal: 3,
      signal: 'Agent loop designed, safety mission pending',
    ),
    CurriculumDay(
      day: 31,
      title: 'AI Deployment & Production Systems',
      topic: 'AI Deployment',
      status: DayStatus.skipped,
      missionsCompleted: 0,
      missionsTotal: 2,
      signal: 'Day skipped',
    ),
  ];

  /// Milestones rendered on the dashboard journey strip.
  static const List<JourneyMilestone> milestones = [
    JourneyMilestone(day: 1, label: 'Foundations', status: DayStatus.completed),
    JourneyMilestone(day: 7, label: 'Prompt Engineering', status: DayStatus.strong),
    JourneyMilestone(day: 12, label: 'RAG', status: DayStatus.strong),
    JourneyMilestone(day: 18, label: 'MCP', status: DayStatus.needsReview),
    JourneyMilestone(day: 24, label: 'Agentic AI', status: DayStatus.needsReview),
    JourneyMilestone(day: 31, label: 'AI Deployment', status: DayStatus.skipped),
  ];

  static CurriculumDay? byDay(int day) {
    for (final d in days) {
      if (d.day == day) return d;
    }
    return null;
  }
}
