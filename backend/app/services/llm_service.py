from openai import OpenAI
from functools import lru_cache
from typing import List

from app.core.config import get_settings
from app.core.logging import setup_logger

logger = setup_logger(__name__)
settings = get_settings()


@lru_cache()
def get_openai_client() -> OpenAI:
    if not settings.OPENAI_API_KEY:
        raise RuntimeError(
            "OPENAI_API_KEY is not set. Add Groq key to .env file."
        )

    logger.info("Initializing Groq client.")
    client = OpenAI(
        api_key=settings.OPENAI_API_KEY,
        base_url="https://api.groq.com/openai/v1",  # ← only change
    )
    logger.info(f"Groq client ready. Model: {settings.LLM_MODEL}")
    return client


def generate_answer(messages: List[dict]) -> str:
    """
    Send messages to OpenAI chat completion.
    Returns clean answer string.

    messages format (from prompt_builder.py):
    [
        {"role": "system", "content": "..."},
        {"role": "user",   "content": "..."},
    ]
    """
    if not messages:
        raise ValueError("Messages list is empty. Cannot call LLM.")

    client = get_openai_client()

    logger.debug(
        f"Calling LLM: model={settings.LLM_MODEL} | "
        f"messages={len(messages)} | "
        f"max_tokens=1024"
    )

    try:
        response = client.chat.completions.create(
            model=settings.LLM_MODEL,
            messages=messages,
            temperature=0.2,      # low = factual, consistent answers
            max_tokens=1024,
            top_p=0.9,
            frequency_penalty=0.1, # mild penalty for repetition
        )
    except Exception as e:
        logger.error(f"OpenAI API call failed: {e}")
        raise RuntimeError(f"LLM generation failed: {e}")

    answer = response.choices[0].message.content.strip()

    logger.info(
        f"LLM response received: "
        f"{response.usage.prompt_tokens} prompt tokens | "
        f"{response.usage.completion_tokens} completion tokens | "
        f"{response.usage.total_tokens} total"
    )
    logger.debug(f"Answer preview: '{answer[:120]}'")

    return answer


def generate_answer_streaming(messages: List[dict]):
    """
    Streaming version — yields answer chunks as they arrive.
    Not wired in Phase 3 but ready for Phase 4 Flutter streaming.

    Usage:
        for chunk in generate_answer_streaming(messages):
            print(chunk, end="", flush=True)
    """
    if not messages:
        raise ValueError("Messages list is empty.")

    client = get_openai_client()

    logger.debug(f"Streaming LLM call: model={settings.LLM_MODEL}")

    try:
        stream = client.chat.completions.create(
            model=settings.LLM_MODEL,
            messages=messages,
            temperature=0.2,
            max_tokens=1024,
            top_p=0.9,
            stream=True,
        )

        for chunk in stream:
            delta = chunk.choices[0].delta
            if delta and delta.content:
                yield delta.content

    except Exception as e:
        logger.error(f"Streaming LLM call failed: {e}")
        raise RuntimeError(f"LLM streaming failed: {e}")