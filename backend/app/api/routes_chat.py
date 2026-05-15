from fastapi import APIRouter, HTTPException

from app.core.logging import setup_logger
from app.core.config import get_settings
from app.schemas.chat import QueryRequest, QueryResponse, Source
from app.services.embedder import embed_query
from app.services.retriever import retrieve, retrieve_with_mmr
from app.services.reranker import rerank
from app.services.prompt_builder import build_prompt, build_no_context_prompt
from app.services.llm_service import generate_answer
from app.services.vector_store import get_collection_stats

logger = setup_logger(__name__)
settings = get_settings()

router = APIRouter()


@router.post("/query", response_model=QueryResponse)
async def query_knowledge_base(request: QueryRequest):
    logger.info(f"Query received: '{request.question[:80]}'")

    # ── Guard: check index not empty ─────────────────────────────────
    try:
        stats = get_collection_stats()
        if stats["total_chunks"] == 0:
            logger.warning("Query received but vector store is empty.")
            raise HTTPException(
                status_code=422,
                detail="No documents indexed yet. Please upload a document first.",
            )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to check collection stats: {e}")
        raise HTTPException(status_code=500, detail=f"Vector store error: {e}")

    top_k = request.top_k or settings.TOP_K

    # ── Stage 1: Embed question ───────────────────────────────────────
    try:
        question_vector = embed_query(request.question)
    except Exception as e:
        logger.error(f"Query embedding failed: {e}")
        raise HTTPException(status_code=500, detail=f"Embedding failed: {e}")

    # ── Stage 2: Retrieve top-k chunks ────────────────────────────────
    try:
        # Use MMR for diversity, fallback to similarity if needed
        retrieved_chunks = retrieve_with_mmr(
            question_vector=question_vector,
            top_k=top_k,
            document_filter=request.document_filter,
        )

        if not retrieved_chunks:
            logger.warning("Retrieval returned 0 chunks.")
            retrieved_chunks = retrieve(
                question_vector=question_vector,
                top_k=top_k,
                document_filter=request.document_filter,
            )
    except Exception as e:
        logger.error(f"Retrieval failed: {e}")
        raise HTTPException(status_code=500, detail=f"Retrieval failed: {e}")

    # ── Stage 3: Rerank chunks ────────────────────────────────────────
    try:
        if retrieved_chunks:
            reranked_chunks = rerank(
                question=request.question,
                chunks=retrieved_chunks,
                top_n=settings.RERANKER_TOP_N,
            )
        else:
            reranked_chunks = []
    except Exception as e:
        # Reranker failure is non-fatal — fall back to retrieved order
        logger.warning(f"Reranking failed, using retrieval order: {e}")
        reranked_chunks = retrieved_chunks[:settings.RERANKER_TOP_N]

    # ── Stage 4: Build prompt ─────────────────────────────────────────
    try:
        if reranked_chunks:
            messages = build_prompt(
                question=request.question,
                chunks=reranked_chunks,
            )
        else:
            logger.warning("No chunks after reranking. Using no-context prompt.")
            messages = build_no_context_prompt(request.question)
    except Exception as e:
        logger.error(f"Prompt building failed: {e}")
        raise HTTPException(status_code=500, detail=f"Prompt build failed: {e}")

    # ── Stage 5: Generate answer ──────────────────────────────────────
    try:
        answer = generate_answer(messages)
    except Exception as e:
        logger.error(f"LLM generation failed: {e}")
        raise HTTPException(status_code=500, detail=f"LLM call failed: {e}")

    # ── Stage 6: Build sources list ───────────────────────────────────
    sources = [
        Source(
            document=chunk.source,
            page=chunk.page_number,
            chunk_id=chunk.chunk_id,
        )
        for chunk in reranked_chunks
    ]

    logger.info(
        f"Query complete: "
        f"retrieved={len(retrieved_chunks)} | "
        f"reranked={len(reranked_chunks)} | "
        f"sources={[s.document for s in sources]}"
    )

    return QueryResponse(
        answer=answer,
        sources=sources,
        retrieved_chunks=len(retrieved_chunks),
    )