# Script 17: Generate Backend Main Application
# This script generates the main FastAPI application file

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Generating Main Application..." -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

$rootPath = "C:\Users\munawar\Documents\Python_LMS_V2"
$backendPath = Join-Path $rootPath "backend"

# Function to create file with content
function Create-File {
    param (
        [string]$Path,
        [string]$Content
    )
    $directory = Split-Path $Path -Parent
    if (-not (Test-Path $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    Set-Content -Path $Path -Value $Content -Encoding UTF8
    Write-Host "Created: $Path" -ForegroundColor Green
}

Write-Host "`n1. Creating API Router..." -ForegroundColor Yellow

$apiRouterContent = @'
from fastapi import APIRouter
from app.api.endpoints import auth, categories, courses, files, progress, scanner

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["authentication"])
api_router.include_router(categories.router, prefix="/categories", tags=["categories"])
api_router.include_router(courses.router, prefix="/courses", tags=["courses"])
api_router.include_router(files.router, prefix="/files", tags=["files"])
api_router.include_router(progress.router, prefix="/progress", tags=["progress"])
api_router.include_router(scanner.router, prefix="/scanner", tags=["scanner"])
'@

Create-File -Path (Join-Path $backendPath "app\api\api.py") -Content $apiRouterContent

Write-Host "`n2. Creating Main Application..." -ForegroundColor Yellow

$mainContent = @'
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.api.api import api_router
from app.db.database import engine, Base

# Create database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_PREFIX}/openapi.json"
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
'@

Create-File -Path (Join-Path $backendPath "app\main.py") -Content $mainContent

Write-Host "`n3. Creating init_db script..." -ForegroundColor Yellow

$initDbContent = @'
from sqlalchemy.orm import Session
from app.db.database import SessionLocal, engine, Base
from app.models import User
from app.core.security import get_password_hash

def init_db():
    """
    Initialize database with default admin user.
    """
    # Create all tables
    Base.metadata.create_all(bind=engine)
    
    db = SessionLocal()
    
    try:
        # Check if admin user exists
        admin = db.query(User).filter(User.username == "admin").first()
        
        if not admin:
            # Create default admin user
            admin = User(
                username="admin",
                email="admin@lms.com",
                hashed_password=get_password_hash("admin123"),
                is_admin=True
            )
            db.add(admin)
            db.commit()
            print("✓ Default admin user created (username: admin, password: admin123)")
        else:
            print("✓ Admin user already exists")
        
        print("✓ Database initialized successfully")
        
    except Exception as e:
        print(f"✗ Error initializing database: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    print("Initializing database...")
    init_db()
'@

Create-File -Path (Join-Path $backendPath "app\init_db.py") -Content $initDbContent

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "Main Application Created!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "`nNext step: Run 18-setup-database.ps1" -ForegroundColor Yellow
