"""
Notification API endpoints
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import Optional
from pydantic import BaseModel
from app.db.database import get_db
from app.models.user import User
from app.core.dependencies import get_current_user
from app.services.notification_service import NotificationService

router = APIRouter()

class AnnouncementCreate(BaseModel):
    title: str
    content: str
    announcement_type: str = "course_announcement"
    course_id: Optional[int] = None
    file_id: Optional[int] = None
    priority: int = 0
    expires_at: Optional[str] = None

@router.get("/")
def get_notifications(
    unread_only: bool = False,
    limit: int = 50,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get user's notifications
    Filtered by course enrollment
    """
    notification_service = NotificationService(db)
    notifications = notification_service.get_user_notifications(
        current_user,
        unread_only,
        limit
    )
    
    return {'notifications': notifications}

@router.get("/unread-count")
def get_unread_count(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get count of unread notifications
    """
    notification_service = NotificationService(db)
    count = notification_service.get_unread_count(current_user)
    
    return {'unread_count': count}

@router.post("/create")
def create_announcement(
    announcement: AnnouncementCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Create new announcement
    Admin only
    """
    if not current_user.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin only"
        )
    
    notification_service = NotificationService(db)
    
    result = notification_service.create_announcement(
        title=announcement.title,
        content=announcement.content,
        announcement_type=announcement.announcement_type,
        created_by_id=current_user.id,
        course_id=announcement.course_id,
        file_id=announcement.file_id,
        priority=announcement.priority
    )
    
    return {
        'id': result.id,
        'title': result.title,
        'created_at': result.created_at.isoformat()
    }

@router.post("/{notification_id}/read")
def mark_as_read(
    notification_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Mark notification as read
    """
    notification_service = NotificationService(db)
    success = notification_service.mark_as_read(notification_id, current_user.id)
    
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notification not found"
        )
    
    return {'success': True}

@router.post("/mark-all-read")
def mark_all_read(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Mark all notifications as read
    """
    notification_service = NotificationService(db)
    count = notification_service.mark_all_as_read(current_user.id)
    
    return {
        'success': True,
        'marked_read': count
    }

@router.delete("/{notification_id}")
def delete_notification(
    notification_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Delete notification
    """
    notification_service = NotificationService(db)
    success = notification_service.delete_notification(notification_id, current_user.id)
    
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notification not found"
        )
    
    return {'success': True}
