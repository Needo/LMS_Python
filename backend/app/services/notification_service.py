"""
Notification service for announcements and updates
"""
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_
from app.models.user import User
from app.models.search import Announcement, UserNotification, AnnouncementType
from app.services.authorization_service import AuthorizationService
from typing import List, Dict, Any, Optional
from datetime import datetime

class NotificationService:
    """Manage announcements and user notifications"""
    
    def __init__(self, db: Session):
        self.db = db
        self.auth_service = AuthorizationService(db)
    
    def create_announcement(
        self,
        title: str,
        content: str,
        announcement_type: str,
        created_by_id: int,
        course_id: Optional[int] = None,
        file_id: Optional[int] = None,
        priority: int = 0,
        expires_at: Optional[datetime] = None
    ) -> Announcement:
        """
        Create a new announcement
        Admin only
        """
        announcement = Announcement(
            title=title,
            content=content,
            announcement_type=announcement_type,
            course_id=course_id,
            file_id=file_id,
            created_by_id=created_by_id,
            priority=priority,
            expires_at=expires_at
        )
        
        self.db.add(announcement)
        self.db.commit()
        self.db.refresh(announcement)
        
        # Create notifications for relevant users
        self._create_user_notifications(announcement)
        
        return announcement
    
    def get_user_notifications(
        self,
        user: User,
        unread_only: bool = False,
        limit: int = 50
    ) -> List[Dict[str, Any]]:
        """
        Get notifications for a user
        Filtered by course enrollment
        """
        # Get user's enrolled courses
        accessible_course_ids = self.auth_service.get_enrolled_course_ids(user)
        
        # Build query
        query = self.db.query(
            UserNotification, Announcement
        ).join(
            Announcement,
            UserNotification.announcement_id == Announcement.id
        ).filter(
            UserNotification.user_id == user.id
        )
        
        # Filter for announcements user can see
        query = query.filter(
            or_(
                # System announcements (no course)
                Announcement.course_id.is_(None),
                # Course announcements user is enrolled in
                Announcement.course_id.in_(accessible_course_ids) if accessible_course_ids else False
            )
        )
        
        # Filter unread only
        if unread_only:
            query = query.filter(UserNotification.is_read == False)
        
        # Filter expired
        query = query.filter(
            or_(
                Announcement.expires_at.is_(None),
                Announcement.expires_at > datetime.utcnow()
            )
        )
        
        # Order by priority and time
        query = query.order_by(
            Announcement.priority.desc(),
            Announcement.created_at.desc()
        ).limit(limit)
        
        results = query.all()
        
        return [
            {
                'id': notif.id,
                'announcement_id': announcement.id,
                'title': announcement.title,
                'content': announcement.content,
                'type': announcement.announcement_type,
                'course_id': announcement.course_id,
                'file_id': announcement.file_id,
                'priority': announcement.priority,
                'is_read': notif.is_read,
                'created_at': announcement.created_at.isoformat(),
                'read_at': notif.read_at.isoformat() if notif.read_at else None,
                'icon': self._get_notification_icon(announcement.announcement_type)
            }
            for notif, announcement in results
        ]
    
    def get_unread_count(self, user: User) -> int:
        """Get count of unread notifications"""
        accessible_course_ids = self.auth_service.get_enrolled_course_ids(user)
        
        count = self.db.query(UserNotification).join(
            Announcement,
            UserNotification.announcement_id == Announcement.id
        ).filter(
            and_(
                UserNotification.user_id == user.id,
                UserNotification.is_read == False,
                or_(
                    Announcement.course_id.is_(None),
                    Announcement.course_id.in_(accessible_course_ids) if accessible_course_ids else False
                ),
                or_(
                    Announcement.expires_at.is_(None),
                    Announcement.expires_at > datetime.utcnow()
                )
            )
        ).count()
        
        return count
    
    def mark_as_read(self, notification_id: int, user_id: int) -> bool:
        """Mark a notification as read"""
        notification = self.db.query(UserNotification).filter(
            and_(
                UserNotification.id == notification_id,
                UserNotification.user_id == user_id
            )
        ).first()
        
        if notification:
            notification.is_read = True
            notification.read_at = datetime.utcnow()
            self.db.commit()
            return True
        
        return False
    
    def mark_all_as_read(self, user_id: int) -> int:
        """Mark all notifications as read for a user"""
        count = self.db.query(UserNotification).filter(
            and_(
                UserNotification.user_id == user_id,
                UserNotification.is_read == False
            )
        ).update({
            'is_read': True,
            'read_at': datetime.utcnow()
        })
        
        self.db.commit()
        return count
    
    def delete_notification(self, notification_id: int, user_id: int) -> bool:
        """Delete a notification for a user"""
        notification = self.db.query(UserNotification).filter(
            and_(
                UserNotification.id == notification_id,
                UserNotification.user_id == user_id
            )
        ).first()
        
        if notification:
            self.db.delete(notification)
            self.db.commit()
            return True
        
        return False
    
    def create_new_course_notification(
        self,
        course_id: int,
        created_by_id: int
    ):
        """Auto-create notification when new course added"""
        from app.models.course import Course
        
        course = self.db.query(Course).filter(Course.id == course_id).first()
        if not course:
            return
        
        self.create_announcement(
            title=f"New Course: {course.name}",
            content=f"A new course '{course.name}' has been added.",
            announcement_type=AnnouncementType.NEW_COURSE,
            created_by_id=created_by_id,
            course_id=course_id,
            priority=1
        )
    
    def create_new_content_notification(
        self,
        course_id: int,
        file_count: int,
        created_by_id: int
    ):
        """Auto-create notification when new files added"""
        from app.models.course import Course
        
        course = self.db.query(Course).filter(Course.id == course_id).first()
        if not course:
            return
        
        self.create_announcement(
            title=f"New Content in {course.name}",
            content=f"{file_count} new file(s) added to {course.name}.",
            announcement_type=AnnouncementType.NEW_CONTENT,
            created_by_id=created_by_id,
            course_id=course_id,
            priority=0
        )
    
    def _create_user_notifications(self, announcement: Announcement):
        """Create notification records for all relevant users"""
        from app.models.enrollment import Enrollment
        
        # Determine which users should get this notification
        if announcement.course_id:
            # Course-specific: notify enrolled users
            enrollments = self.db.query(Enrollment).filter(
                Enrollment.course_id == announcement.course_id
            ).all()
            user_ids = [e.user_id for e in enrollments]
        else:
            # System-wide: notify all users
            from app.models.user import User
            users = self.db.query(User).all()
            user_ids = [u.id for u in users]
        
        # Create notification for each user
        for user_id in user_ids:
            # Skip if already exists
            existing = self.db.query(UserNotification).filter(
                and_(
                    UserNotification.user_id == user_id,
                    UserNotification.announcement_id == announcement.id
                )
            ).first()
            
            if not existing:
                notif = UserNotification(
                    user_id=user_id,
                    announcement_id=announcement.id
                )
                self.db.add(notif)
        
        try:
            self.db.commit()
        except Exception as e:
            print(f"Error creating user notifications: {e}")
            self.db.rollback()
    
    def _get_notification_icon(self, announcement_type: str) -> str:
        """Get Material icon for notification type"""
        icon_map = {
            AnnouncementType.COURSE_ANNOUNCEMENT: 'campaign',
            AnnouncementType.NEW_COURSE: 'school',
            AnnouncementType.NEW_CONTENT: 'fiber_new',
            AnnouncementType.SYSTEM: 'info'
        }
        
        return icon_map.get(announcement_type, 'notifications')
