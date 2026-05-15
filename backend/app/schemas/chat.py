from pydantic import BaseModel, Field
from typing import List, Optional


class Source(BaseModel):
    document: str
    page: Optional[int] = None
    chunk_id: str


class QueryRequest(BaseModel):
    question: str = Field(..., min_length=3, max_length=1000)
    document_filter: Optional[str] = None
    top_k: Optional[int] = Field(default=5, ge=1, le=20)


class QueryResponse(BaseModel):
    answer: str
    sources: List[Source]
    retrieved_chunks: int