"""
Enrollment management endpoints
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app.db.database import get_db
from app.models.user import User
from app.models.enrollment import Enrollment
from app.schemas.enrollment import EnrollmentCreate, EnrollmentResponse
from app.core.dependencies import get_current_user
from app.core.authorization import get_auth_service
from app.services.authorization_service import AuthorizationService

router = APIRouter()

@router.post("/", response_model=EnrollmentResponse)
def create_enrollment(
    enrollment_data: EnrollmentCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
    auth_service: AuthorizationService = Depends(get_auth_service)
):
    """
    Enroll a user in a course.
    Admin only.
    """
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Admin only")
    
    try:
        enrollment = auth_service.enroll_user(
            user_id=enrollment_data.user_id,
            course_id=enrollment_data.course_id,
            role=enrollment_data.role or "student"
        )
        return enrollment
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.delete("/{user_id}/{course_id}")
def delete_enrollment(
    user_id: int,
    course_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
    auth_service: AuthorizationService = Depends(get_auth_service)
):
    """
    Unenroll a user from a course.
    Admin only.
    """
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Admin only")
    
    success = auth_service.unenroll_user(user_id, course_id)
    if not success:
        raise HTTPException(status_code=404, detail="Enrollment not found")
    
    return {"message": "Enrollment removed successfully"}

@router.get("/user/{user_id}", response_model=List[EnrollmentResponse])
def get_user_enrollments(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get all enrollments for a user.
    Admin or the user themselves.
    """
    if not current_user.is_admin and current_user.id != user_id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    enrollments = db.query(Enrollment).filter(
        Enrollment.user_id == user_id
    ).all()
    
    return enrollments

@router.get("/course/{course_id}", response_model=List[EnrollmentResponse])
def get_course_enrollments(
    course_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get all enrollments for a course.
    Admin only.
    """
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Admin only")
    
    enrollments = db.query(Enrollment).filter(
        Enrollment.course_id == course_id
    ).all()
    
    return enrollments
