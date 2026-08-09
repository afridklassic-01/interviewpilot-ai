import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:interviewpilot_ai/screens/interview/interview_complete_screen.dart';
import 'package:interviewpilot_ai/screens/results/question_review_screen.dart';
import 'package:interviewpilot_ai/screens/results/results_screen.dart';
import 'package:interviewpilot_ai/services/interview_api_service.dart';
import 'package:interviewpilot_ai/state/interview_session.dart';
import 'package:interviewpilot_ai/theme/app_theme.dart';

import 'helpers/test_fonts.dart';

/// Renders the final-report surfaces at desktop, laptop, tablet and phone
/// widths and asserts that NO layout overflow / clipping exceptions occur
/// (no "RIGHT OVERFLOWED BY ..." / "BOTTOM OVERFLOWED BY ...").
void main() {
  const genericAnswer =
      'I would weigh latency, cost and operational burden, then measure '
      'retrieval quality and monitor the pipeline in production with clear '
      'rollback and evaluation loops.';

  testWidgets('report, complete and review screens fit at every viewport width',
      (tester) async {
    await loadRealFonts();

    // Run the mock interview to completion using real timers, then render
    // the same completed session at each viewport size.
    final session = (await tester.runAsync(() async {
      SharedPreferences.setMockInitialValues({});
      final s = InterviewSession(api: MockInterviewApiService());
      await s.startInterview();
      for (var i = 0; i < 8; i++) {
        await s.submitAnswer(genericAnswer);
        s.continueToNext();
      }
      await Future<void>.delayed(const Duration(seconds: 2));
      return s;
    }))!;

    expect(session.isComplete, isTrue);
    expect(session.report, isNotNull, reason: 'report must exist to render');

    final widths = <double>[1440, 1024, 768, 480, 360];

    for (final width in widths) {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(SessionScope(
        session: session,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const ResultsScreen(),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 600));
      // NOTE: takeException intentionally disabled for diagnosis so the
      // framework dumps the full overflow report at the end of the test.

      await tester.pumpWidget(SessionScope(
        session: session,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const InterviewCompleteScreen(),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 600));
      expect(
        tester.takeException(),
        isNull,
        reason: 'InterviewCompleteScreen overflow at width $width',
      );

      await tester.pumpWidget(SessionScope(
        session: session,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const QuestionReviewScreen(),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 600));
      expect(
        tester.takeException(),
        isNull,
        reason: 'QuestionReviewScreen overflow at width $width',
      );
    }
  });
}
