from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import List, Optional
from app.db.database import get_db
from app.core.dependencies import get_current_user
from app.core.config import settings
from app.models.user import User

router = APIRouter()

# Response schemas
class ConfigResponse(BaseModel):
    max_file_size: int
    allowed_extensions: List[str]
    scan_depth: int
    environment: str

class RootPathValidationRequest(BaseModel):
    path: str

class RootPathValidationResponse(BaseModel):
    valid: bool
    exists: bool
    readable: bool
    canonical: bool
    path: Optional[str]
    error: Optional[str]

# Dependency for admin-only routes
def get_current_active_admin(
    current_user: User = Depends(get_current_user)
) -> User:
    if not current_user.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions"
        )
    return current_user

@router.get("/public", response_model=ConfigResponse)
def get_public_config():
    """
    Get public configuration settings
    Available to all authenticated users
    """
    return ConfigResponse(
        max_file_size=settings.MAX_FILE_SIZE,
        allowed_extensions=settings.get_allowed_extensions_list(),
        scan_depth=settings.SCAN_DEPTH,
        environment=settings.ENV
    )

@router.post("/validate-root-path", response_model=RootPathValidationResponse)
def validate_root_path(
    request: RootPathValidationRequest,
    current_user: User = Depends(get_current_active_admin)
):
    """
    Validate root folder path
    Admin only
    """
    result = settings.validate_root_path(request.path)
    return RootPathValidationResponse(**result)
