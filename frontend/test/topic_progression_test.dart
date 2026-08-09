import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:interviewpilot_ai/services/interview_api_service.dart';
import 'package:interviewpilot_ai/state/interview_session.dart';
import 'package:interviewpilot_ai/state/topic_progress.dart';

/// Verifies the topic-progression state machine with the offline mock
/// backend: completing RAG marks it COMPLETED, and the next normal
/// interview starts the NEXT INCOMPLETE topic (never RAG again).
void main() {
  const genericAnswer =
      'I would weigh latency, cost and operational burden, then measure '
      'retrieval quality and monitor the pipeline in production with clear '
      'rollback and evaluation loops.';

  test('complete RAG -> next interview starts Vector Databases, RAG stays done',
      () async {
    SharedPreferences.setMockInitialValues({});
    final session = InterviewSession(api: MockInterviewApiService());

    // Normal start: first incomplete topic in curriculum order is RAG.
    await session.startInterview();
    expect(session.currentTopic, 'RAG');
    expect(session.topicStatus('RAG'), TopicStatus.inProgress);
    expect(session.questionNumber, 1);
    expect(session.totalQuestions, 8);

    // Answer all 8 questions of the topic.
    for (var i = 0; i < 8; i++) {
      await session.submitAnswer(genericAnswer);
      session.continueToNext(); // next question, or completes at the end
    }

    // Give the async completion + report load a moment.
    await Future<void>.delayed(const Duration(seconds: 2));

    expect(session.isComplete, isTrue);
    expect(session.topicStatus('RAG'), TopicStatus.completed);
    expect(session.completedTopics, contains('RAG'));

    // The next incomplete topic is Vector Databases — NOT RAG.
    expect(session.nextIncompleteTopic, 'Vector Databases');

    // Start another interview: it must begin with the next incomplete topic.
    await session.startInterview();
    expect(session.currentTopic, 'Vector Databases');
    expect(session.questionNumber, 1);
    expect(session.topicStatus('RAG'), TopicStatus.completed,
        reason: 'Completed topics must not restart automatically');

    // Explicit retry still targets the completed topic on purpose.
    session.retryTopic('RAG');
    await session.startInterview();
    expect(session.currentTopic, 'RAG');
    expect(session.topicStatus('RAG'), TopicStatus.inProgress);
  });
}
