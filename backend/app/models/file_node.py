from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Boolean, BigInteger
from sqlalchemy.orm import relationship
from datetime import datetime
from app.db.database import Base

class FileNode(Base):
    __tablename__ = "file_nodes"

    id = Column(Integer, primary_key=True, index=True)
    course_id = Column(Integer, ForeignKey("courses.id"), nullable=False)
    name = Column(String, nullable=False)
    path = Column(String, unique=True, nullable=False)
    file_type = Column(String, nullable=False)
    parent_id = Column(Integer, ForeignKey("file_nodes.id"), nullable=True)
    is_directory = Column(Boolean, default=False)
    size = Column(BigInteger, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    course = relationship("Course", back_populates="files")
    parent = relationship("FileNode", remote_side=[id], backref="children")
    progress = relationship("UserProgress", back_populates="file")
