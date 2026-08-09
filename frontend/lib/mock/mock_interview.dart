import '../models/question.dart';

/// Offline simulation of the FastAPI backend.
///
/// The real backend runs Hugging Face inference; this engine mimics the
/// same observable behavior deterministically from the candidate's answer.
/// It never contains a "correct answer" — only heuristics over the answer's
/// content (vocabulary, structure, coverage, relevance), exactly like the
/// real model weighs those signals.
class MockInterviewData {
  MockInterviewData._();

  static const String focus = 'MCP + Production AI Systems';

  /// Canonical interview-topic order.
  ///
  /// This is the SINGLE source of truth for topic progression (coverage
  /// panel, next-topic selection, dashboard). It is the existing curriculum
  /// topic list already used by the app — no second curriculum is created.
  static const List<String> topicOrder = [
    'RAG',
    'Vector Databases',
    'Prompt Engineering',
    'Agentic AI',
    'MCP',
    'AI Deployment',
    'Production AI Systems',
  ];

  /// Curriculum anchor (day, title) for each topic, from the existing cohort.
  static (int, String) _anchorFor(String topic) => switch (topic) {
        'RAG' => (12, 'Retrieval-Augmented Generation'),
        'Vector Databases' => (15, 'Vector Databases'),
        'Prompt Engineering' => (7, 'Prompt Engineering'),
        'Agentic AI' => (24, 'Agentic AI'),
        'MCP' => (18, 'MCP Architecture'),
        _ => (31, 'AI Deployment & Production Systems'),
      };

  /// Broad sub-areas per topic — the 8-question interview walks through
  /// them so a single topic is covered with breadth, not one narrow concept.
  static const Map<String, List<String>> _subAreas = {
    'RAG': [
      'retrieval-augmented generation pipeline and how it grounds answers to reduce hallucinations',
      'the retrieval layer of a production RAG system and how you would handle irrelevant retrieval results',
      'chunk size, chunk overlap and embedding strategy on long documents',
      'reranking, hybrid search and how you would measure retrieval quality',
      'system prompts and guardrails for a grounded assistant built on retrieved evidence',
      'detecting and mitigating hallucination in production RAG responses',
      'cost, latency and scale trade-offs when serving RAG at volume',
      'evaluating a RAG system: metrics, eval sets and regression detection',
    ],
    'Vector Databases': [
      'choosing between hosted and self-hosted vector databases for a production workload',
      'index types such as HNSW and IVF and how you would configure them at scale',
      'metadata filtering and hybrid search over a large vector collection',
      'handling fresh data, updates and deletions without breaking recall',
      'capacity planning: memory, quantization and sharding for millions of vectors',
      'measuring and tuning recall, precision and p95 latency',
      'failover, replication and backups for a vector database',
      'cost trade-offs across Pinecone, Qdrant, pgvector and FAISS',
    ],
    'Prompt Engineering': [
      'designing a system prompt for a production assistant with strict guardrails',
      'keeping prompts maintainable across product iterations',
      'prompt injection and how you would defend against it',
      'few-shot examples: when they help and when they hurt',
      'structured outputs and tool-calling reliability',
      'measuring prompt quality and iterating with an eval set',
      'token budget, context window and cost management',
      'prompt versioning, testing and rollout',
    ],
    'Agentic AI': [
      'designing a production agent loop that calls internal tools',
      'preventing tool misuse and enforcing permissions',
      'handling tool failures, retries and partial results',
      'keeping agent loops observable and debuggable',
      'planning versus reactive loops and when to use each',
      'safety, sandboxing and human-in-the-loop checkpoints',
      'scaling agents: concurrency, state and cost',
      'evaluating agent performance end to end',
    ],
    'MCP': [
      'what the Model Context Protocol standardizes and why it matters',
      'designing MCP servers for internal tools and data',
      'where MCP adds operational complexity for a team',
      'security boundaries and authentication for MCP connections',
      'MCP versus custom integrations: trade-offs',
      'versioning and compatibility across MCP servers',
      'monitoring and debugging MCP traffic in production',
      'governing a growing catalog of MCP servers',
    ],
    'AI Deployment': [
      'designing the evaluation, monitoring and rollout strategy for an AI assistant',
      'the metrics you would watch in the first week of production',
      'handling silent regressions after a model or data refresh',
      'canary releases and gradual rollout for LLM features',
      'cost control: token spend, caching and model routing',
      'incident response for a degraded AI service',
      'compliance, data handling and privacy in AI deployment',
      'building a feedback loop from production traffic to retraining',
    ],
    'Production AI Systems': [
      'detecting retrieval-quality regression after a data refresh',
      'diagnosing the root cause of a production quality drop',
      'preventing repeat regressions with eval gates',
      'architecting for reliability: fallbacks, retries and circuit breakers',
      'capacity and latency engineering for AI services',
      'observability: tracing prompts, tool calls and answers',
      'data drift and model drift detection',
      'trade-offs in a multi-model production architecture',
    ],
  };

  /// Expected-focus chips shown on each question card, per topic.
  static const Map<String, List<String>> _focusAreas = {
    'RAG': ['RAG pipeline', 'Grounding', 'Failure modes'],
    'Vector Databases': ['Indexing', 'Retrieval quality', 'Operations'],
    'Prompt Engineering': ['System prompts', 'Guardrails', 'Maintainability'],
    'Agentic AI': ['Tool design', 'Guardrails', 'Observability'],
    'MCP': ['Protocol design', 'Tool integration', 'Trade-offs'],
    'AI Deployment': ['Evaluation', 'Monitoring', 'Rollout'],
    'Production AI Systems': ['Detection', 'Diagnosis', 'Prevention'],
  };

  static const List<String> _stems = [
    'Walk me through how you would handle ',
    'Explain your approach to ',
    'Design the solution for ',
    'What trade-offs and failure modes matter for ',
  ];

  /// Builds the 8-question sequence for a single topic. Every question
  /// covers a different sub-area (breadth), and difficulty ramps to
  /// staff-level for the final two questions.
  static List<InterviewQuestion> questionsForTopic(
    String topic, {
    int count = 8,
  }) {
    final areas = _subAreas[topic] ?? _subAreas['RAG']!;
    final focus = _focusAreas[topic] ?? _focusAreas['RAG']!;
    final (day, title) = _anchorFor(topic);
    return [
      for (var i = 0; i < count; i++)
        InterviewQuestion(
          id: 'q${i + 1}',
          topic: topic,
          prompt: '${_stems[i % _stems.length]}${areas[i % areas.length]}. '
              'Reason through your answer like a senior engineer — structure, '
              'trade-offs and failure modes carry weight.',
          difficulty: i >= count - 2 ? Difficulty.staff : Difficulty.senior,
          expectedFocus: focus,
          curriculumDay: '$day',
          curriculumTitle: title,
        ),
    ];
  }
}

/// Intermediate evaluation result produced by the offline engine.
class MockEvalResult {
  const MockEvalResult({
    required this.score,
    required this.technicalDepth,
    required this.communication,
    required this.problemSolving,
    required this.architecture,
    required this.isValid,
    required this.feedback,
    required this.strengths,
    required this.missingConcepts,
    this.followUpPrompt,
    this.followUpReason,
  });

  final double score;
  final double technicalDepth;
  final double communication;
  final double problemSolving;
  final double architecture;
  final bool isValid;
  final String feedback;
  final List<String> strengths;
  final List<String> missingConcepts;

  /// Follow-up question derived from the answer, if any.
  final String? followUpPrompt;
  final String? followUpReason;
}

/// Deterministic answer evaluation engine (mock backend brain).
///
/// Scores are driven by what the answer ACTUALLY contains: whether it
/// addresses the question (relevance), depth of vocabulary, reasoning,
/// structure and production awareness. A refusal or an off-topic answer
/// scores very low; a deep, structured answer scores high. The four
/// dimensions are weighted independently (30/20/25/25) so they differ.
class MockEvaluationEngine {
  const MockEvaluationEngine();

  static const List<String> _architectureWords = [
    'trade-off', 'tradeoff', 'latency', 'cost', 'scale', 'throughput',
    'concurrency', 'guardrail', 'observab', 'rollout', 'fallback',
    'redundancy', 'caching', 'monitor', 'evaluat', 'benchmark', 'sla',
  ];

  static const List<String> _qualityWords = [
    'rerank', 'hybrid', 'filter', 'metadata', 'recall', 'precision',
    'threshold', 'relevance', 'chunk', 'embedding', 'pipeline',
  ];

  static const List<String> _reasoningWords = [
    'because', 'therefore', 'so that', 'instead of', 'depends', 'would',
    'trade-off', 'tradeoff', 'if ', 'then ', 'when ', 'failure', 'cost',
    'scale', 'latency',
  ];

  static const List<String> _refusalPhrases = [
    "i don't know", 'i dont know', 'i do not know', "i'm not sure",
    'i am not sure', 'no idea', 'i have no idea', 'not sure', 'idk',
    'dunno', 'unable to answer', "i can't answer", 'i cannot answer',
  ];

  /// Returns the name of a vector store mentioned in the answer, if any.
  static String? detectVectorStore(String answer) {
    const stores = {
      'pinecone': 'Pinecone',
      'qdrant': 'Qdrant',
      'weaviate': 'Weaviate',
      'milvus': 'Milvus',
      'chroma': 'Chroma',
      'pgvector': 'pgvector',
      'faiss': 'FAISS',
      'elasticsearch': 'Elasticsearch',
      'redis': 'Redis',
    };
    final lower = answer.toLowerCase();
    for (final entry in stores.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return null;
  }

  static bool _containsAny(String text, List<String> words) =>
      words.any(text.contains);

  static bool _hasStructure(String answer) {
    return RegExp(r'(First|Second|Third|Finally|1\.|2\.|3\.|•|\n-)',
            caseSensitive: false)
        .hasMatch(answer);
  }

  static double _clamp(double v) => v.clamp(0.0, 98.0);

  /// Number of distinct vocabulary tokens from the question (topic +
  /// expected focus + the question's own prompt words) that appear in the
  /// answer. A light relevance signal: the SAME answer scores differently
  /// on DIFFERENT questions.
  static int _topicHits(String lower, InterviewQuestion question) {
    final tokens = <String>{
      for (final w in question.topic.toLowerCase().split(RegExp(r'\s+')))
        if (w.length >= 3) w,
      for (final f in question.expectedFocus)
        for (final w in f.toLowerCase().split(RegExp(r'\s+')))
          if (w.length >= 3) w,
      for (final w
          in question.prompt.toLowerCase().split(RegExp(r'[^a-z0-9]+')))
        if (w.length >= 4) w,
    };
    if (tokens.isEmpty) return 1;
    return tokens.where(lower.contains).length;
  }

  /// Evaluates an answer and returns the mock backend evaluation.
  static MockEvalResult evaluate({
    required InterviewQuestion question,
    required String answer,
  }) {
    final trimmed = answer.trim();
    final lower = trimmed.toLowerCase();
    final words =
        trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

    final isEmpty = trimmed.isEmpty;
    final refusal = !isEmpty && _containsAny(lower, _refusalPhrases);
    final invalid = words < 5;
    final hasQuality = _containsAny(lower, _qualityWords);
    final hasArch = _containsAny(lower, _architectureWords);
    final structured = _hasStructure(trimmed);
    final hasReasoning = _containsAny(lower, _reasoningWords);
    final hits = _topicHits(lower, question);

    // Base tier: how much the answer actually addresses the question.
    // The content of the answer — not a rubric — decides the score.
    final double tier;
    if (isEmpty || refusal) {
      tier = 4; // No real attempt.
    } else if (invalid) {
      tier = 12; // Too short to evaluate.
    } else if (hits == 0 && !hasQuality && !hasArch) {
      tier = 18; // Off-topic / unrelated.
    } else if (hits < 3 && !(hasQuality && hasArch)) {
      tier = 32; // Only partially on topic.
    } else {
      tier = 48; // Directly addresses the question.
    }

    final technicalDepth = _clamp(
      tier + (hasQuality ? 16 : 0) + (hasArch ? 8 : 0) +
          (words >= 40 ? 10 : words >= 20 ? 5 : 0) + (hasReasoning ? 6 : 0),
    );
    final communication = _clamp(
      tier + (structured ? 16 : 0) +
          (words >= 40 ? 12 : words >= 20 ? 6 : 0) +
          (words <= 280 ? 4 : 0) + (hasReasoning ? 4 : 0),
    );
    final problemSolving = _clamp(
      tier + (hasReasoning ? 14 : 0) + (hasArch ? 10 : 0) +
          (hasQuality ? 8 : 0) + (words >= 25 ? 6 : 0),
    );
    final architecture = _clamp(
      tier + (hasArch ? 20 : 0) + (hasQuality ? 8 : 0) +
          (structured ? 6 : 0) + (hasReasoning ? 4 : 0),
    );
    final score = _clamp(
      (technicalDepth * 0.3) + (communication * 0.2) +
          (problemSolving * 0.25) + (architecture * 0.25),
    );

    // Strengths derived from what the answer actually covered.
    final strengths = <String>[
      if (hasQuality) 'Solid command of retrieval-quality vocabulary',
      if (hasArch) 'Names production trade-offs and operational concerns',
      if (structured) 'Answers are structured and easy to follow',
      if (words >= 25 && tier >= 48) 'Good depth for the question',
    ];

    // Missing concepts derived from what the answer left out.
    final missingConcepts = <String>[
      if (!lower.contains('rerank')) 'Reranking',
      if (!_containsAny(lower, ['monitor', 'evaluat', 'benchmark']))
        'Evaluation & monitoring strategy',
      if (!_containsAny(lower, ['fallback', 'fail', 'retry']))
        'Failure handling',
      if (!_containsAny(lower, ['latency', 'cost', 'trade-off', 'tradeoff']))
        'Operational trade-offs',
    ];
    if (missingConcepts.length > 3) {
      missingConcepts.removeRange(3, missingConcepts.length);
    }

    final String feedback;
    if (isEmpty || refusal) {
      feedback = 'The answer does not attempt the question. Even a partial '
          'answer — naming the key components and one trade-off — would '
          'show progress.';
    } else if (invalid) {
      feedback = 'The answer is too short to evaluate. Please expand it with '
          'structure, trade-offs and failure modes.';
    } else if (score >= 82) {
      feedback = 'Strong response. You reason about ${question.topic} '
          'trade-offs clearly and ground your decisions in production '
          'realities. Depth held up across the full answer.';
    } else if (score >= 64) {
      feedback = 'Solid response with a clear direction. Adding explicit '
          'trade-offs and failure handling around ${question.topic} would '
          'strengthen the engineering depth.';
    } else if (score >= 40) {
      feedback = 'Partially correct: the answer touches ${question.topic} but '
          'stays high-level. Name concrete components, parameters and '
          'failure modes to go deeper.';
    } else {
      feedback = 'The response does not meaningfully address the question. '
          'Restart around the core concepts of ${question.topic} and answer '
          'in a structured way.';
    }

    // Adaptive follow-up: only derived from the candidate's own words and
    // only for genuine attempts at the question.
    String? followUpPrompt;
    String? followUpReason;
    if (tier >= 40) {
      final store = detectVectorStore(trimmed);
      if (store != null && !question.isFollowUp) {
        final isHosted = store == 'Pinecone';
        followUpPrompt = isHosted
            ? 'You chose Pinecone for vector search. What trade-off would make '
                'you choose a self-hosted vector database instead?'
            : 'You chose $store for vector search. What trade-off would make you '
                'choose a different or self-hosted vector database instead?';
        followUpReason =
            'Based on your previous answer — you mentioned $store.';
      }
    }

    return MockEvalResult(
      score: score,
      technicalDepth: technicalDepth,
      communication: communication,
      problemSolving: problemSolving,
      architecture: architecture,
      isValid: !invalid,
      feedback: feedback,
      strengths: invalid ? const [] : strengths,
      missingConcepts: invalid ? const [] : missingConcepts,
      followUpPrompt: followUpPrompt,
      followUpReason: followUpReason,
    );
  }
}
