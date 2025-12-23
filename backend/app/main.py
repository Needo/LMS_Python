from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from app.core.config import settings
from app.api.api import api_router
from app.db.database import engine, Base
from app.core.background_tasks import task_manager

# Lifespan context manager for startup/shutdown
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    print("Starting up LMS API...")
    Base.metadata.create_all(bind=engine)
    
    yield
    
    # Shutdown
    print("Shutting down LMS API...")
    task_manager.shutdown(timeout=30)
    print("Shutdown complete")

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
