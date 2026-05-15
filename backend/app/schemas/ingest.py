from pydantic import BaseModel


class IngestResponse(BaseModel):
    message: str
    filename: str
    chunks_created: int
    document_id: str