from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime
from app.db.database import get_db
from app.models import UserProgress as UserProgressModel, LastViewed as LastViewedModel, User
from app.schemas import UserProgress, UserProgressCreate, LastViewed, LastViewedCreate
from app.core.dependencies import get_current_user

router = APIRouter()

@router.get("/user/{user_id}", response_model=List[UserProgress])
def get_user_progress(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get all progress records for a user.
    """
    if current_user.id != user_id and not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Not authorized")
    
    progress = db.query(UserProgressModel).filter(
        UserProgressModel.user_id == user_id
    ).all()
    return progress

@router.get("/user/{user_id}/file/{file_id}", response_model=UserProgress)
def get_progress_for_file(
    user_id: int,
    file_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get progress for a specific file and user.
    """
    if current_user.id != user_id and not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Not authorized")
    
    progress = db.query(UserProgressModel).filter(
        UserProgressModel.user_id == user_id,
        UserProgressModel.file_id == file_id
    ).first()
    
    if not progress:
        raise HTTPException(status_code=404, detail="Progress not found")
    
    return progress

@router.post("/", response_model=UserProgress)
def update_progress(
    progress_data: UserProgressCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Create or update progress for a file.
    """
    if current_user.id != progress_data.user_id and not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Not authorized")
    
    # Check if progress already exists
    existing_progress = db.query(UserProgressModel).filter(
        UserProgressModel.user_id == progress_data.user_id,
        UserProgressModel.file_id == progress_data.file_id
    ).first()
    
    if existing_progress:
        # Update existing progress
        existing_progress.status = progress_data.status
        existing_progress.last_position = progress_data.last_position
        existing_progress.updated_at = datetime.utcnow()
        
        if progress_data.status == "completed":
            existing_progress.completed_at = datetime.utcnow()
        
        db.commit()
        db.refresh(existing_progress)
        return existing_progress
    else:
        # Create new progress
        new_progress = UserProgressModel(
            user_id=progress_data.user_id,
            file_id=progress_data.file_id,
            status=progress_data.status,
            last_position=progress_data.last_position,
            completed_at=datetime.utcnow() if progress_data.status == "completed" else None
        )
        db.add(new_progress)
        db.commit()
        db.refresh(new_progress)
        return new_progress

@router.get("/user/{user_id}/last-viewed", response_model=LastViewed)
def get_last_viewed(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get last viewed file for a user.
    """
    if current_user.id != user_id and not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Not authorized")
    
    last_viewed = db.query(LastViewedModel).filter(
        LastViewedModel.user_id == user_id
    ).first()
    
    if not last_viewed:
        raise HTTPException(status_code=404, detail="No last viewed record found")
    
    return last_viewed

@router.post("/last-viewed", response_model=LastViewed)
def set_last_viewed(
    last_viewed_data: LastViewedCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Set last viewed file for a user.
    """
    if current_user.id != last_viewed_data.user_id and not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Not authorized")
    
    # Check if record exists
    existing = db.query(LastViewedModel).filter(
        LastViewedModel.user_id == last_viewed_data.user_id
    ).first()
    
    if existing:
        # Update existing
        existing.course_id = last_viewed_data.course_id
        existing.file_id = last_viewed_data.file_id
        existing.timestamp = datetime.utcnow()
        db.commit()
        db.refresh(existing)
        return existing
    else:
        # Create new
        new_last_viewed = LastViewedModel(
            user_id=last_viewed_data.user_id,
            course_id=last_viewed_data.course_id,
            file_id=last_viewed_data.file_id
        )
        db.add(new_last_viewed)
        db.commit()
        db.refresh(new_last_viewed)
        return new_last_viewed
