from sentence_transformers import CrossEncoder
from functools import lru_cache
from typing import List

from app.core.config import get_settings
from app.core.logging import setup_logger
from app.services.retriever import RetrievedChunk

logger = setup_logger(__name__)
settings = get_settings()

RERANKER_MODEL = "cross-encoder/ms-marco-MiniLM-L-6-v2"


@lru_cache()
def get_reranker_model() -> CrossEncoder:
    """
    Load cross-encoder once, reuse forever.
    First call downloads ~80MB model.
    """
    logger.info(f"Loading reranker model: {RERANKER_MODEL}")
    model = CrossEncoder(RERANKER_MODEL, max_length=512)
    logger.info("Reranker model loaded.")
    return model


def rerank(
    question: str,
    chunks: List[RetrievedChunk],
    top_n: int = 3,
) -> List[RetrievedChunk]:
    """
    Rerank retrieved chunks using cross-encoder.
    
    Why cross-encoder beats bi-encoder for reranking:
    - Bi-encoder (embedder): encodes question + chunk separately → fast but approximate
    - Cross-encoder: sees question + chunk together → slower but much more accurate
    
    Strategy: retrieve top-10 with bi-encoder, rerank to top-3 with cross-encoder.
    Best of both worlds: speed + accuracy.
    
    Returns top_n chunks sorted by reranker score descending.
    """
    if not chunks:
        logger.warning("Reranker received empty chunk list. Returning empty.")
        return []

    if len(chunks) == 1:
        logger.debug("Only 1 chunk. Skipping reranking.")
        return chunks

    model = get_reranker_model()

    # Cross-encoder needs [question, chunk_text] pairs
    pairs = [[question, chunk.text] for chunk in chunks]

    logger.debug(f"Reranking {len(chunks)} chunks for question: '{question[:60]}'")

    scores = model.predict(pairs)

    # Attach reranker scores to chunks
    scored_chunks = list(zip(chunks, scores))
    scored_chunks.sort(key=lambda x: x[1], reverse=True)

    # Take top_n
    top_chunks = [chunk for chunk, score in scored_chunks[:top_n]]
    top_scores = [round(float(score), 4) for _, score in scored_chunks[:top_n]]

    logger.info(
        f"Reranking complete: {len(chunks)} → {len(top_chunks)} chunks. "
        f"Top scores: {top_scores}"
    )

    return top_chunks