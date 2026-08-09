import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:interviewpilot_ai/models/question.dart';
import 'package:interviewpilot_ai/widgets/interview/learning_context_panel.dart';

import 'helpers/test_fonts.dart';

void main() {
  testWidgets('learning context panel fits at 264px (follow-up + badges)',
      (tester) async {
    await loadRealFonts();
    tester.view.physicalSize = const Size(1500, 950);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    const q = InterviewQuestion(
      id: 'q2-followup',
      topic: 'Vector Databases',
      prompt: 'You chose Pinecone for vector search. What trade-off would make '
          'you choose a self-hosted vector database instead?',
      difficulty: Difficulty.staff,
      isFollowUp: true,
      basedOnAnswer: 'I would design the retrieval layer around Pinecone…',
      curriculumDay: '15',
      curriculumTitle: 'Vector Databases',
    );

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: 264,
            child: LearningContextPanel(
              question: q,
              signal: 'One mission left incomplete',
              previousPerformance: 'Needs review',
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Day 15'), findsOneWidget);
  });
}
