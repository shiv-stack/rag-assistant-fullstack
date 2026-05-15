import chromadb
from chromadb.config import Settings as ChromaSettings
from functools import lru_cache
from typing import List

from app.core.config import get_settings
from app.core.logging import setup_logger
from app.services.chunker import Chunk

logger = setup_logger(__name__)
settings = get_settings()


@lru_cache()
def get_chroma_client() -> chromadb.ClientAPI:
    """
    Create persistent Chroma client once.
    Data survives server restarts — stored at CHROMA_PERSIST_DIR.
    """
    logger.info(f"Initializing Chroma client at: {settings.CHROMA_PERSIST_DIR}")
    client = chromadb.PersistentClient(
        path=settings.CHROMA_PERSIST_DIR,
        settings=ChromaSettings(anonymized_telemetry=False),
    )
    logger.info("Chroma client ready.")
    return client


def get_collection() -> chromadb.Collection:
    """
    Get or create the main collection.
    Called fresh each time — collection object is lightweight.
    """
    client = get_chroma_client()
    collection = client.get_or_create_collection(
        name=settings.CHROMA_COLLECTION_NAME,
        metadata={"hnsw:space": "cosine"},  # cosine similarity
    )
    return collection


def store_chunks(chunks: List[Chunk], vectors: List[List[float]]) -> None:
    """
    Persist chunks + their vectors into Chroma.
    Each chunk stored with full metadata for filtering + citation.
    """
    if not chunks:
        raise ValueError("No chunks to store.")
    if len(chunks) != len(vectors):
        raise ValueError(
            f"Chunk count ({len(chunks)}) != vector count ({len(vectors)})"
        )

    collection = get_collection()

    ids = [chunk.chunk_id for chunk in chunks]
    documents = [chunk.text for chunk in chunks]
    metadatas = [
        {
            "source": chunk.source,
            "page_number": chunk.page_number,
            "chunk_index": chunk.chunk_index,
        }
        for chunk in chunks
    ]

    # Chroma upsert — safe to re-ingest same document
    collection.upsert(
        ids=ids,
        embeddings=vectors,
        documents=documents,
        metadatas=metadatas,
    )

    logger.info(
        f"Stored {len(chunks)} chunks into collection "
        f"'{settings.CHROMA_COLLECTION_NAME}'"
    )


def list_documents() -> List[str]:
    """
    Return unique source filenames currently indexed.
    """
    collection = get_collection()
    results = collection.get(include=["metadatas"])

    if not results["metadatas"]:
        return []

    sources = list(
        {meta["source"] for meta in results["metadatas"] if "source" in meta}
    )
    logger.debug(f"Indexed documents: {sources}")
    return sorted(sources)


def delete_document(filename: str) -> int:
    """
    Remove all chunks belonging to a document.
    Returns count of deleted chunks.
    """
    collection = get_collection()

    results = collection.get(
        where={"source": filename},
        include=["metadatas"],
    )

    chunk_ids = results["ids"]

    if not chunk_ids:
        logger.warning(f"No chunks found for document: {filename}")
        return 0

    collection.delete(ids=chunk_ids)
    logger.info(f"Deleted {len(chunk_ids)} chunks for document: {filename}")
    return len(chunk_ids)


def get_collection_stats() -> dict:
    """
    Return basic stats about current collection.
    Useful for /health or /documents endpoints.
    """
    collection = get_collection()
    count = collection.count()
    documents = list_documents()

    return {
        "total_chunks": count,
        "total_documents": len(documents),
        "documents": documents,
    }