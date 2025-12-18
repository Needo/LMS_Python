# Script 16: Generate Backend API Endpoints (Part 2)
# This script generates API endpoints for files, progress, and scanner

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Generating API Endpoints (Part 2)..." -ForegroundColor Cyan
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

Write-Host "`n1. Creating Files Endpoint..." -ForegroundColor Yellow

$filesEndpointContent = @'
from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from typing import List
from app.db.database import get_db
from app.models import FileNode as FileNodeModel, User
from app.schemas import FileNode
from app.core.dependencies import get_current_user
import os

router = APIRouter()

@router.get("/course/{course_id}", response_model=List[FileNode])
def get_files_by_course(
    course_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get all files in a specific course.
    """
    files = db.query(FileNodeModel).filter(
        FileNodeModel.course_id == course_id
    ).all()
    return files

@router.get("/{file_id}", response_model=FileNode)
def get_file(
    file_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get a specific file by ID.
    """
    file = db.query(FileNodeModel).filter(FileNodeModel.id == file_id).first()
    if not file:
        raise HTTPException(status_code=404, detail="File not found")
    return file

@router.get("/{file_id}/content")
def get_file_content(
    file_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get the actual file content for viewing.
    """
    file = db.query(FileNodeModel).filter(FileNodeModel.id == file_id).first()
    if not file:
        raise HTTPException(status_code=404, detail="File not found")
    
    if file.is_directory:
        raise HTTPException(status_code=400, detail="Cannot get content of a directory")
    
    if not os.path.exists(file.path):
        raise HTTPException(status_code=404, detail="File not found on disk")
    
    return FileResponse(file.path)
'@

Create-File -Path (Join-Path $backendPath "app\api\endpoints\files.py") -Content $filesEndpointContent

Write-Host "`n2. Creating Progress Endpoint..." -ForegroundColor Yellow

$progressEndpointContent = @'
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
'@

Create-File -Path (Join-Path $backendPath "app\api\endpoints\progress.py") -Content $progressEndpointContent

Write-Host "`n3. Creating Scanner Endpoint..." -ForegroundColor Yellow

$scannerEndpointContent = @'
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.models import User
from app.schemas import ScanRequest, ScanResult, RootPathRequest, RootPathResponse
from app.services import ScannerService
from app.core.dependencies import get_current_user

router = APIRouter()

@router.post("/scan", response_model=ScanResult)
def scan_root_folder(
    scan_request: ScanRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Scan the root folder and populate the database.
    """
    scanner_service = ScannerService(db)
    return scanner_service.scan_root_folder(scan_request.root_path)

@router.post("/rescan/{course_id}", response_model=ScanResult)
def rescan_course(
    course_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Rescan a specific course.
    """
    # This would be similar to scan but for a specific course
    # Implementation can be added later if needed
    raise HTTPException(status_code=501, detail="Not implemented yet")

@router.get("/root-path", response_model=RootPathResponse)
def get_root_path(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get the configured root path.
    """
    scanner_service = ScannerService(db)
    root_path = scanner_service.get_root_path()
    return RootPathResponse(root_path=root_path)

@router.post("/root-path")
def set_root_path(
    request: RootPathRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Set the root path.
    """
    scanner_service = ScannerService(db)
    success = scanner_service.set_root_path(request.root_path)
    
    if success:
        return {"success": True}
    else:
        raise HTTPException(status_code=500, detail="Failed to set root path")
'@

Create-File -Path (Join-Path $backendPath "app\api\endpoints\scanner.py") -Content $scannerEndpointContent

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "API Endpoints (Part 2) Created!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "`nNext step: Run 17-generate-backend-main.ps1" -ForegroundColor Yellow
