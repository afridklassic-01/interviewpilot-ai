import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../mock/mock_candidate.dart';
import '../mock/mock_interview.dart';
import '../models/candidate.dart';
import '../models/feedback.dart';
import '../models/interview.dart';
import '../models/question.dart';

/// Contract for the InterviewPilot backend.
///
/// Every method maps 1:1 to a REST endpoint of the FastAPI backend. The
/// Flutter app never holds an API key — the Hugging Face key lives in the
/// backend's `.env` and the app only exchanges candidate answers.
///
/// REST mapping:
///  - [fetchCandidate]      -> GET  /api/candidate/{candidate_id}
///  - [startInterview]      -> POST /api/interview/start
///  - [submitAnswer]        -> POST /api/interview/answer
///  - [getSession]          -> GET  /api/interview/{session_id}
///  - [completeInterview]   -> POST /api/interview/complete
///  - [getFeedback]         -> GET  /api/interview/{session_id}/feedback
abstract class InterviewApiService {
  Future<Candidate> fetchCandidate(String candidateId);

  Future<InterviewStartData> startInterview({
    required String candidateId,
    required String focus,
    required String topic,
  });

  Future<AnswerEvaluation> submitAnswer({
    required String sessionId,
    required String question,
    required String answer,
    required String topic,
    required int questionNumber,
    String difficulty = 'Senior-level',
    List<String> expectedFocus = const [],
  });

  Future<InterviewSessionData> getSession(String sessionId);

  Future<void> completeInterview(String sessionId);

  /// Returns null when the backend has no authoritative report yet
  /// (the session then aggregates locally from recorded evaluations).
  Future<InterviewReport?> getFeedback(String sessionId);
}

/// Picks the service implementation from [ApiConfig].
InterviewApiService createInterviewApiService() {
  if (ApiConfig.useMockBackend) return MockInterviewApiService();
  return RealInterviewApiService();
}

// ===========================================================================
// MOCK MODE — offline, no network required.
// ===========================================================================

/// Offline implementation that simulates the adaptive backend.
///
/// Stateful per session so the question progression behaves exactly like the
/// real backend will: it decides the next topic/question and can insert an
/// adaptive follow-up derived from the previous answer.
class MockInterviewApiService implements InterviewApiService {
  final Map<String, _MockSessionState> _states = {};

  static const _startLatency = Duration(milliseconds: 1100);
  static const _answerLatency = Duration(milliseconds: 1400);

  static Future<T> _delay<T>(T value, {Duration? duration}) {
    return Future.delayed(duration ?? _startLatency, () => value);
  }

  @override
  Future<Candidate> fetchCandidate(String candidateId) =>
      _delay(MockCandidate.data, duration: const Duration(milliseconds: 600));

  @override
  Future<InterviewStartData> startInterview({
    required String candidateId,
    required String focus,
    required String topic,
  }) {
    final sessionId = 'iv_${DateTime.now().millisecondsSinceEpoch}';
    final questions = MockInterviewData.questionsForTopic(topic);
    _states[sessionId] = _MockSessionState(questions: questions);
    final first = questions.first;
    return _delay(
      InterviewStartData(
        sessionId: sessionId,
        questionNumber: 1,
        totalQuestions: questions.length,
        topic: first.topic,
        difficulty: first.difficulty.label,
        question: first.prompt,
        expectedFocus: first.expectedFocus,
        curriculumDay: first.curriculumDay,
        curriculumTitle: first.curriculumTitle,
      ),
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
  }) {
    final state = _states.putIfAbsent(
      sessionId,
      () => _MockSessionState(
        questions: MockInterviewData.questionsForTopic(topic),
      ),
    );

    // Resolve which question this answer belongs to: the pending adaptive
    // follow-up (matched by prompt text) or the regular sequence.
    final answeringFollowUp =
        state.pendingFollowUpPrompt != null &&
            question.trim() == state.pendingFollowUpPrompt!.trim();
    final current = state.questionForPrompt(question) ??
        state.questions[
            (state.nextIndex - 1).clamp(0, state.questions.length - 1)];

    final result = MockEvaluationEngine.evaluate(
      question: current,
      answer: answer,
    );

    // Decide the next question exactly like the backend would.
    String? nextQuestion;
    String? nextTopic;
    String? nextDifficulty;
    String? nextCurriculumDay;
    String? nextCurriculumTitle;
    var isFollowUp = false;

    if (result.followUpPrompt != null && !answeringFollowUp) {
      // The follow-up occupies this slot; the sequence does not advance.
      state.pendingFollowUpPrompt = result.followUpPrompt;
      state.followUpSourceIndex = state.questions.indexOf(current);
      nextQuestion = result.followUpPrompt;
      nextTopic = current.topic;
      nextDifficulty = Difficulty.staff.label;
      nextCurriculumDay = current.curriculumDay;
      nextCurriculumTitle = current.curriculumTitle;
      isFollowUp = true;
    } else {
      state.pendingFollowUpPrompt = null;
      if (state.nextIndex < state.questions.length) {
        final next = state.questions[state.nextIndex];
        nextQuestion = next.prompt;
        nextTopic = next.topic;
        nextDifficulty = next.difficulty.label;
        nextCurriculumDay = next.curriculumDay;
        nextCurriculumTitle = next.curriculumTitle;
        state.nextIndex += 1;
      }
      // else: sequence exhausted -> interview complete (nextQuestion null).
    }

    return _delay(
      AnswerEvaluation(
        score: result.score,
        technicalDepth: result.technicalDepth,
        communication: result.communication,
        problemSolving: result.problemSolving,
        architecture: result.architecture,
        isValid: result.isValid,
        feedback: result.feedback,
        strengths: result.strengths,
        missingConcepts: result.missingConcepts,
        nextQuestion: nextQuestion,
        nextTopic: nextTopic,
        nextDifficulty: nextDifficulty,
        isFollowUp: isFollowUp,
        followUpReason: result.followUpReason,
        curriculumDay: nextCurriculumDay,
        curriculumTitle: nextCurriculumTitle,
      ),
      duration: _answerLatency,
    );
  }

  @override
  Future<InterviewSessionData> getSession(String sessionId) async {
    final state = _states[sessionId];
    return _delay(
      InterviewSessionData(
        sessionId: sessionId,
        questionNumber: 1,
        totalQuestions: state?.questions.length ?? 8,
        topic: state?.currentTopicHint ?? MockInterviewData.topicOrder.first,
        difficulty: Difficulty.senior.label,
        question: state?.questions.first.prompt ?? '',
      ),
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  Future<void> completeInterview(String sessionId) async =>
      _delay(null, duration: const Duration(milliseconds: 500));

  @override
  Future<InterviewReport?> getFeedback(String sessionId) async =>
      _delay(null, duration: const Duration(milliseconds: 300));
}

class _MockSessionState {
  _MockSessionState({required this.questions});

  /// The 8-question sequence generated for the session's topic.
  final List<InterviewQuestion> questions;

  /// Index of the next REGULAR question to deliver (0-based). A pending
  /// adaptive follow-up occupies the current slot without advancing this.
  int nextIndex = 1;

  /// Non-null while a generated follow-up is pending to be answered.
  String? pendingFollowUpPrompt;

  /// Index of the question the pending follow-up derives from.
  int followUpSourceIndex = 0;

  String get currentTopicHint =>
      questions[(nextIndex - 1).clamp(0, questions.length - 1)].topic;

  /// Finds a question by its exact prompt text (used for follow-ups).
  InterviewQuestion? questionForPrompt(String prompt) {
    final p = prompt.trim();
    for (final q in questions) {
      if (q.prompt.trim() == p) return q;
    }
    return null;
  }
}

// ===========================================================================
// REAL BACKEND MODE — FastAPI over HTTP.
// ===========================================================================

/// Exception carrying the backend's error details.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// HTTP implementation of [InterviewApiService] for the FastAPI backend.
///
/// No API key is ever sent: the Hugging Face token stays on the backend.
class RealInterviewApiService implements InterviewApiService {
  RealInterviewApiService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _client;
  final String baseUrl;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> get _headers => const {'Content-Type': 'application/json'};

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final res = await _client
        .post(_uri(path), headers: _headers, body: jsonEncode(body))
        .timeout(ApiConfig.networkTimeout);
    if (res.statusCode >= 400) {
      throw ApiException(
        'Backend error ${res.statusCode} on $path',
        statusCode: res.statusCode,
      );
    }
    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException('Unexpected response shape from $path');
    }
    // The backend reports failures as 200 + {"error": ...} bodies. Surface
    // them as exceptions instead of silently parsing them into zero-score
    // evaluations.
    final error = decoded['error'];
    if (error is String && error.isNotEmpty) {
      throw ApiException('Backend error on $path: $error');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> _getJson(String path) async {
    final res = await _client
        .get(_uri(path), headers: _headers)
        .timeout(ApiConfig.networkTimeout);
    if (res.statusCode >= 400) {
      throw ApiException(
        'Backend error ${res.statusCode} on $path',
        statusCode: res.statusCode,
      );
    }
    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException('Unexpected response shape from $path');
    }
    final error = decoded['error'];
    if (error is String && error.isNotEmpty) {
      throw ApiException('Backend error on $path: $error');
    }
    return decoded;
  }

  @override
  Future<Candidate> fetchCandidate(String candidateId) async {
    final json = await _getJson(ApiConfig.candidatePath(candidateId));
    return Candidate.fromJson(json);
  }

  @override
  Future<InterviewStartData> startInterview({
    required String candidateId,
    required String focus,
    required String topic,
  }) async {
    final json = await _postJson(ApiConfig.interviewStartPath, {
      'candidate_id': candidateId,
      'focus': focus,
      'topic': topic,
    });
    return InterviewStartData.fromJson(json);
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
    final json = await _postJson(ApiConfig.interviewAnswerPath, {
      'session_id': sessionId,
      'question': question,
      'answer': answer,
      'topic': topic,
      'question_number': questionNumber,
      'difficulty': difficulty,
      'expected_focus': expectedFocus,
    });
    return AnswerEvaluation.fromJson(json);
  }

  @override
  Future<InterviewSessionData> getSession(String sessionId) async {
    final json = await _getJson(ApiConfig.interviewSessionPath(sessionId));
    return InterviewSessionData.fromJson(json);
  }

  @override
  Future<void> completeInterview(String sessionId) async {
    await _postJson(ApiConfig.interviewCompletePath(sessionId), {
      'session_id': sessionId,
    });
  }

  @override
  Future<InterviewReport?> getFeedback(String sessionId) async {
    final json = await _getJson(ApiConfig.interviewFeedbackPath(sessionId));
    return InterviewReport.fromJson(json);
  }
}
