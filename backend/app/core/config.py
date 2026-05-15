from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    # App
    APP_NAME: str = "RAG Knowledge Assistant"
    APP_VERSION: str = "0.1.0"
    DEBUG: bool = False

    # LLM
    OPENAI_API_KEY: str = ""
    LLM_MODEL: str = "gpt-4o-mini"

    # Embeddings
    EMBEDDING_MODEL: str = "all-MiniLM-L6-v2"  # local, free

    # Vector store
    CHROMA_PERSIST_DIR: str = "./index"
    CHROMA_COLLECTION_NAME: str = "rag_documents"

    # Retrieval
    TOP_K: int = 5
    CHUNK_SIZE: int = 500
    CHUNK_OVERLAP: int = 50

    # Reranking
    RERANKER_TOP_N: int = 3

    # LLM generation
    LLM_TEMPERATURE: float = 0.2
    LLM_MAX_TOKENS: int = 1024

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


@lru_cache()
def get_settings() -> Settings:
    return Settings()