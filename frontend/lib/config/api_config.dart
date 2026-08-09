/// Central configuration for backend connectivity.
///
/// SECURITY:
/// The Hugging Face API token NEVER lives inside Flutter.
/// It stays inside the FastAPI backend's .env file.
///
/// Flutter only communicates with the FastAPI backend over HTTP REST.
class ApiConfig {
  ApiConfig._();

  // ============================================================
  // BACKEND URL
  // ============================================================

  /// FastAPI backend URL.
  ///
  /// Local development:
  /// http://127.0.0.1:8000
  ///
  /// For deployment, use:
  /// --dart-define=API_BASE_URL=https://your-api-domain.com
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  // ============================================================
  // BACKEND MODE
  // ============================================================

  /// false = use real FastAPI backend
  /// true  = use Flutter mock backend
  static const bool useMockBackend = bool.fromEnvironment(
    'USE_MOCK_BACKEND',
    defaultValue: false,
  );

  // ============================================================
  // NETWORK SETTINGS
  // ============================================================

  /// Maximum time allowed for a backend request.
  ///
  /// Kept generous: the evaluator prompt is long and Hugging Face
  /// inference can take 20-45s per answer.
  static const Duration networkTimeout = Duration(
    seconds: 45,
  );

  // ============================================================
  // INTERVIEW ENDPOINTS
  // ============================================================

  /// Start a new interview.
  ///
  /// POST:
  /// http://127.0.0.1:8000/api/interview/start
  static String get interviewStartPath {
    return '/api/interview/start';
  }

  /// Submit candidate answer.
  ///
  /// POST:
  /// http://127.0.0.1:8000/api/interview/answer
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

  /// Converts an endpoint path into a complete URL.
  ///
  /// Example:
  ///
  /// resolve('/api/interview/start')
  ///
  /// becomes:
  ///
  /// http://127.0.0.1:8000/api/interview/start
  static String resolve(String path) {
    return '$baseUrl$path';
  }
}