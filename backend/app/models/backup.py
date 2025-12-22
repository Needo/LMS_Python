from sqlalchemy import Column, Integer, String, BigInteger, DateTime, ForeignKey, Text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import relationship
from app.db.database import Base
import datetime

class BackupHistory(Base):
    __tablename__ = "backup_history"
    
    id = Column(Integer, primary_key=True, index=True)
    filename = Column(String(255), nullable=False, unique=True)
    file_path = Column(String(512), nullable=False)
    file_size = Column(BigInteger)
    backup_type = Column(String(50), default='manual')
    created_by_id = Column(Integer, ForeignKey('users.id'))
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    status = Column(String(50), default='completed')
    backup_metadata = Column(JSONB)  # Changed from 'metadata' to 'backup_metadata'
    notes = Column(Text)
    
    created_by = relationship("User")

class OperationLock(Base):
    __tablename__ = "operation_lock"
    
    id = Column(Integer, primary_key=True, index=True)
    operation_type = Column(String(50), nullable=False)
    locked_by_id = Column(Integer, ForeignKey('users.id'))
    locked_at = Column(DateTime, default=datetime.datetime.utcnow)
    status = Column(String(50), default='in_progress')
    
    locked_by = relationship("User")
