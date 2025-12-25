from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.models import User
from app.schemas import ScanRequest, ScanResult, RootPathRequest, RootPathResponse
from app.schemas.scanner import ScanStatusResponse, ScanHistoryResponse
from app.services import ScannerService
from app.services.reliable_scanner_service import ReliableScannerService
from app.core.dependencies import get_current_user
from app.core.rate_limit import check_rate_limit
from app.core.config import settings
from typing import List

router = APIRouter()

@router.post("/scan")
def scan_root_folder(
    scan_request: ScanRequest,
    request: Request,
    background: bool = True,  # Run in background by default
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Scan the root folder with state management and error tracking.
    Runs in background by default for long-running operations.
    Admin only with rate limiting.
    """
    # Check if user is admin
    if not current_user.is_admin:
        raise HTTPException(
            status_code=403,
            detail="Only administrators can scan folders"
        )
    
    # Rate limiting
    if settings.ENABLE_RATE_LIMITING:
        check_rate_limit(
            request, 
            max_requests=settings.SCAN_RATE_LIMIT,
            window_seconds=3600,  # 1 hour
            key_prefix="scan"
        )
    
    # Use reliable scanner
    reliable_scanner = ReliableScannerService(db)
    
    if background:
        # Run in background
        result = reliable_scanner.scan_root_folder_background(
            scan_request.root_path,
            current_user.id
        )
        return result
    else:
        # Run synchronously (old behavior)
        result = reliable_scanner.scan_root_folder_reliable(
            scan_request.root_path,
            current_user.id
        )
        return result

@router.post("/rescan/{course_id}", response_model=ScanResult)
def rescan_course(
    course_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Rescan a specific course.
    Admin only.
    """
    if not current_user.is_admin:
        raise HTTPException(
            status_code=403,
            detail="Only administrators can scan courses"
        )
    
    # Get course to validate it exists
    from app.models.course import Course
    course = db.query(Course).filter(Course.id == course_id).first()
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    
    # Use regular scanner for single course
    scanner_service = ScannerService(db)
    result = scanner_service.scan_course(course_id)
    
    return result

@router.get("/status", response_model=ScanStatusResponse)
def get_scan_status(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get current scan status and last scan results.
    """
    reliable_scanner = ReliableScannerService(db)
    return reliable_scanner.get_scan_status()

@router.get("/history", response_model=List[ScanHistoryResponse])
def get_scan_history(
    limit: int = 10,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get scan history (admin only).
    """
    if not current_user.is_admin:
        raise HTTPException(
            status_code=403,
            detail="Only administrators can view scan history"
        )
    
    reliable_scanner = ReliableScannerService(db)
    return reliable_scanner.get_scan_history(limit)

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

@router.get("/logs/{scan_id}")
def get_scan_logs(
    scan_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get detailed logs for a specific scan.
    Admin only.
    """
    if not current_user.is_admin:
        raise HTTPException(
            status_code=403,
            detail="Only administrators can view scan logs"
        )
    
    from app.models.scan_history import ScanError
    
    # Get scan errors
    errors = db.query(ScanError).filter(
        ScanError.scan_id == scan_id
    ).order_by(ScanError.occurred_at.desc()).all()
    
    return {
        "scan_id": scan_id,
        "errors": [
            {
                "id": e.id,
                "path": e.path,
                "error_type": e.error_type,
                "error_message": e.error_message,
                "occurred_at": e.occurred_at.isoformat()
            }
            for e in errors
        ]
    }

@router.post("/cleanup")
def cleanup_orphaned_entries(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Clean up orphaned database entries (files that no longer exist on disk).
    Admin only.
    """
    if not current_user.is_admin:
        raise HTTPException(
            status_code=403,
            detail="Only administrators can cleanup database"
        )
    
    from app.services.cleanup_service import CleanupService
    
    cleanup_service = CleanupService(db)
    result = cleanup_service.cleanup_orphan_files()
    
    return {
        "success": True,
        "files_removed": result["removed_count"],
        "message": result["message"]
    }
