from sentence_transformers import SentenceTransformer
from functools import lru_cache
from typing import List

from app.core.config import get_settings
from app.core.logging import setup_logger

logger = setup_logger(__name__)
settings = get_settings()


@lru_cache()
def get_embedding_model() -> SentenceTransformer:
    """
    Load model once, reuse forever.
    First call downloads model (~90MB) if not cached locally.
    Subsequent calls return cached instance.
    """
    logger.info(f"Loading embedding model: {settings.EMBEDDING_MODEL}")
    model = SentenceTransformer(settings.EMBEDDING_MODEL)
    logger.info("Embedding model loaded.")
    return model


def embed_texts(texts: List[str]) -> List[List[float]]:
    """
    Convert list of strings → list of float vectors.
    Used for chunks during ingestion.
    """
    if not texts:
        raise ValueError("No texts provided for embedding.")

    model = get_embedding_model()

    logger.debug(f"Embedding {len(texts)} texts...")

    vectors = model.encode(
        texts,
        batch_size=32,
        show_progress_bar=False,
        convert_to_numpy=True,
        normalize_embeddings=True,  # cosine similarity friendly
    )

    logger.debug(f"Embedding complete. Vector shape: {vectors.shape}")

    return vectors.tolist()


def embed_query(query: str) -> List[float]:
    """
    Convert single query string → float vector.
    Used at query time for similarity search.
    """
    if not query.strip():
        raise ValueError("Query text is empty.")

    model = get_embedding_model()

    vector = model.encode(
        query,
        convert_to_numpy=True,
        normalize_embeddings=True,
    )

    return vector.tolist()