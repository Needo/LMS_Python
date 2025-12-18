# Script 10: Generate Backend Structure and Core Files
# This script generates the FastAPI backend structure

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Generating Backend Structure..." -ForegroundColor Cyan
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

Write-Host "`n1. Creating requirements.txt..." -ForegroundColor Yellow

$requirementsContent = @'
fastapi==0.115.5
uvicorn[standard]==0.32.1
sqlalchemy==2.0.36
psycopg2-binary==2.9.10
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-multipart==0.0.20
pydantic==2.10.3
pydantic-settings==2.6.1
python-dotenv==1.0.1
alembic==1.14.0
'@

Create-File -Path (Join-Path $backendPath "requirements.txt") -Content $requirementsContent

Write-Host "`n2. Creating .env.example..." -ForegroundColor Yellow

$envExampleContent = @'
# Database Configuration
DATABASE_URL=postgresql://postgres:password@localhost:5432/lms_db

# Security
SECRET_KEY=your-secret-key-here-change-this-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# Application
API_V1_PREFIX=/api
PROJECT_NAME=Learning Management System

# CORS Origins
BACKEND_CORS_ORIGINS=["http://localhost:4200"]
'@

Create-File -Path (Join-Path $backendPath ".env.example") -Content $envExampleContent

Write-Host "`n3. Creating .env (actual config)..." -ForegroundColor Yellow

$envContent = @'
# Database Configuration
DATABASE_URL=postgresql://postgres:postgres123@localhost:5432/lms_db

# Security
SECRET_KEY=my-secret-key-change-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# Application
API_V1_PREFIX=/api
PROJECT_NAME=Learning Management System

# CORS Origins
BACKEND_CORS_ORIGINS=["http://localhost:4200"]
'@

Create-File -Path (Join-Path $backendPath ".env") -Content $envContent

Write-Host "`n4. Creating config.py..." -ForegroundColor Yellow

$configContent = @'
from pydantic_settings import BaseSettings
from typing import List
import os

class Settings(BaseSettings):
    PROJECT_NAME: str = "Learning Management System"
    API_V1_PREFIX: str = "/api"
    
    DATABASE_URL: str
    
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    BACKEND_CORS_ORIGINS: List[str] = ["http://localhost:4200"]
    
    class Config:
        env_file = ".env"
        case_sensitive = True

settings = Settings()
'@

Create-File -Path (Join-Path $backendPath "app\core\config.py") -Content $configContent

Write-Host "`n5. Creating security utilities..." -ForegroundColor Yellow

$securityContent = @'
from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from passlib.context import CryptContext
from app.core.config import settings

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt

def decode_access_token(token: str) -> Optional[str]:
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        username: str = payload.get("sub")
        return username
    except JWTError:
        return None
'@

Create-File -Path (Join-Path $backendPath "app\core\security.py") -Content $securityContent

Write-Host "`n6. Creating __init__.py files..." -ForegroundColor Yellow

$initContent = ""

Create-File -Path (Join-Path $backendPath "app\__init__.py") -Content $initContent
Create-File -Path (Join-Path $backendPath "app\core\__init__.py") -Content $initContent
Create-File -Path (Join-Path $backendPath "app\api\__init__.py") -Content $initContent
Create-File -Path (Join-Path $backendPath "app\api\endpoints\__init__.py") -Content $initContent
Create-File -Path (Join-Path $backendPath "app\models\__init__.py") -Content $initContent
Create-File -Path (Join-Path $backendPath "app\schemas\__init__.py") -Content $initContent
Create-File -Path (Join-Path $backendPath "app\services\__init__.py") -Content $initContent
Create-File -Path (Join-Path $backendPath "app\db\__init__.py") -Content $initContent

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "Backend Structure Created!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "`nNext step: Run 11-generate-backend-database.ps1" -ForegroundColor Yellow
