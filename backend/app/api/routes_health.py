from fastapi import APIRouter
from app.core.logging import setup_logger
from app.core.config import get_settings

logger = setup_logger(__name__)
settings = get_settings()

router = APIRouter()


@router.get("/health")
def health_check():
    logger.info("Health check called")
    return {
        "status": "ok",
        "app": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "debug": settings.DEBUG,
    }