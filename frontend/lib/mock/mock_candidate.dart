import '../models/candidate.dart';
import 'mock_curriculum.dart';

/// Mock candidate profile for "Alex".
///
/// Derived from the completed 31-day cohort; will be replaced by the
/// backend's profile endpoint in the full-stack version.
class MockCandidate {
  MockCandidate._();

  static const String id = 'cand_alex_01';

  static const Candidate data = Candidate(
    id: id,
    name: 'Alex',
    cohortName: 'AI Engineering Cohort — 31 Days',
    readinessOverride: 82,
    stats: LearningStats(
      daysTotal: 31,
      daysCompleted: 24,
      daysSkipped: 3,
      daysNeedsReview: 4,
    ),
    skills: [
      SkillProficiency(
        name: 'RAG',
        score: 92,
        summary: 'Deep retrieval + generation fluency from Day 12 missions.',
      ),
      SkillProficiency(
        name: 'Prompt Engineering',
        score: 86,
        summary: 'Strong system-prompt design across 5+ missions.',
      ),
      SkillProficiency(
        name: 'Agentic AI',
        score: 81,
        summary: 'Confident agent loops; tool safety still maturing.',
      ),
      SkillProficiency(
        name: 'Vector Databases',
        score: 74,
        summary: 'Solid theory; fewer hands-on indexing missions.',
      ),
      SkillProficiency(
        name: 'MCP',
        score: 63,
        summary: 'Theory strong, limited practical mission completion.',
      ),
      SkillProficiency(
        name: 'AI Deployment',
        score: 58,
        summary: 'Fewest completed missions in deployment and ops.',
      ),
    ],
    previousInterview: PreviousInterview(
      score: 76,
      strongestTopic: 'RAG',
      weakestTopic: 'AI Deployment',
      trend: [68, 71, 74, 76, 79],
    ),
    journey: MockCurriculum.milestones,
  );
}
