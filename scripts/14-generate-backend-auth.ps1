# Script 14: Generate Backend Auth Service and Dependencies
# This script generates authentication service and FastAPI dependencies

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Generating Auth Service..." -ForegroundColor Cyan
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

Write-Host "`n1. Creating Auth Service..." -ForegroundColor Yellow

$authServiceContent = @'
from datetime import timedelta
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from app.models import User
from app.schemas import UserCreate, UserLogin, Token
from app.core.security import verify_password, get_password_hash, create_access_token
from app.core.config import settings

class AuthService:
    def __init__(self, db: Session):
        self.db = db

    def register_user(self, user_data: UserCreate) -> User:
        """
        Register a new user.
        """
        # Check if username already exists
        existing_user = self.db.query(User).filter(
            User.username == user_data.username
        ).first()
        
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Username already registered"
            )

        # Check if email already exists
        existing_email = self.db.query(User).filter(
            User.email == user_data.email
        ).first()
        
        if existing_email:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered"
            )

        # Create new user
        hashed_password = get_password_hash(user_data.password)
        db_user = User(
            username=user_data.username,
            email=user_data.email,
            hashed_password=hashed_password,
            is_admin=False
        )
        
        self.db.add(db_user)
        self.db.commit()
        self.db.refresh(db_user)
        
        return db_user

    def authenticate_user(self, login_data: UserLogin) -> Token:
        """
        Authenticate user and return token.
        """
        user = self.db.query(User).filter(
            User.username == login_data.username
        ).first()
        
        if not user or not verify_password(login_data.password, user.hashed_password):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Incorrect username or password",
                headers={"WWW-Authenticate": "Bearer"},
            )

        access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"sub": user.username}, expires_delta=access_token_expires
        )
        
        return Token(
            access_token=access_token,
            token_type="bearer",
            user=user
        )

    def get_user_by_username(self, username: str) -> User:
        """
        Get user by username.
        """
        return self.db.query(User).filter(User.username == username).first()
'@

Create-File -Path (Join-Path $backendPath "app\services\auth_service.py") -Content $authServiceContent

Write-Host "`n2. Creating Dependencies..." -ForegroundColor Yellow

$dependenciesContent = @'
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.models import User
from app.core.security import decode_access_token

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="api/auth/login")

def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
) -> User:
    """
    Get current authenticated user.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    username = decode_access_token(token)
    if username is None:
        raise credentials_exception
    
    user = db.query(User).filter(User.username == username).first()
    if user is None:
        raise credentials_exception
    
    return user

def get_current_admin_user(
    current_user: User = Depends(get_current_user)
) -> User:
    """
    Verify that current user is an admin.
    """
    if not current_user.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough privileges"
        )
    return current_user
'@

Create-File -Path (Join-Path $backendPath "app\core\dependencies.py") -Content $dependenciesContent

Write-Host "`n3. Creating services __init__.py..." -ForegroundColor Yellow

$servicesInitContent = @'
from app.services.auth_service import AuthService
from app.services.scanner_service import ScannerService

__all__ = [
    "AuthService",
    "ScannerService"
]
'@

Create-File -Path (Join-Path $backendPath "app\services\__init__.py") -Content $servicesInitContent

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "Auth Service Created!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "`nNext step: Run 15-generate-backend-endpoints.ps1" -ForegroundColor Yellow
