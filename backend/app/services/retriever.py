from dataclasses import dataclass
from typing import List, Optional

from app.core.config import get_settings
from app.core.logging import setup_logger
from app.services.vector_store import get_collection

logger = setup_logger(__name__)
settings = get_settings()


@dataclass
class RetrievedChunk:
    chunk_id: str
    text: str
    source: str
    page_number: int
    chunk_index: int
    score: float  # cosine similarity — higher = more relevant


def retrieve(
    question_vector: List[float],
    top_k: Optional[int] = None,
    document_filter: Optional[str] = None,
) -> List[RetrievedChunk]:
    """
    Query Chroma for top-k most similar chunks.
    Optionally filter by source document filename.
    Returns RetrievedChunk list sorted by relevance score descending.
    """
    k = top_k or settings.TOP_K
    collection = get_collection()

    total_chunks = collection.count()
    if total_chunks == 0:
        logger.warning("Vector store is empty. No chunks to retrieve.")
        return []

    # Clamp k to available chunks — Chroma errors if k > count
    k = min(k, total_chunks)

    # Build optional metadata filter
    where_filter = {"source": document_filter} if document_filter else None

    logger.debug(
        f"Querying Chroma: top_k={k} | filter={document_filter} | "
        f"total_indexed={total_chunks}"
    )

    results = collection.query(
        query_embeddings=[question_vector],
        n_results=k,
        where=where_filter,
        include=["documents", "metadatas", "distances"],
    )

    chunks = _parse_results(results)

    logger.info(
        f"Retrieved {len(chunks)} chunks. "
        f"Top score: {chunks[0].score:.4f}" if chunks else "Retrieved 0 chunks."
    )

    return chunks


def _parse_results(results: dict) -> List[RetrievedChunk]:
    """
    Parse raw Chroma query results into clean RetrievedChunk objects.
    Converts Chroma distance → similarity score (1 - distance).
    """
    chunks = []

    ids = results.get("ids", [[]])[0]
    documents = results.get("documents", [[]])[0]
    metadatas = results.get("metadatas", [[]])[0]
    distances = results.get("distances", [[]])[0]

    for chunk_id, text, meta, distance in zip(ids, documents, metadatas, distances):
        # Chroma cosine distance: 0 = identical, 2 = opposite
        # Convert to similarity: 1 = identical, -1 = opposite
        score = round(1 - distance, 4)

        chunks.append(
            RetrievedChunk(
                chunk_id=chunk_id,
                text=text,
                source=meta.get("source", "unknown"),
                page_number=meta.get("page_number", 0),
                chunk_index=meta.get("chunk_index", 0),
                score=score,
            )
        )

    # Sort by score descending — Chroma usually returns sorted but enforce it
    chunks.sort(key=lambda c: c.score, reverse=True)
    return chunks


def retrieve_with_mmr(
    question_vector: List[float],
    top_k: Optional[int] = None,
    document_filter: Optional[str] = None,
    fetch_k_multiplier: int = 3,
    diversity_weight: float = 0.3,
) -> List[RetrievedChunk]:
    """
    Maximal Marginal Relevance retrieval.
    Fetches fetch_k_multiplier * top_k candidates first,
    then re-selects for balance of relevance + diversity.

    diversity_weight: 0.0 = pure relevance, 1.0 = pure diversity.
    Start with 0.3 and tune.
    """
    k = top_k or settings.TOP_K
    fetch_k = min(k * fetch_k_multiplier, get_collection().count())

    if fetch_k == 0:
        return []

    candidates = retrieve(question_vector, top_k=fetch_k, document_filter=document_filter)

    if len(candidates) <= k:
        return candidates

    selected: List[RetrievedChunk] = []
    remaining = list(candidates)

    # Greedily pick chunks that are relevant but not redundant
    while len(selected) < k and remaining:
        if not selected:
            # First pick: highest relevance score
            best = remaining.pop(0)
            selected.append(best)
            continue

        best_chunk = None
        best_mmr_score = float("-inf")

        for candidate in remaining:
            relevance = candidate.score

            # Redundancy = max overlap with already selected chunks
            redundancy = max(
                _text_overlap(candidate.text, s.text) for s in selected
            )

            mmr_score = (1 - diversity_weight) * relevance - diversity_weight * redundancy

            if mmr_score > best_mmr_score:
                best_mmr_score = mmr_score
                best_chunk = candidate

        if best_chunk:
            selected.append(best_chunk)
            remaining.remove(best_chunk)

    logger.debug(f"MMR selected {len(selected)} chunks from {len(candidates)} candidates.")
    return selected


def _text_overlap(text_a: str, text_b: str) -> float:
    """
    Simple word-level Jaccard overlap between two texts.
    Returns 0.0 (no overlap) to 1.0 (identical).
    Used by MMR for redundancy penalty.
    """
    words_a = set(text_a.lower().split())
    words_b = set(text_b.lower().split())

    if not words_a or not words_b:
        return 0.0

    intersection = words_a & words_b
    union = words_a | words_b
    return len(intersection) / len(union)