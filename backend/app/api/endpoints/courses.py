from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app.db.database import get_db
from app.models import Course as CourseModel, User
from app.schemas import Course
from app.core.dependencies import get_current_user
from app.core.authorization import get_auth_service
from app.services.authorization_service import AuthorizationService

router = APIRouter()

@router.get("/", response_model=List[Course])
def get_all_courses(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
    auth_service: AuthorizationService = Depends(get_auth_service)
):
    """
    Get accessible courses for current user.
    Admin sees all, regular users see only enrolled courses.
    """
    courses = auth_service.get_accessible_courses(current_user)
    return courses

@router.get("/category/{category_id}", response_model=List[Course])
def get_courses_by_category(
    category_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
    auth_service: AuthorizationService = Depends(get_auth_service)
):
    """
    Get accessible courses in a specific category.
    Admin sees all, regular users see only enrolled courses.
    """
    courses = auth_service.get_accessible_courses(current_user, category_id)
    return courses

@router.get("/{course_id}", response_model=Course)
def get_course(
    course_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
    auth_service: AuthorizationService = Depends(get_auth_service)
):
    """
    Get a specific course by ID.
    Requires access to the course.
    """
    # Check access
    if not auth_service.can_access_course(current_user, course_id):
        raise HTTPException(status_code=403, detail="Access denied to this course")
    
    course = db.query(CourseModel).filter(CourseModel.id == course_id).first()
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    return course
