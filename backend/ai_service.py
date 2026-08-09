import os
from dotenv import load_dotenv
from groq import Groq

# Load environment variables
load_dotenv()

# Get Groq API key
GROQ_API_KEY = os.getenv("GROQ_API_KEY")

if not GROQ_API_KEY:
    raise ValueError("GROQ_API_KEY not found in .env")

# Create Groq client
client = Groq(
    api_key=GROQ_API_KEY
)


def generate_ai_response(prompt):
    response = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[
            {
                "role": "user",
                "content": prompt
            }
        ],
        max_completion_tokens=2000,
        temperature=0.2
    )

    if not response.choices:
        raise ValueError("AI returned no choices")

    text = response.choices[0].message.content

    if not text:
        raise ValueError("AI returned an empty response")

    return text.strip()