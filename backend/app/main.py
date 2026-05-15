from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from app.core.config import get_settings
from app.core.logging import setup_logger
from app.api.routes_health import router as health_router
from app.api.routes_ingest import router as ingest_router
from app.api.routes_chat import router as chat_router

settings = get_settings()
logger = setup_logger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info(f"Starting {settings.APP_NAME} v{settings.APP_VERSION}")
    logger.info(f"Debug mode: {settings.DEBUG}")
    logger.info(f"LLM model: {settings.LLM_MODEL}")
    logger.info(f"Embedding model: {settings.EMBEDDING_MODEL}")
    logger.info("All systems ready.")
    yield
    # Shutdown
    logger.info("Shutting down. Goodbye.")


app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="RAG Knowledge Assistant — FastAPI Backend",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

# CORS — allows Flutter app (any origin in dev)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # lock down in prod to Flutter app origin
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Routers
app.include_router(health_router, tags=["Health"])
app.include_router(ingest_router, tags=["Ingestion"])
app.include_router(chat_router, tags=["Chat"])