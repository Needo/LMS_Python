"""
Scan history and error tracking models
"""
from sqlalchemy import Column, Integer, String, DateTime, Boolean, Text, ForeignKey, Enum as SQLEnum
from sqlalchemy.orm import relationship
from datetime import datetime
from enum import Enum
from app.db.database import Base

class ScanStatus(str, Enum):
    """Scan state machine states"""
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    PARTIAL = "partial"

class ScanHistory(Base):
    """Track all scan operations"""
    __tablename__ = "scan_history"
    
    id = Column(Integer, primary_key=True, index=True)
    started_by_id = Column(Integer, ForeignKey('users.id'), nullable=False)
    started_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    completed_at = Column(DateTime, nullable=True)
    status = Column(SQLEnum(ScanStatus), default=ScanStatus.PENDING, nullable=False)
    
    # Scan details
    root_path = Column(String(500), nullable=False)
    categories_found = Column(Integer, default=0)
    courses_found = Column(Integer, default=0)
    files_added = Column(Integer, default=0)
    files_updated = Column(Integer, default=0)
    files_removed = Column(Integer, default=0)
    errors_count = Column(Integer, default=0)
    
    # Result message
    message = Column(Text, nullable=True)
    error_message = Column(Text, nullable=True)
    
    # Relationships
    started_by = relationship("User", backref="scans")
    errors = relationship("ScanError", back_populates="scan", cascade="all, delete-orphan")

class ScanError(Base):
    """Track file-level scan errors"""
    __tablename__ = "scan_errors"
    
    id = Column(Integer, primary_key=True, index=True)
    scan_id = Column(Integer, ForeignKey('scan_history.id'), nullable=False)
    file_path = Column(String(500), nullable=False)
    error_type = Column(String(100), nullable=False)  # e.g., "path_traversal", "invalid_extension", "oversized"
    error_message = Column(Text, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationship
    scan = relationship("ScanHistory", back_populates="errors")

class ScanLock(Base):
    """Prevent concurrent scans"""
    __tablename__ = "scan_lock"
    
    id = Column(Integer, primary_key=True)
    is_locked = Column(Boolean, default=False, nullable=False)
    locked_by_id = Column(Integer, ForeignKey('users.id'), nullable=True)
    locked_at = Column(DateTime, nullable=True)
    scan_id = Column(Integer, ForeignKey('scan_history.id'), nullable=True)
    
    # Relationships
    locked_by = relationship("User")
    scan = relationship("ScanHistory")
