from typing import List

from app.core.logging import setup_logger
from app.services.retriever import RetrievedChunk

logger = setup_logger(__name__)

SYSTEM_PROMPT = """You are a precise knowledge assistant. Your job is to answer questions strictly based on the provided context chunks.

Rules you must follow:
- Answer ONLY from the provided context. Never use outside knowledge.
- If the answer is not in the context, say exactly: "I could not find an answer in the provided documents."
- Always cite your sources using [Source: filename, Page: N] format inline.
- Be concise and direct. Avoid filler phrases.
- If multiple chunks support the answer, synthesize them into one clear response.
- Never hallucinate or guess."""


def build_prompt(
    question: str,
    chunks: List[RetrievedChunk],
) -> List[dict]:
    """
    Build OpenAI-compatible messages list from question + retrieved chunks.

    Returns list of message dicts:
    [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user",   "content": context_block + question},
    ]

    Why messages format vs single string:
    - OpenAI chat API expects messages list.
    - System prompt stays separate — easier to tune independently.
    - User message contains context + question together so LLM
      sees both in same attention window.
    """
    if not chunks:
        logger.warning("No chunks provided to prompt builder.")
        context_block = "No context available."
    else:
        context_block = _build_context_block(chunks)

    user_message = f"""Use the following context to answer the question.

{context_block}

Question: {question}

Answer:"""

    logger.debug(
        f"Prompt built: {len(chunks)} chunks | "
        f"context_chars={len(context_block)} | "
        f"question='{question[:60]}'"
    )

    return [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": user_message},
    ]


def _build_context_block(chunks: List[RetrievedChunk]) -> str:
    """
    Format chunks into numbered context block.
    Each chunk labeled with source + page for inline citation.

    Output format:
    --- Context 1 [Source: resume.pdf, Page: 2] ---
    Led backend development for...

    --- Context 2 [Source: resume.pdf, Page: 3] ---
    Designed REST APIs using...
    """
    lines = []

    for i, chunk in enumerate(chunks, start=1):
        header = f"--- Context {i} [Source: {chunk.source}, Page: {chunk.page_number}] ---"
        lines.append(header)
        lines.append(chunk.text.strip())
        lines.append("")  # blank line between chunks

    return "\n".join(lines)


def build_no_context_prompt(question: str) -> List[dict]:
    """
    Fallback prompt when vector store is empty.
    LLM instructed to say no documents indexed yet.
    Used by routes_chat.py when retriever returns empty list.
    """
    user_message = f"""No documents have been indexed yet.

Question: {question}

Answer:"""

    return [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": user_message},
    ]