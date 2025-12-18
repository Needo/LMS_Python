from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app.db.database import get_db
from app.models import Course as CourseModel, User
from app.schemas import Course
from app.core.dependencies import get_current_user

router = APIRouter()

@router.get("/", response_model=List[Course])
def get_all_courses(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get all courses.
    """
    courses = db.query(CourseModel).all()
    return courses

@router.get("/category/{category_id}", response_model=List[Course])
def get_courses_by_category(
    category_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get all courses in a specific category.
    """
    courses = db.query(CourseModel).filter(
        CourseModel.category_id == category_id
    ).all()
    return courses

@router.get("/{course_id}", response_model=Course)
def get_course(
    course_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get a specific course by ID.
    """
    course = db.query(CourseModel).filter(CourseModel.id == course_id).first()
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    return course
