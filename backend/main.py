from typing import List, Optional

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import uuid

from ai_service import generate_ai_response
from interview_agent import evaluate_answer


# ============================================================
# FASTAPI APP
# ============================================================

app = FastAPI(title="InterviewPilot AI")


# ============================================================
# CORS
# ============================================================
# Required for Flutter Web running in Chrome.
#
# This allows:
# Flutter Web
#     ↓
# FastAPI
#
# during local development.
# ============================================================

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============================================================
# TEMPORARY IN-MEMORY INTERVIEW SESSIONS
# ============================================================

sessions = {}


# ============================================================
# REQUEST MODELS
# ============================================================

class StartInterviewRequest(BaseModel):
    topic: str = "RAG"
    difficulty: str = "Intermediate"
    candidate_id: Optional[str] = ""
    focus: Optional[str] = ""


class AnswerRequest(BaseModel):
    session_id: str
    question: str
    answer: str
    topic: str
    question_number: int
    difficulty: Optional[str] = "Senior-level"
    expected_focus: List[str] = []


# ============================================================
# BASIC ROUTES
# ============================================================

@app.get("/")
def home():
    return {
        "message": "InterviewPilot AI backend is running"
    }


@app.get("/health")
def health():
    return {
        "status": "ok"
    }


# ============================================================
# START INTERVIEW
# ============================================================
# The Flutter frontend picks the topic (next incomplete topic in the
# curriculum) and sends it here. Each interview session covers ONE
# topic for its full 8-question run.

@app.post("/api/interview/start")
def start_interview(request: StartInterviewRequest):

    try:

        # ----------------------------------------------------
        # Create unique interview session
        # ----------------------------------------------------

        session_id = str(uuid.uuid4())

        # ----------------------------------------------------
        # Prompt for AI interviewer
        # ----------------------------------------------------

        prompt = f"""
You are a professional technical interviewer.

Generate ONE technical interview question.

Topic: {request.topic}

Difficulty: {request.difficulty}

Requirements:

- Test practical engineering understanding.
- Require explanation and reasoning.
- Do not make it multiple choice.
- Make it suitable for a technical interview.
- Keep the question clear and concise.
- Stay within the topic "{request.topic}".

Return ONLY the interview question.
"""

        # ----------------------------------------------------
        # Generate question using Hugging Face
        # ----------------------------------------------------

        question = generate_ai_response(prompt)

        # ----------------------------------------------------
        # Make sure AI returned something
        # ----------------------------------------------------

        if not question:
            return {
                "error": "AI failed to generate interview question"
            }

        question = question.strip()

        # ----------------------------------------------------
        # Store interview session
        # ----------------------------------------------------

        sessions[session_id] = {
            "session_id": session_id,
            "question_number": 1,
            "total_questions": 8,
            "current_question": question,
            "current_topic": request.topic,
            "difficulty": request.difficulty,
            "history": [],
            "evaluations": []
        }

        # ----------------------------------------------------
        # Debug information
        # ----------------------------------------------------

        print("\n========================================")
        print("INTERVIEW STARTED")
        print("========================================")
        print("Session ID:", session_id)
        print("Topic:", request.topic)
        print("Difficulty:", request.difficulty)
        print("Question:", question)
        print("========================================\n")

        # ----------------------------------------------------
        # Send response to Flutter
        # ----------------------------------------------------

        return {
            "session_id": session_id,
            "question_number": 1,
            "total_questions": 8,
            "topic": request.topic,
            "difficulty": request.difficulty,
            "question": question
        }

    except Exception as e:

        print("\n========================================")
        print("ERROR IN /api/interview/start")
        print("========================================")
        print("Error type:", type(e).__name__)
        print("Error:", str(e))
        print("========================================\n")

        return {
            "error": type(e).__name__,
            "message": str(e)
        }


# ============================================================
# SUBMIT ANSWER
# ============================================================

@app.post("/api/interview/answer")
def submit_answer(request: AnswerRequest):

    try:

        # ----------------------------------------------------
        # Check whether session exists
        # ----------------------------------------------------

        if request.session_id not in sessions:
            return {
                "error": "Interview session not found"
            }

        session = sessions[request.session_id]

        # ----------------------------------------------------
        # Print submitted answer
        # ----------------------------------------------------

        print("\n========================================")
        print("ANSWER SUBMISSION")
        print("========================================")
        print("Session ID:", request.session_id)
        print("Question:", request.question)
        print("Answer:", request.answer)
        print("Topic:", request.topic)
        print("Question Number:", request.question_number)
        print("========================================")

        # ----------------------------------------------------
        # Evaluate candidate answer
        # ----------------------------------------------------

        result = evaluate_answer(
            question=request.question,
            answer=request.answer,
            topic=request.topic,
            history=session["history"],
            difficulty=request.difficulty or "Senior-level",
            expected_focus=request.expected_focus or []
        )

        # ----------------------------------------------------
        # Print AI evaluation
        # ----------------------------------------------------

        print("\n========================================")
        print("AI EVALUATION RESULT")
        print("========================================")
        print(result)
        print("========================================\n")

        # ----------------------------------------------------
        # Check evaluation result
        # ----------------------------------------------------

        if not result:
            return {
                "error": "AI evaluation returned empty result"
            }

        # ----------------------------------------------------
        # Save conversation history
        # ----------------------------------------------------

        session["history"].append({
            "question": request.question,
            "answer": request.answer,
            "evaluation": result
        })

        # ----------------------------------------------------
        # Save evaluation
        # ----------------------------------------------------

        session["evaluations"].append(result)

        # ----------------------------------------------------
        # Calculate next question number
        # ----------------------------------------------------

        next_question_number = request.question_number + 1

        # ----------------------------------------------------
        # Update session.
        #
        # The interview stays on the topic the frontend requested for
        # its full 8-question run; the AI decides sub-areas and
        # difficulty, never the topic.
        # ----------------------------------------------------

        session["question_number"] = next_question_number

        if next_question_number <= session["total_questions"]:
            session["current_question"] = result.get(
                "next_question",
                ""
            )
        else:
            # Interview complete — no further question.
            session["current_question"] = ""

        session["current_topic"] = request.topic

        session["difficulty"] = result.get(
            "next_difficulty",
            "Intermediate"
        )

        # ----------------------------------------------------
        # Return evaluation to Flutter
        # ----------------------------------------------------

        return {
            "score": result.get("score", 0),

            "technical_depth": result.get(
                "technical_depth",
                0
            ),

            "communication": result.get(
                "communication",
                0
            ),

            "problem_solving": result.get(
                "problem_solving",
                0
            ),

            "architecture": result.get(
                "architecture",
                0
            ),

            "is_valid": result.get(
                "is_valid",
                False
            ),

            "feedback": result.get(
                "feedback",
                ""
            ),

            "strengths": result.get(
                "strengths",
                []
            ),

            "missing_concepts": result.get(
                "missing_concepts",
                []
            ),

            "answer_quality": result.get(
                "answer_quality",
                ""
            ),

            "next_question": result.get(
                "next_question",
                ""
            ) if next_question_number <= session["total_questions"]
            else None,

            "next_topic": request.topic,

            "next_difficulty": result.get(
                "next_difficulty",
                "Intermediate"
            ),

            "is_follow_up": result.get(
                "is_follow_up",
                False
            ),

            "follow_up_reason": result.get(
                "follow_up_reason",
                ""
            ),

            "question_number": next_question_number
        }

    except Exception as e:

        print("\n========================================")
        print("ERROR IN /api/interview/answer")
        print("========================================")
        print("Error type:", type(e).__name__)
        print("Error:", str(e))
        print("========================================\n")

        return {
            "error": type(e).__name__,
            "message": str(e)
        }
