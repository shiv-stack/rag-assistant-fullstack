import fitz  # pymupdf
from dataclasses import dataclass
from typing import List
from app.core.logging import setup_logger

logger = setup_logger(__name__)


@dataclass
class PageContent:
    text: str
    page_number: int
    source: str


def load_document(contents: bytes, filename: str) -> List[PageContent]:
    """
    Entry point. Routes to correct loader based on file extension.
    Returns list of PageContent — one per page or logical block.
    """
    suffix = "." + filename.split(".")[-1].lower()

    logger.info(f"Loading document: {filename} (type={suffix})")

    if suffix == ".pdf":
        return _load_pdf(contents, filename)
    elif suffix in {".txt", ".md"}:
        return _load_text(contents, filename)
    else:
        raise ValueError(f"Unsupported file type: {suffix}")


def _load_pdf(contents: bytes, filename: str) -> List[PageContent]:
    """
    Extract text page by page using pymupdf.
    Preserves page numbers for citation.
    """
    pages = []

    try:
        doc = fitz.open(stream=contents, filetype="pdf")
        total_pages = len(doc)
        logger.debug(f"PDF opened: {total_pages} pages")

        for page_num in range(total_pages):
            page = doc[page_num]
            text = page.get_text("text").strip()

            if not text:
                logger.debug(f"Page {page_num + 1} is empty or image-only. Skipping.")
                continue

            pages.append(
                PageContent(
                    text=text,
                    page_number=page_num + 1,  # human-readable: starts at 1
                    source=filename,
                )
            )

        doc.close()
        logger.info(f"PDF loaded: {len(pages)} non-empty pages extracted from {filename}")

    except Exception as e:
        logger.error(f"Failed to parse PDF {filename}: {e}")
        raise RuntimeError(f"PDF parsing failed: {e}")

    return pages


def _load_text(contents: bytes, filename: str) -> List[PageContent]:
    """
    Load plain text or markdown as single page block.
    No page numbers — set to 1 by default.
    """
    try:
        text = contents.decode("utf-8").strip()
    except UnicodeDecodeError:
        text = contents.decode("latin-1").strip()

    if not text:
        raise ValueError(f"File {filename} is empty.")

    logger.info(f"Text file loaded: {len(text)} characters from {filename}")

    return [
        PageContent(
            text=text,
            page_number=1,
            source=filename,
        )
    ]