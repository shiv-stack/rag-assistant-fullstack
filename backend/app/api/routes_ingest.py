import uuid
from fastapi import APIRouter, UploadFile, File, HTTPException
from fastapi.responses import JSONResponse

from app.core.logging import setup_logger
from app.schemas.ingest import IngestResponse
from app.services.document_loader import load_document
from app.services.chunker import chunk_pages
from app.services.embedder import embed_texts
from app.services.vector_store import store_chunks, list_documents, delete_document, get_collection_stats

logger = setup_logger(__name__)

router = APIRouter()

ALLOWED_EXTENSIONS = {".pdf", ".txt", ".md"}
MAX_FILE_SIZE_MB = 20


@router.post("/ingest", response_model=IngestResponse)
async def ingest_document(file: UploadFile = File(...)):
    logger.info(f"Ingest request received: {file.filename}")

    # ── Validate extension ────────────────────────────────────────────
    suffix = "." + file.filename.split(".")[-1].lower()
    if suffix not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported file type: {suffix}. Allowed: {ALLOWED_EXTENSIONS}",
        )

    # ── Validate file size ────────────────────────────────────────────
    contents = await file.read()
    size_mb = len(contents) / (1024 * 1024)
    if size_mb > MAX_FILE_SIZE_MB:
        raise HTTPException(
            status_code=400,
            detail=f"File too large: {size_mb:.1f}MB. Max: {MAX_FILE_SIZE_MB}MB",
        )

    logger.info(f"File validated: {file.filename} ({size_mb:.2f}MB)")

    # ── Stage 1: Load document → pages ───────────────────────────────
    try:
        pages = load_document(contents, file.filename)
    except Exception as e:
        logger.error(f"Document loading failed: {e}")
        raise HTTPException(status_code=422, detail=f"Failed to parse document: {e}")

    if not pages:
        raise HTTPException(
            status_code=422,
            detail="Document appears to be empty or image-only. No text extracted.",
        )

    # ── Stage 2: Chunk pages → chunks ────────────────────────────────
    try:
        chunks = chunk_pages(pages)
    except Exception as e:
        logger.error(f"Chunking failed: {e}")
        raise HTTPException(status_code=500, detail=f"Chunking failed: {e}")

    if not chunks:
        raise HTTPException(
            status_code=422,
            detail="No chunks produced. Document may have too little text.",
        )

    # ── Stage 3: Embed chunks → vectors ──────────────────────────────
    try:
        texts = [chunk.text for chunk in chunks]
        vectors = embed_texts(texts)
    except Exception as e:
        logger.error(f"Embedding failed: {e}")
        raise HTTPException(status_code=500, detail=f"Embedding failed: {e}")

    # ── Stage 4: Store chunks + vectors → Chroma ─────────────────────
    try:
        store_chunks(chunks, vectors)
    except Exception as e:
        logger.error(f"Vector store write failed: {e}")
        raise HTTPException(status_code=500, detail=f"Storage failed: {e}")

    document_id = str(uuid.uuid4())

    logger.info(
        f"Ingestion complete: {file.filename} | "
        f"pages={len(pages)} | chunks={len(chunks)} | doc_id={document_id}"
    )

    return IngestResponse(
        message="Document successfully ingested and indexed.",
        filename=file.filename,
        chunks_created=len(chunks),
        document_id=document_id,
    )


@router.get("/documents")
def list_indexed_documents():
    """
    Return all currently indexed document filenames.
    """
    try:
        stats = get_collection_stats()
        return {
            "documents": stats["documents"],
            "total_documents": stats["total_documents"],
            "total_chunks": stats["total_chunks"],
        }
    except Exception as e:
        logger.error(f"Failed to list documents: {e}")
        raise HTTPException(status_code=500, detail=f"Could not retrieve documents: {e}")


@router.delete("/documents/{filename}")
def delete_indexed_document(filename: str):
    """
    Remove all chunks for a given document filename.
    """
    try:
        deleted_count = delete_document(filename)
    except Exception as e:
        logger.error(f"Delete failed for {filename}: {e}")
        raise HTTPException(status_code=500, detail=f"Delete failed: {e}")

    if deleted_count == 0:
        raise HTTPException(
            status_code=404,
            detail=f"Document '{filename}' not found in index.",
        )

    logger.info(f"Document deleted: {filename} ({deleted_count} chunks removed)")

    return {
        "message": f"Document '{filename}' deleted.",
        "chunks_removed": deleted_count,
    }