"""
Authorization dependencies for FastAPI
"""
from fastapi import Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.core.auth import get_current_user
from app.models.user import User
from app.services.authorization_service import AuthorizationService

def get_auth_service(db: Session = Depends(get_db)) -> AuthorizationService:
    """Get authorization service instance"""
    return AuthorizationService(db)

def require_course_access(
    course_id: int,
    current_user: User = Depends(get_current_user),
    auth_service: AuthorizationService = Depends(get_auth_service)
):
    """
    Dependency to require course access
    
    Raises:
        HTTPException 403 if user doesn't have access
    """
    if not auth_service.can_access_course(current_user, course_id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have access to this course"
        )

def require_file_access(
    file_id: int,
    current_user: User = Depends(get_current_user),
    auth_service: AuthorizationService = Depends(get_auth_service)
):
    """
    Dependency to require file access
    
    Raises:
        HTTPException 403 if user doesn't have access
    """
    if not auth_service.can_access_file(current_user, file_id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have access to this file"
        )
