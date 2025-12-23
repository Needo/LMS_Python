from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from app.core.config import settings
from app.api.api import api_router
from app.db.database import engine, Base
from app.core.background_tasks import task_manager
from app.core.logging_config import setup_logging
from app.core.correlation_middleware import CorrelationIdMiddleware
import logging

# Setup logging
setup_logging(
    log_level=settings.LOG_LEVEL,
    log_file="./logs/lms.log",
    structured=(settings.ENV == "production")
)

logger = logging.getLogger(__name__)

# Lifespan context manager for startup/shutdown
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info("Starting up LMS API...", extra={'event': 'startup'})
    Base.metadata.create_all(bind=engine)
    
    yield
    
    # Shutdown
    logger.info("Shutting down LMS API...", extra={'event': 'shutdown'})
    task_manager.shutdown(timeout=30)
    logger.info("Shutdown complete", extra={'event': 'shutdown_complete'})

app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_PREFIX}/openapi.json",
    lifespan=lifespan
)

# Set up CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.BACKEND_CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Add correlation ID middleware
app.add_middleware(CorrelationIdMiddleware)

# Include API router
app.include_router(api_router, prefix=settings.API_V1_PREFIX)

@app.get("/")
def root():
    return {
        "message": "Learning Management System API",
        "docs": "/docs",
        "openapi": f"{settings.API_V1_PREFIX}/openapi.json"
    }

@app.get("/health")
def health_check():
    return {"status": "healthy"}
