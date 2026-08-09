import json
import re

from ai_service import generate_ai_response


# ============================================================
# SCORING MODEL
# ============================================================
# The overall score is ALWAYS computed from the four independent
# dimensions below — it is never copied from a single AI field and
# never replaced by a fixed fallback value.
#
#   Technical Depth   = 30%
#   Communication     = 20%
#   Problem Solving   = 25%
#   Architecture      = 25%
# ============================================================

SCORE_WEIGHTS = {
    "technical_depth": 0.30,
    "communication": 0.20,
    "problem_solving": 0.25,
    "architecture": 0.25,
}


def compute_overall_score(result):
    """
    Weighted overall score (0-100, rounded) from the four dimensions.
    """
    total = sum(
        result.get(key, 0) * weight
        for key, weight in SCORE_WEIGHTS.items()
    )
    return int(round(max(0.0, min(100.0, total))))


# ============================================================
# JSON EXTRACTION
# ============================================================

def extract_json(text):
    """
    Extract the first complete JSON object from the AI response.
    Handles responses wrapped in ```json ... ``` as well.
    Raises ValueError with the real reason on failure — never
    silently substitutes a fixed score.
    """

    if not text:
        raise ValueError("AI returned an empty response")

    text = text.strip()

    # Remove markdown code fences
    text = re.sub(r"```json\s*", "", text, flags=re.IGNORECASE)
    text = re.sub(r"```\s*", "", text)

    text = text.strip()

    # Find JSON object
    start = text.find("{")

    if start == -1:
        raise ValueError("No JSON object found in AI response")

    # Find matching closing brace
    depth = 0
    in_string = False
    escape = False

    for i in range(start, len(text)):

        char = text[i]

        if escape:
            escape = False
            continue

        if char == "\\":
            escape = True
            continue

        if char == '"':
            in_string = not in_string
            continue

        if not in_string:

            if char == "{":
                depth += 1

            elif char == "}":
                depth -= 1

                if depth == 0:
                    json_text = text[start:i + 1]

                    try:
                        return json.loads(json_text)

                    except json.JSONDecodeError as e:
                        raise ValueError(
                            f"Invalid JSON returned by AI: {e}"
                        )

    raise ValueError("AI returned incomplete JSON")


# ============================================================
# VALIDATION
# ============================================================

def validate_result(result):
    """
    Validate and normalize the AI evaluation result.

    - Every dimension is coerced to an integer clamped to 0..100.
    - The overall score is COMPUTED from the dimensions (weighted).
    - Invalid responses raise ValueError with the actual error so the
      caller can surface it — no silent 5/55 fallbacks.
    """

    required_fields = [
        "technical_depth",
        "communication",
        "problem_solving",
        "architecture",
        "is_valid",
        "feedback",
        "strengths",
        "missing_concepts",
        "next_question",
        "next_topic",
        "next_difficulty",
        "is_follow_up",
        "follow_up_reason",
    ]

    missing = [
        field for field in required_fields
        if field not in result
    ]

    if missing:
        raise ValueError(
            f"AI response is missing fields: {missing}"
        )

    # Clamp + coerce the four dimensions.
    dimension_fields = [
        "technical_depth",
        "communication",
        "problem_solving",
        "architecture",
    ]

    for field in dimension_fields:

        try:
            result[field] = int(result[field])
        except (ValueError, TypeError):
            raise ValueError(
                f"{field} must be a number, got: {result[field]!r}"
            )

        result[field] = max(0, min(100, result[field]))

    # Overall is always derived from the dimensions.
    result["score"] = compute_overall_score(result)

    # Make sure lists are lists.
    if not isinstance(result["strengths"], list):
        result["strengths"] = [str(result["strengths"])]

    if not isinstance(result["missing_concepts"], list):
        result["missing_concepts"] = [
            str(result["missing_concepts"])
        ]

    # answer_quality is advisory metadata; keep it if present.
    result.setdefault("answer_quality", "")

    return result


# ============================================================
# EVALUATION
# ============================================================

def evaluate_answer(
    question,
    answer,
    topic,
    history,
    difficulty="Senior-level",
    expected_focus=None,
):
    expected_focus = expected_focus or []

    prompt = f"""
You are an expert technical interviewer conducting an adaptive
engineering interview.

Evaluate the candidate's answer to the CURRENT QUESTION. Your job is
to judge whether the candidate actually answered THIS question, and
how well. Do not give credit for generic text that does not address
the question.

CURRENT QUESTION:
{question}

TOPIC:
{topic}

DIFFICULTY:
{difficulty}

EXPECTED CONCEPTS / EVALUATION CRITERIA:
{json.dumps(expected_focus, ensure_ascii=False)}

CANDIDATE ANSWER:
{answer}

PREVIOUS INTERVIEW HISTORY (question/answer/evaluation pairs):
{json.dumps(history, ensure_ascii=False)}

STEP 1 — RELEVANCE FIRST.
Decide whether the answer addresses the question at all. An empty
answer, "I don't know", or an unrelated answer must score very low on
EVERY dimension. A strong but off-topic answer must still score low on
relevance-sensitive dimensions.

STEP 2 — SCORE EACH DIMENSION INDEPENDENTLY, 0-100, using these
anchors:

  0-15    no answer, refusal, or completely irrelevant content
  16-35   mostly incorrect or superficial; key concepts missing
  36-55   partially correct; some relevant concepts, shallow or flawed
  56-75   correct core ideas with reasonable depth but some gaps
  76-90   correct, specific, with real engineering depth
  91-100  exceptional: precise, quantitative, complete, with trade-offs

TECHNICAL DEPTH:
technical correctness, relevant concepts, implementation details,
algorithms, models, indexes, parameters, trade-offs, limitations,
quantitative reasoning.

COMMUNICATION:
clarity, structure, directness, explanation, technical vocabulary,
relevance to the question.

PROBLEM SOLVING:
reasoning, problem decomposition, constraints, trade-offs, failure
cases, solution strategy.

ARCHITECTURE:
system design, scalability, reliability, performance, cost,
deployment, production concerns.

The four dimensions MUST be scored independently. It is completely
valid for them to differ (e.g. technical_depth 82, communication 90,
problem_solving 73, architecture 61). Never assign the same number to
all four unless the answer genuinely merits it.

STEP 3 — NEXT QUESTION.
The next question must be a real technical interview question that:

- stays within the topic "{topic}" (keep next_topic exactly "{topic}"),
- probes a genuinely missing or weak area from THIS answer when one
  exists,
- otherwise explores a NEW sub-area of "{topic}" so the 8-question
  interview covers breadth: architecture, embeddings, retrieval,
  indexing, chunking, prompt design, evaluation, scaling, cost,
  deployment ...
- never repeats the same narrow concept (e.g. HNSW / Pinecone /
  vector-store selection) unless the candidate's answer genuinely
  requires another follow-up,
- does not leak that it is generated from a rubric.

Use "is_follow_up": true ONLY when the next question derives directly
from the candidate's previous answer; otherwise false.

Return ONLY valid JSON. Do not use Markdown. Do not use ```json.
Do not add explanations outside the JSON.

Use exactly this structure:

{{
  "technical_depth": 0,
  "communication": 0,
  "problem_solving": 0,
  "architecture": 0,
  "is_valid": true,
  "answer_quality": "low",
  "feedback": "short constructive feedback",
  "strengths": [
    "strength"
  ],
  "missing_concepts": [
    "missing concept"
  ],
  "next_question": "next interview question",
  "next_topic": "{topic}",
  "next_difficulty": "Senior-level",
  "is_follow_up": false,
  "follow_up_reason": "why this question follows the candidate's answer"
}}

Rules:

- All dimension scores must be integers from 0 to 100.
- "answer_quality" must be one of: low, partial, good, strong, excellent.
- Do not give credit for concepts the candidate did not explain.
- Focus on technical correctness rather than grammar.
- feedback should be concise and useful.
- missing_concepts must contain specific concepts.
- next_question must be a real technical interview question related to
  the candidate's previous answer.
- Do not reveal hidden reasoning.
"""

    # Ask the AI
    response = generate_ai_response(prompt)

    print("\n========== RAW AI RESPONSE ==========")
    print(response)
    print("=====================================\n")

    # Extract JSON safely — raises ValueError with the real error when
    # the model returns invalid output. Never silently falls back.
    result = extract_json(response)

    # Validate + normalize. Computes the overall score from dimensions.
    result = validate_result(result)

    return result
