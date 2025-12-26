"""
Search and notification models
"""
from sqlalchemy import Column, Integer, String, Text, DateTime, Boolean, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime
from app.db.database import Base
import enum

class AnnouncementType(str, enum.Enum):
    COURSE_ANNOUNCEMENT = "course_announcement"
    NEW_COURSE = "new_course"
    NEW_CONTENT = "new_content"
    SYSTEM = "system"

class Announcement(Base):
    """Course and system announcements"""
    __tablename__ = "announcements"
    
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(255), nullable=False)
    content = Column(Text, nullable=False)
    announcement_type = Column(String(50), default='course_announcement', nullable=False)
    
    # For course-specific announcements
    course_id = Column(Integer, ForeignKey("courses.id", ondelete="CASCADE"), nullable=True, index=True)
    
    # For file/content announcements
    file_id = Column(Integer, ForeignKey("file_nodes.id", ondelete="CASCADE"), nullable=True, index=True)
    
    # Creator
    created_by_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False, index=True)
    
    # Priority for sorting
    priority = Column(Integer, default=0)
    
    # Expiration (optional)
    expires_at = Column(DateTime, nullable=True)
    
    # Relationships
    course = relationship("Course", backref="announcements")
    file_node = relationship("FileNode", backref="announcements")
    created_by = relationship("User", backref="announcements")

class UserNotification(Base):
    """User-specific notification tracking"""
    __tablename__ = "user_notifications"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    announcement_id = Column(Integer, ForeignKey("announcements.id", ondelete="CASCADE"), nullable=False, index=True)
    
    # Read status
    is_read = Column(Boolean, default=False, nullable=False, index=True)
    read_at = Column(DateTime, nullable=True)
    
    # Created timestamp
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    
    # Relationships
    user = relationship("User", backref="notifications")
    announcement = relationship("Announcement", backref="user_notifications")

class SearchLog(Base):
    """Search query logging for analytics"""
    __tablename__ = "search_logs"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    query = Column(String(255), nullable=False, index=True)
    results_count = Column(Integer, default=0)
    search_type = Column(String(50))
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False, index=True)
    
    # Relationships
    user = relationship("User", backref="search_logs")
