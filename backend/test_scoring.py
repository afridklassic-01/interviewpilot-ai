"""
Scoring pipeline tests for InterviewPilot AI.

Two parts:

1. Pure unit tests (no AI / no network):
   - compute_overall_score uses the weighted formula (30/20/25/25).
   - validate_result clamps 0..100, computes the overall, and raises
     real errors instead of silently substituting 5/55.
   - extract_json handles code fences and raises on garbage.

2. Live AI evaluation harness (needs HF_TOKEN in .env):
   - Evaluates the 8 answer-quality scenarios end to end and prints
     the scores, so you can verify wrong answers score low, excellent
     answers score high, and identical answers on different questions
     get different scores.

Run unit tests only:
    python test_scoring.py unit

Run unit tests + live AI checks (slower, calls Hugging Face):
    python test_scoring.py all
"""

import sys
import json

# Windows consoles default to cp1252 and choke on Unicode from the model.
try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:  # noqa: BLE001
    pass

from interview_agent import (
    compute_overall_score,
    extract_json,
    validate_result,
    evaluate_answer,
)


def _base_result(**overrides):
    result = {
        "technical_depth": 50,
        "communication": 50,
        "problem_solving": 50,
        "architecture": 50,
        "is_valid": True,
        "answer_quality": "good",
        "feedback": "ok",
        "strengths": ["depth"],
        "missing_concepts": ["reranking"],
        "next_question": "next question?",
        "next_topic": "RAG",
        "next_difficulty": "Senior-level",
        "is_follow_up": False,
        "follow_up_reason": "",
    }
    result.update(overrides)
    return result


# ============================================================
# UNIT TESTS
# ============================================================

def test_compute_overall_weights():
    # 82*0.30 + 90*0.20 + 73*0.25 + 61*0.25
    # = 24.6 + 18.0 + 18.25 + 15.25 = 76.1 -> 76
    assert compute_overall_score({
        "technical_depth": 82,
        "communication": 90,
        "problem_solving": 73,
        "architecture": 61,
    }) == 76

    # The formula must NOT just copy technical_depth.
    assert compute_overall_score({
        "technical_depth": 82,
        "communication": 90,
        "problem_solving": 73,
        "architecture": 61,
    }) != 82


def test_compute_overall_rounding():
    # 0.3*30 + 0.2*30 + 0.25*30 + 0.25*30 = 30
    assert compute_overall_score({
        "technical_depth": 30,
        "communication": 30,
        "problem_solving": 30,
        "architecture": 30,
    }) == 30


def test_validate_result_computes_score():
    result = _base_result(
        technical_depth=82,
        communication=90,
        problem_solving=73,
        architecture=61,
    )
    validated = validate_result(result)
    assert validated["score"] == 76
    assert validated["score"] == compute_overall_score(validated)


def test_validate_result_clamps():
    result = _base_result(
        technical_depth=250,
        communication=-10,
        problem_solving=55,
        architecture=61,
    )
    validated = validate_result(result)
    assert validated["technical_depth"] == 100
    assert validated["communication"] == 0


def test_validate_result_raises_on_missing_field():
    bad = _base_result()
    del bad["feedback"]
    try:
        validate_result(bad)
        raise AssertionError("expected ValueError")
    except ValueError as e:
        assert "feedback" in str(e)


def test_validate_result_raises_on_non_numeric():
    bad = _base_result(technical_depth="high")
    try:
        validate_result(bad)
        raise AssertionError("expected ValueError")
    except ValueError as e:
        assert "technical_depth" in str(e)


def test_extract_json_with_fences():
    text = 'Sure! Here you go:\n```json\n{"a": 1, "b": [1, 2]}\n```\nHope that helps.'
    assert extract_json(text) == {"a": 1, "b": [1, 2]}


def test_extract_json_raises_on_garbage():
    try:
        extract_json("no json here at all")
        raise AssertionError("expected ValueError")
    except ValueError as e:
        assert "No JSON object" in str(e)


def run_unit_tests():
    tests = [
        ("weighted overall formula", test_compute_overall_weights),
        ("overall rounding", test_compute_overall_rounding),
        ("validate computes score", test_validate_result_computes_score),
        ("validate clamps 0..100", test_validate_result_clamps),
        ("validate raises on missing field", test_validate_result_raises_on_missing_field),
        ("validate raises on non-numeric", test_validate_result_raises_on_non_numeric),
        ("extract_json code fences", test_extract_json_with_fences),
        ("extract_json raises on garbage", test_extract_json_raises_on_garbage),
    ]
    failed = 0
    for name, fn in tests:
        try:
            fn()
            print(f"  PASS  {name}")
        except Exception as e:  # noqa: BLE001
            failed += 1
            print(f"  FAIL  {name}: {e}")
    print(f"\n{len(tests) - failed}/{len(tests)} unit tests passed")
    return failed == 0


# ============================================================
# LIVE AI EVALUATION HARNESS
# ============================================================

QUESTION_FAISS = (
    "Explain how you would configure FAISS for 10 million "
    "768-dimensional vectors."
)

ANSWERS = [
    ("TEST 1 - empty answer", ""),
    ("TEST 2 - irrelevant answer", "I really enjoy hiking on weekends and "
     "cooking pasta for my family. The weather today is nice."),
    ("TEST 3 - wrong technical answer", "FAISS is a framework for CSS "
     "styling websites, so I would configure its themes."),
    ("TEST 4 - partially correct answer", "You can store vectors in a "
     "database and search them."),
    ("TEST 5 - good answer", "I would use FAISS with an index that fits "
     "10 million 768-d vectors in memory: roughly 30 GB for vectors plus "
     "graph overhead for HNSW. I would build with HNSW, M=32, "
     "efConstruction=200, then tune efSearch against Recall@K and p95 "
     "latency on an eval set, and shard the index across servers as it "
     "grows."),
    ("TEST 6 - excellent senior answer", "I would start with a flat or "
     "PQ-compressed index benchmark before committing to HNSW. For 10M x "
     "768 floats the raw vectors are ~30GB; with HNSW M=32, efConstruction "
     "~200, add ~10-20% for graph links. I would tune efSearch per query "
     "profile against Recall@10 and p95 latency, add product quantization "
     "with 16-32 bytes per vector if RAM is tight, measure true recall with "
     "an exhaustive flat index on a sample, plan for index rebuilds on data "
     "refresh, and load-test concurrent search throughput before deciding "
     "on sharding. I would also monitor recall drift in production."),
    ("TEST 7 - same answer, different question", "I would use HNSW with "
     "M=32 and efConstruction=200, then tune efSearch on Recall@K and p95 "
     "latency, provisioning memory for vectors and graph overhead."),
]


def run_live_checks():
    print("\n=== LIVE AI EVALUATION (Hugging Face) ===\n")

    # TEST 7/8: same answer against a relevant and an irrelevant question.
    same_answer = ANSWERS[-1][1]
    pairs = [
        ("TEST 7 - different answers, same question",
         QUESTION_FAISS, ANSWERS[2][1], ANSWERS[6][1]),
        ("TEST 8 - same answer, different questions",
         "Design a system prompt for a customer-support assistant.",
         same_answer, QUESTION_FAISS),
    ]

    try:
        for label, q, a1, a2 in pairs:
            r1 = evaluate_answer(q, a1, "Vector Databases", [])
            r2 = evaluate_answer(q, a2, "Vector Databases", [])
            s1 = r1["score"]
            s2 = r2["score"]
            status = "OK" if s1 != s2 else "SAME (problem)"
            print(f"[{status}] {label}: score {s1} vs {s2}")
            print(f"         dims: {r1['technical_depth']}/{r1['communication']}/{r1['problem_solving']}/{r1['architecture']} "
                  f"vs {r2['technical_depth']}/{r2['communication']}/{r2['problem_solving']}/{r2['architecture']}")

        print()
        for label, answer in ANSWERS[:-1]:
            result = evaluate_answer(QUESTION_FAISS, answer, "Vector Databases", [])
            print(f"[{label}]")
            print(f"  score={result['score']}  td={result['technical_depth']} "
                  f"comm={result['communication']} ps={result['problem_solving']} "
                  f"arch={result['architecture']}  quality={result.get('answer_quality')}")
    except Exception as e:  # noqa: BLE001
        print(f"  Live AI check failed: {type(e).__name__}: {e}")
        print("  (This usually means HF_TOKEN is missing or the model call failed.)")
        return False
    return True


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "unit"
    ok = run_unit_tests()
    if mode == "all":
        live_ok = run_live_checks()
        ok = ok and live_ok
    print("\nRESULT:", "PASS" if ok else "FAIL")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
