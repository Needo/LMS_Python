from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.core.dependencies import get_current_user
from app.schemas import UserCreate, UserLogin, Token, User, TokenRefresh
from app.services import AuthService
from app.models.user import User as UserModel

router = APIRouter()

@router.post("/register", response_model=User, status_code=status.HTTP_201_CREATED)
def register(user_data: UserCreate, db: Session = Depends(get_db)):
    """
    Register a new user.
    """
    auth_service = AuthService(db)
    return auth_service.register_user(user_data)

@router.post("/login", response_model=Token)
def login(login_data: UserLogin, db: Session = Depends(get_db)):
    """
    Login and get access + refresh tokens.
    """
    auth_service = AuthService(db)
    return auth_service.authenticate_user(login_data)

@router.post("/refresh")
def refresh_token(token_data: TokenRefresh, db: Session = Depends(get_db)):
    """
    Refresh access token using refresh token.
    """
    auth_service = AuthService(db)
    return auth_service.refresh_access_token(token_data.refresh_token)

@router.post("/logout")
def logout(
    token_data: TokenRefresh,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Logout by revoking refresh token.
    """
    auth_service = AuthService(db)
    success = auth_service.logout(token_data.refresh_token)
    
    if success:
        return {"message": "Logged out successfully"}
    
    return {"message": "Token not found or already revoked"}

@router.post("/logout-all")
def logout_all(
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Logout from all devices by revoking all refresh tokens.
    """
    auth_service = AuthService(db)
    count = auth_service.logout_all_sessions(current_user.id)
    
    return {"message": f"Logged out from {count} session(s)"}
