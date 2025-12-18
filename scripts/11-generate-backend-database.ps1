# Script 11: Generate Backend Database Models
# This script generates SQLAlchemy models and database connection

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Generating Database Models..." -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

$rootPath = "C:\Users\munawar\Documents\Python_LMS_V2"
$backendPath = Join-Path $rootPath "backend"

# Function to create file with content
function Create-File {
    param (
        [string]$Path,
        [string]$Content
    )
    $directory = Split-Path $Path -Parent
    if (-not (Test-Path $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    Set-Content -Path $Path -Value $Content -Encoding UTF8
    Write-Host "Created: $Path" -ForegroundColor Green
}

Write-Host "`n1. Creating database connection..." -ForegroundColor Yellow

$databaseContent = @'
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from app.core.config import settings

engine = create_engine(settings.DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
'@

Create-File -Path (Join-Path $backendPath "app\db\database.py") -Content $databaseContent

Write-Host "`n2. Creating User model..." -ForegroundColor Yellow

$userModelContent = @'
from sqlalchemy import Column, Integer, String, Boolean, DateTime
from sqlalchemy.orm import relationship
from datetime import datetime
from app.db.database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    is_admin = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    progress = relationship("UserProgress", back_populates="user")
    last_viewed = relationship("LastViewed", back_populates="user", uselist=False)
'@

Create-File -Path (Join-Path $backendPath "app\models\user.py") -Content $userModelContent

Write-Host "`n3. Creating Category model..." -ForegroundColor Yellow

$categoryModelContent = @'
from sqlalchemy import Column, Integer, String, DateTime
from sqlalchemy.orm import relationship
from datetime import datetime
from app.db.database import Base

class Category(Base):
    __tablename__ = "categories"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, index=True, nullable=False)
    path = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    courses = relationship("Course", back_populates="category", cascade="all, delete-orphan")
'@

Create-File -Path (Join-Path $backendPath "app\models\category.py") -Content $categoryModelContent

Write-Host "`n4. Creating Course model..." -ForegroundColor Yellow

$courseModelContent = @'
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime
from app.db.database import Base

class Course(Base):
    __tablename__ = "courses"

    id = Column(Integer, primary_key=True, index=True)
    category_id = Column(Integer, ForeignKey("categories.id"), nullable=False)
    name = Column(String, index=True, nullable=False)
    path = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    category = relationship("Category", back_populates="courses")
    files = relationship("FileNode", back_populates="course", cascade="all, delete-orphan")
'@

Create-File -Path (Join-Path $backendPath "app\models\course.py") -Content $courseModelContent

Write-Host "`n5. Creating FileNode model..." -ForegroundColor Yellow

$fileNodeModelContent = @'
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
'@

Create-File -Path (Join-Path $backendPath "app\models\file_node.py") -Content $fileNodeModelContent

Write-Host "`n6. Creating UserProgress model..." -ForegroundColor Yellow

$progressModelContent = @'
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Enum
from sqlalchemy.orm import relationship
from datetime import datetime
import enum
from app.db.database import Base

class ProgressStatus(str, enum.Enum):
    NOT_STARTED = "not_started"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"

class UserProgress(Base):
    __tablename__ = "user_progress"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    file_id = Column(Integer, ForeignKey("file_nodes.id"), nullable=False)
    status = Column(Enum(ProgressStatus), default=ProgressStatus.NOT_STARTED)
    last_position = Column(Integer, nullable=True)
    completed_at = Column(DateTime, nullable=True)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    user = relationship("User", back_populates="progress")
    file = relationship("FileNode", back_populates="progress")
'@

Create-File -Path (Join-Path $backendPath "app\models\progress.py") -Content $progressModelContent

Write-Host "`n7. Creating LastViewed model..." -ForegroundColor Yellow

$lastViewedModelContent = @'
from sqlalchemy import Column, Integer, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime
from app.db.database import Base

class LastViewed(Base):
    __tablename__ = "last_viewed"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)
    course_id = Column(Integer, ForeignKey("courses.id"), nullable=False)
    file_id = Column(Integer, ForeignKey("file_nodes.id"), nullable=False)
    timestamp = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    user = relationship("User", back_populates="last_viewed")
    course = relationship("Course")
    file = relationship("FileNode")
'@

Create-File -Path (Join-Path $backendPath "app\models\last_viewed.py") -Content $lastViewedModelContent

Write-Host "`n8. Creating Settings model for root path..." -ForegroundColor Yellow

$settingsModelContent = @'
from sqlalchemy import Column, Integer, String, DateTime
from datetime import datetime
from app.db.database import Base

class Settings(Base):
    __tablename__ = "settings"

    id = Column(Integer, primary_key=True, index=True)
    key = Column(String, unique=True, nullable=False)
    value = Column(String, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
'@

Create-File -Path (Join-Path $backendPath "app\models\settings.py") -Content $settingsModelContent

Write-Host "`n9. Creating models __init__.py..." -ForegroundColor Yellow

$modelsInitContent = @'
from app.models.user import User
from app.models.category import Category
from app.models.course import Course
from app.models.file_node import FileNode
from app.models.progress import UserProgress, ProgressStatus
from app.models.last_viewed import LastViewed
from app.models.settings import Settings

__all__ = [
    "User",
    "Category",
    "Course",
    "FileNode",
    "UserProgress",
    "ProgressStatus",
    "LastViewed",
    "Settings"
]
'@

Create-File -Path (Join-Path $backendPath "app\models\__init__.py") -Content $modelsInitContent

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "Database Models Created!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "`nNext step: Run 12-generate-backend-schemas.ps1" -ForegroundColor Yellow
