import uuid
from dataclasses import dataclass
from typing import List

from langchain_text_splitters import RecursiveCharacterTextSplitter

from app.core.config import get_settings
from app.core.logging import setup_logger
from app.services.document_loader import PageContent

logger = setup_logger(__name__)
settings = get_settings()


@dataclass
class Chunk:
    chunk_id: str
    text: str
    source: str
    page_number: int
    chunk_index: int  # position within document


def chunk_pages(pages: List[PageContent]) -> List[Chunk]:
    """
    Entry point.
    Takes list of PageContent → returns flat list of Chunks.
    Each chunk carries full metadata for citation and filtering.
    """
    if not pages:
        raise ValueError("No pages provided to chunker.")

    splitter = RecursiveCharacterTextSplitter(
        chunk_size=settings.CHUNK_SIZE,
        chunk_overlap=settings.CHUNK_OVERLAP,
        separators=["\n\n", "\n", ". ", " ", ""],
        length_function=len,
    )

    all_chunks: List[Chunk] = []
    chunk_index = 0

    for page in pages:
        if not page.text.strip():
            continue

        splits = splitter.split_text(page.text)
        logger.debug(
            f"Page {page.page_number} of '{page.source}' → {len(splits)} chunks"
        )

        for split_text in splits:
            clean = split_text.strip()
            if not clean:
                continue

            all_chunks.append(
                Chunk(
                    chunk_id=f"chunk_{uuid.uuid4().hex[:12]}",
                    text=clean,
                    source=page.source,
                    page_number=page.page_number,
                    chunk_index=chunk_index,
                )
            )
            chunk_index += 1

    logger.info(
        f"Chunking complete: {len(all_chunks)} chunks from "
        f"{len(pages)} pages of '{pages[0].source}'"
    )

    return all_chunks