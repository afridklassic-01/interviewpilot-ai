/// Central configuration for backend connectivity.
///
/// SECURITY:
/// The API token NEVER lives inside Flutter.
/// It stays inside the FastAPI backend's .env file.
///
/// Flutter only communicates with the FastAPI backend over HTTP REST.
class ApiConfig {
  ApiConfig._();

  // ============================================================
  // BACKEND URL
  // ============================================================

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://interviewpilot-ai-3zl3.onrender.com',
  );

  // ============================================================
  // BACKEND MODE
  // ============================================================

  static const bool useMockBackend = bool.fromEnvironment(
    'USE_MOCK_BACKEND',
    defaultValue: false,
  );

  // ============================================================
  // NETWORK SETTINGS
  // ============================================================

  static const Duration networkTimeout = Duration(
    seconds: 45,
  );

  // ============================================================
  // INTERVIEW ENDPOINTS
  // ============================================================

  static String get interviewStartPath {
    return '/api/interview/start';
  }

  static String get interviewAnswerPath {
    return '/api/interview/answer';
  }

  // ============================================================
  // OTHER INTERVIEW ENDPOINTS
  // ============================================================

  static String interviewSessionPath(String sessionId) {
    return '/api/interview/$sessionId';
  }

  static String interviewCompletePath(String sessionId) {
    return '/api/interview/$sessionId/complete';
  }

  static String interviewFeedbackPath(String sessionId) {
    return '/api/interview/$sessionId/feedback';
  }

  // ============================================================
  // CANDIDATE ENDPOINT
  // ============================================================

  static String candidatePath(String candidateId) {
    return '/api/candidate/$candidateId';
  }

  // ============================================================
  // URL BUILDER
  // ============================================================

  static String resolve(String path) {
    return '$baseUrl$path';
  }
}