# Script 12: Generate Backend Schemas (Pydantic)
# This script generates Pydantic schemas for request/response validation

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Generating Backend Schemas..." -ForegroundColor Cyan
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

Write-Host "`n1. Creating User schemas..." -ForegroundColor Yellow

$userSchemaContent = @'
from pydantic import BaseModel, EmailStr
from datetime import datetime
from typing import Optional

class UserBase(BaseModel):
    username: str
    email: EmailStr

class UserCreate(UserBase):
    password: str

class UserLogin(BaseModel):
    username: str
    password: str

class User(UserBase):
    id: int
    is_admin: bool
    created_at: datetime

    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str
    user: User

class TokenData(BaseModel):
    username: Optional[str] = None
'@

Create-File -Path (Join-Path $backendPath "app\schemas\user.py") -Content $userSchemaContent

Write-Host "`n2. Creating Category schemas..." -ForegroundColor Yellow

$categorySchemaContent = @'
from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class CategoryBase(BaseModel):
    name: str
    path: str

class CategoryCreate(CategoryBase):
    pass

class Category(CategoryBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True
'@

Create-File -Path (Join-Path $backendPath "app\schemas\category.py") -Content $categorySchemaContent

Write-Host "`n3. Creating Course schemas..." -ForegroundColor Yellow

$courseSchemaContent = @'
from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class CourseBase(BaseModel):
    name: str
    path: str
    category_id: int

class CourseCreate(CourseBase):
    pass

class Course(CourseBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True
'@

Create-File -Path (Join-Path $backendPath "app\schemas\course.py") -Content $courseSchemaContent

Write-Host "`n4. Creating FileNode schemas..." -ForegroundColor Yellow

$fileSchemaContent = @'
from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List

class FileNodeBase(BaseModel):
    name: str
    path: str
    file_type: str
    is_directory: bool

class FileNodeCreate(FileNodeBase):
    course_id: int
    parent_id: Optional[int] = None
    size: Optional[int] = None

class FileNode(FileNodeBase):
    id: int
    course_id: int
    parent_id: Optional[int]
    size: Optional[int]
    created_at: datetime

    class Config:
        from_attributes = True

class FileNodeTree(FileNode):
    children: Optional[List['FileNodeTree']] = []
'@

Create-File -Path (Join-Path $backendPath "app\schemas\file_node.py") -Content $fileSchemaContent

Write-Host "`n5. Creating Progress schemas..." -ForegroundColor Yellow

$progressSchemaContent = @'
from pydantic import BaseModel
from datetime import datetime
from typing import Optional
from enum import Enum

class ProgressStatus(str, Enum):
    NOT_STARTED = "not_started"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"

class UserProgressBase(BaseModel):
    user_id: int
    file_id: int
    status: ProgressStatus
    last_position: Optional[int] = None

class UserProgressCreate(UserProgressBase):
    pass

class UserProgress(UserProgressBase):
    id: int
    completed_at: Optional[datetime]
    updated_at: datetime

    class Config:
        from_attributes = True

class LastViewedBase(BaseModel):
    user_id: int
    course_id: int
    file_id: int

class LastViewedCreate(LastViewedBase):
    pass

class LastViewed(LastViewedBase):
    id: int
    timestamp: datetime

    class Config:
        from_attributes = True
'@

Create-File -Path (Join-Path $backendPath "app\schemas\progress.py") -Content $progressSchemaContent

Write-Host "`n6. Creating Scanner schemas..." -ForegroundColor Yellow

$scannerSchemaContent = @'
from pydantic import BaseModel
from typing import Optional

class ScanRequest(BaseModel):
    root_path: str

class ScanResult(BaseModel):
    success: bool
    message: str
    categories_found: int
    courses_found: int
    files_added: int
    files_removed: int
    files_updated: int

class RootPathRequest(BaseModel):
    root_path: str

class RootPathResponse(BaseModel):
    root_path: Optional[str]
'@

Create-File -Path (Join-Path $backendPath "app\schemas\scanner.py") -Content $scannerSchemaContent

Write-Host "`n7. Creating schemas __init__.py..." -ForegroundColor Yellow

$schemasInitContent = @'
from app.schemas.user import User, UserCreate, UserLogin, Token, TokenData
from app.schemas.category import Category, CategoryCreate
from app.schemas.course import Course, CourseCreate
from app.schemas.file_node import FileNode, FileNodeCreate, FileNodeTree
from app.schemas.progress import UserProgress, UserProgressCreate, LastViewed, LastViewedCreate, ProgressStatus
from app.schemas.scanner import ScanRequest, ScanResult, RootPathRequest, RootPathResponse

__all__ = [
    "User", "UserCreate", "UserLogin", "Token", "TokenData",
    "Category", "CategoryCreate",
    "Course", "CourseCreate",
    "FileNode", "FileNodeCreate", "FileNodeTree",
    "UserProgress", "UserProgressCreate",
    "LastViewed", "LastViewedCreate",
    "ProgressStatus",
    "ScanRequest", "ScanResult",
    "RootPathRequest", "RootPathResponse"
]
'@

Create-File -Path (Join-Path $backendPath "app\schemas\__init__.py") -Content $schemasInitContent

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "Backend Schemas Created!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "`nNext step: Run 13-generate-backend-services.ps1" -ForegroundColor Yellow
