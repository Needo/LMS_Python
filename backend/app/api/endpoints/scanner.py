from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.models import User
from app.schemas import ScanRequest, ScanResult, RootPathRequest, RootPathResponse
from app.services import ScannerService
from app.core.dependencies import get_current_user
from app.core.rate_limit import check_rate_limit
from app.core.config import settings
from fastapi import Request

router = APIRouter()

@router.post("/scan", response_model=ScanResult)
def scan_root_folder(
    scan_request: ScanRequest,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Scan the root folder and populate the database.
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
