"""
Scan logging models
"""
from sqlalchemy import Column, Integer, String, DateTime, Text, ForeignKey, Enum as SQLEnum, Index
from sqlalchemy.orm import relationship
from datetime import datetime
from enum import Enum
from app.db.database import Base

class LogLevel(str, Enum):
    DEBUG = "debug"
    INFO = "info"
    WARNING = "warning"
    ERROR = "error"
    CRITICAL = "critical"

class ScanLog(Base):
    """Detailed scan operation logs"""
    __tablename__ = "scan_logs"
    
    id = Column(Integer, primary_key=True, index=True)
    scan_id = Column(Integer, ForeignKey('scan_history.id', ondelete='CASCADE'), nullable=False, index=True)
    correlation_id = Column(String(36), nullable=True, index=True)
    timestamp = Column(DateTime, default=datetime.utcnow, nullable=False, index=True)
    level = Column(SQLEnum(LogLevel), default=LogLevel.INFO, nullable=False, index=True)
    
    # Log details
    message = Column(Text, nullable=False)
    module = Column(String(100), nullable=True)
    function = Column(String(100), nullable=True)
    
    # Optional context
    file_path = Column(String(500), nullable=True, index=True)
    category = Column(String(200), nullable=True)
    course = Column(String(200), nullable=True)
    
    # Extra data (JSON-like string)
    extra = Column(Text, nullable=True)
    
    # Relationship
    scan = relationship("ScanHistory", backref="logs")
    
    __table_args__ = (
        Index('idx_scan_logs_scan_timestamp', 'scan_id', 'timestamp'),
        Index('idx_scan_logs_level_timestamp', 'level', 'timestamp'),
    )

class FileAccessLog(Base):
    """File streaming/download access logs"""
    __tablename__ = "file_access_logs"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey('users.id', ondelete='SET NULL'), nullable=True, index=True)
    file_id = Column(Integer, ForeignKey('file_nodes.id', ondelete='SET NULL'), nullable=True, index=True)
    correlation_id = Column(String(36), nullable=True, index=True)
    accessed_at = Column(DateTime, default=datetime.utcnow, nullable=False, index=True)
    
    # Access details
    file_path = Column(String(500), nullable=False)
    file_name = Column(String(255), nullable=False)
    file_size = Column(Integer, nullable=True)
    action = Column(String(20), nullable=False)  # 'stream', 'download', 'view'
    
    # Client info
    ip_address = Column(String(45), nullable=True)
    user_agent = Column(String(500), nullable=True)
    
    # Result
    success = Column(String(20), default=True, nullable=False)
    error_message = Column(Text, nullable=True)
    
    # Relationships
    user = relationship("User")
    file_node = relationship("FileNode")
    
    __table_args__ = (
        Index('idx_file_access_user_accessed', 'user_id', 'accessed_at'),
        Index('idx_file_access_file_accessed', 'file_id', 'accessed_at'),
    )
