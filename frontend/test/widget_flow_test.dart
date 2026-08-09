import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:interviewpilot_ai/app.dart';
import 'package:interviewpilot_ai/models/candidate.dart';
import 'package:interviewpilot_ai/models/feedback.dart';
import 'package:interviewpilot_ai/models/interview.dart';
import 'package:interviewpilot_ai/services/interview_api_service.dart';
import 'package:interviewpilot_ai/screens/interview/interview_screen.dart';
import 'package:interviewpilot_ai/state/interview_session.dart';
import 'package:interviewpilot_ai/theme/app_theme.dart';

import 'helpers/test_fonts.dart';

/// End-to-end smoke test of the core flow:
/// landing → interview → analyze → evaluation → adaptive follow-up ("Pinecone")
/// → 8 questions → complete → report → review.
void main() {
  Future<void> pumpFor(WidgetTester tester, Duration d) async {
    await tester.pump();
    await tester.pump(d);
    await tester.pump();
  }

  testWidgets('full backend-driven flow with adaptive follow-up', (tester) async {
    await loadRealFonts();
    SharedPreferences.setMockInitialValues({});

    // Desktop viewport so the three-pane interview layout is active.
    tester.view.physicalSize = const Size(1500, 950);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // Use the offline mock backend (the test binding blocks real HTTP).
    final session = InterviewSession(api: MockInterviewApiService());
    await tester.pumpWidget(InterviewPilotApp(session: session));
    await tester.pump(const Duration(milliseconds: 200));

    // --- Landing ---
    expect(find.textContaining('INTERVIEWPILOT'), findsWidgets);
    expect(find.text('Start AI Interview'), findsWidgets);

    // Start the interview from the landing CTA.
    await tester.tap(find.text('Start AI Interview').first);
    await pumpFor(tester, const Duration(seconds: 2));

    // --- Interview, question 1 ---
    expect(find.text('WHY THIS TOPIC?'), findsOneWidget);
    expect(find.text('LIVE INTERVIEW SIGNALS'), findsOneWidget);
    expect(find.text('TOPIC COVERAGE'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Before the first answer the signals show placeholders — no fake values.
    expect(find.text('Ready for your answer'), findsOneWidget);
    expect(find.text('—'), findsWidgets);

    // Generic answer for Q1.
    await tester.enterText(
      find.byType(TextField),
      'RAG grounds generation in retrieved evidence. The failure points are '
      'low-quality retrieval, stale indexes and weak reranking, so I would '
      'instrument recall and monitor answer grounding in production.',
    );
    await tester.tap(find.text('Submit Answer'));
    await pumpFor(tester, const Duration(seconds: 2));

    // Analyzing state appeared; evaluation card now shows real values.
    expect(find.text('ANSWER EVALUATION'), findsOneWidget);
    expect(find.text('STRENGTHS'), findsOneWidget);
    expect(find.text('NEEDS IMPROVEMENT'), findsOneWidget);
    expect(find.text('FEEDBACK'), findsOneWidget);

    // --- Q2: answer mentioning Pinecone -> adaptive follow-up ---
    await tester.tap(find.textContaining('Continue to Question 2'));
    await pumpFor(tester, const Duration(milliseconds: 400));

    await tester.enterText(
      find.byType(TextField),
      'I would design the retrieval layer around Pinecone for vector search, '
      'with metadata filtering, hybrid search and a reranker, and evaluate '
      'recall and precision against a labeled eval set before tuning '
      'thresholds and measuring latency at scale.',
    );
    await tester.tap(find.text('Submit Answer'));
    await pumpFor(tester, const Duration(seconds: 2));

    // Evaluation previews the follow-up derived from the previous answer.
    expect(find.textContaining('Based on your previous answer'), findsWidgets);
    expect(find.textContaining('Pinecone'), findsWidgets);
    expect(find.textContaining('self-hosted'), findsWidgets);

    // Advance into the generated follow-up question.
    await tester.tap(find.textContaining('Continue to Question 3'));
    await pumpFor(tester, const Duration(milliseconds: 400));
    expect(find.textContaining('Based on your previous answer'), findsWidgets);

    // --- Remaining questions to completion ---
    const generic =
        'I would weigh latency, cost and operational burden, then measure '
        'retrieval quality and monitor the pipeline in production with clear '
        'rollback and evaluation loops.';

    for (var i = 0; i < 6; i++) {
      await tester.enterText(find.byType(TextField), generic);
      await tester.tap(find.text('Submit Answer'));
      await pumpFor(tester, const Duration(seconds: 2));

      expect(find.text('ANSWER EVALUATION'), findsOneWidget);
      final continueButton = find.textContaining('Continue to Question');
      if (continueButton.evaluate().isNotEmpty) {
        await tester.tap(continueButton);
        await pumpFor(tester, const Duration(milliseconds: 400));
      }
    }

    // --- Complete ---
    await tester.tap(find.text('Complete Interview'));
    await pumpFor(tester, const Duration(seconds: 3));

    if (find.text('Interview Complete').evaluate().isEmpty) {
      // Diagnostic: print what is on screen when the completion screen is missing.
      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
          .where((t) => t.isNotEmpty)
          .toList();
      // ignore: avoid_print
      print('ON-SCREEN TEXTS: $texts');
    }
    expect(find.text('Interview Complete'), findsOneWidget);
    expect(find.textContaining('Technical Foundation'), findsOneWidget);

    // --- Report ---
    await tester.ensureVisible(find.text('View Engineering Report'));
    await tester.tap(find.text('View Engineering Report'));
    await pumpFor(tester, const Duration(seconds: 2));
    expect(find.textContaining('ENGINEERING INTERVIEW REPORT'), findsOneWidget);
    expect(find.textContaining('SKILL PROFILE'), findsOneWidget);
    expect(find.textContaining('Your next 3 moves'), findsWidgets);
    expect(find.text('AI RECOMMENDATION'), findsOneWidget);
    expect(find.text('MISSING CONCEPTS'), findsOneWidget);
    expect(find.text('RECOMMENDED TOPICS'), findsOneWidget);

    // --- Question review ---
    await tester.ensureVisible(find.textContaining('Review All Questions'));
    await tester.tap(find.textContaining('Review All Questions'));
    await pumpFor(tester, const Duration(seconds: 1));
    expect(find.text('QUESTION REVIEW'), findsOneWidget);

    // Expand the first question and verify the answer detail.
    await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded).first);
    await pumpFor(tester, const Duration(milliseconds: 400));
    expect(find.text('CANDIDATE ANSWER'), findsWidgets);
    expect(find.text('TOPIC'), findsWidgets);

    // Final settle: allow remaining transient timers to flush.
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('answer submission failure offers Retry Answer and keeps the text',
      (tester) async {
    await loadRealFonts();
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1500, 950);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final session = InterviewSession(api: _SubmitFailingApi());
    await tester.pumpWidget(SessionScope(
      session: session,
      child: MaterialApp(
        theme: AppTheme.dark,
        home: const InterviewScreen(),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    // Interview started; Q1 is displayed.
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(
      find.byType(TextField),
      'My answer must survive a failed evaluation and be retried.',
    );
    await tester.tap(find.text('Submit Answer'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.textContaining("Couldn't evaluate your answer."), findsWidgets);
    expect(find.text('Retry Answer'), findsOneWidget);

    // Retry re-submits the preserved answer (and fails again, recoverably).
    await tester.tap(find.text('Retry Answer'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(find.textContaining("Couldn't evaluate your answer."), findsWidgets);
    expect(find.text('Retry Answer'), findsOneWidget);
  });

  testWidgets('interview shows unavailable error and retry when the API fails',
      (tester) async {
    await loadRealFonts();
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1500, 950);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final session = InterviewSession(api: _FailingApi());
    await tester.pumpWidget(SessionScope(
      session: session,
      child: MaterialApp(
        theme: AppTheme.dark,
        home: const InterviewScreen(),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Interview service unavailable'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Back to Dashboard'), findsOneWidget);

    // Retry keeps failing but stays in a recoverable error state.
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Interview service unavailable'), findsOneWidget);
  });
}

/// API stub that fails only answer submissions — exercises the preserved-
/// answer retry path.
class _SubmitFailingApi implements InterviewApiService {
  @override
  Future<Candidate> fetchCandidate(String candidateId) async {
    throw Exception('candidate endpoint not implemented');
  }

  @override
  Future<InterviewStartData> startInterview({
    required String candidateId,
    required String focus,
    required String topic,
  }) async {
    return InterviewStartData(
      sessionId: 'iv_test',
      questionNumber: 1,
      totalQuestions: 8,
      topic: topic,
      difficulty: 'Senior-level',
      question: 'Explain how retrieval-augmented generation reduces hallucinations.',
      expectedFocus: const ['RAG pipeline', 'Grounding'],
    );
  }

  @override
  Future<AnswerEvaluation> submitAnswer({
    required String sessionId,
    required String question,
    required String answer,
    required String topic,
    required int questionNumber,
    String difficulty = 'Senior-level',
    List<String> expectedFocus = const [],
  }) async {
    throw Exception('evaluation service down');
  }

  @override
  Future<InterviewSessionData> getSession(String sessionId) async {
    throw Exception('not implemented');
  }

  @override
  Future<void> completeInterview(String sessionId) async {}

  @override
  Future<InterviewReport?> getFeedback(String sessionId) async => null;
}

/// API stub that always fails — exercises the error + retry UI path.
class _FailingApi implements InterviewApiService {
  @override
  Future<Candidate> fetchCandidate(String candidateId) async {
    throw Exception('network down');
  }

  @override
  Future<InterviewStartData> startInterview({
    required String candidateId,
    required String focus,
    required String topic,
  }) async {
    throw Exception('network down');
  }

  @override
  Future<AnswerEvaluation> submitAnswer({
    required String sessionId,
    required String question,
    required String answer,
    required String topic,
    required int questionNumber,
    String difficulty = 'Senior-level',
    List<String> expectedFocus = const [],
  }) async {
    throw Exception('network down');
  }

  @override
  Future<InterviewSessionData> getSession(String sessionId) async {
    throw Exception('network down');
  }

  @override
  Future<void> completeInterview(String sessionId) async {
    throw Exception('network down');
  }

  @override
  Future<InterviewReport?> getFeedback(String sessionId) async {
    throw Exception('network down');
  }
}
