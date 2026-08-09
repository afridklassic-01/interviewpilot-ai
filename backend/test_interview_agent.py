from interview_agent import evaluate_answer


question = """
Explain how Retrieval-Augmented Generation works
and how it can reduce hallucinations.
"""

answer = """
RAG first converts documents into embeddings and stores them
in a vector database. When the user asks a question, the system
retrieves relevant documents and gives them to the language model
as context. This helps the model generate an answer based on
retrieved information instead of relying only on its training data.
"""


result = evaluate_answer(
    question=question,
    answer=answer,
    topic="RAG",
    history=[]
)

print(result)