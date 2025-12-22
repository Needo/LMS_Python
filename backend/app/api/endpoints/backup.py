from fastapi import APIRouter, Depends, HTTPException, status, Request
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from typing import List
import os
from app.db.database import get_db
from app.core.dependencies import get_current_user
from app.core.rate_limit import check_rate_limit
from app.core.config import settings
from app.models.user import User
from app.schemas.backup import (
    BackupCreate, BackupResponse, BackupListResponse,
    BackupStatusResponse, RestoreRequest
)
from app.services.backup_service import BackupService
from app.services.restore_service import RestoreService
from app.services.lock_service import LockService

router = APIRouter()

def get_current_active_admin(
    current_user: User = Depends(get_current_user)
) -> User:
    """Verify user is admin"""
    if not current_user.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions"
        )
    return current_user

@router.post("/create", response_model=BackupResponse)
async def create_backup(
    backup_data: BackupCreate,
    request: Request,
    current_user: User = Depends(get_current_active_admin),
    db: Session = Depends(get_db)
):
    """Create a new database backup with rate limiting"""
    # Rate limiting
    if settings.ENABLE_RATE_LIMITING:
        check_rate_limit(
            request,
            max_requests=settings.ADMIN_RATE_LIMIT,
            window_seconds=3600,
            key_prefix="admin:backup"
        )
    
    try:
        backup_service = BackupService(db)
        backup = backup_service.create_backup(
            user_id=current_user.id,
            notes=backup_data.notes
        )
        
        return BackupResponse(
            id=backup.id,
            filename=backup.filename,
            file_size=backup.file_size,
            backup_type=backup.backup_type,
            created_by=backup.created_by.username,
            created_at=backup.created_at,
            status=backup.status,
            notes=backup.notes
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.get("/list", response_model=BackupListResponse)
def list_backups(
    skip: int = 0,
    limit: int = 50,
    current_user: User = Depends(get_current_active_admin),
    db: Session = Depends(get_db)
):
    """List all available backups"""
    backup_service = BackupService(db)
    backups = backup_service.list_backups(limit=limit, offset=skip)
    
    backup_responses = [
        BackupResponse(
            id=backup.id,
            filename=backup.filename,
            file_size=backup.file_size,
            backup_type=backup.backup_type,
            created_by=backup.created_by.username,
            created_at=backup.created_at,
            status=backup.status,
            notes=backup.notes
        )
        for backup in backups
    ]
    
    return BackupListResponse(
        backups=backup_responses,
        total=len(backup_responses)
    )

@router.get("/download/{backup_id}")
async def download_backup(
    backup_id: int,
    current_user: User = Depends(get_current_active_admin),
    db: Session = Depends(get_db)
):
    """Download a backup file"""
    backup_service = BackupService(db)
    backup = backup_service.get_backup_by_id(backup_id)
    
    if not backup:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Backup not found"
        )
    
    if not os.path.exists(backup.file_path):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Backup file not found on disk"
        )
    
    return FileResponse(
        path=backup.file_path,
        filename=backup.filename,
        media_type='application/octet-stream'
    )

@router.post("/restore/{backup_id}")
async def restore_backup(
    backup_id: int,
    restore_data: RestoreRequest,
    current_user: User = Depends(get_current_active_admin),
    db: Session = Depends(get_db)
):
    """Restore database from backup (DESTRUCTIVE)"""
    if not restore_data.confirm:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Confirmation required for restore operation"
        )
    
    try:
        restore_service = RestoreService(db)
        success = restore_service.restore_backup(
            backup_id=backup_id,
            user_id=current_user.id
        )
        
        if success:
            return {"message": "Database restored successfully"}
        else:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Restore failed"
            )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.delete("/{backup_id}")
async def delete_backup(
    backup_id: int,
    current_user: User = Depends(get_current_active_admin),
    db: Session = Depends(get_db)
):
    """Delete a backup"""
    backup_service = BackupService(db)
    success = backup_service.delete_backup(backup_id, current_user.id)
    
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Backup not found or could not be deleted"
        )
    
    return {"message": "Backup deleted successfully"}

@router.get("/status", response_model=BackupStatusResponse)
def get_backup_status(
    current_user: User = Depends(get_current_active_admin),
    db: Session = Depends(get_db)
):
    """Get current backup/restore operation status"""
    lock_service = LockService(db)
    lock = lock_service.check_lock_status()
    
    if lock:
        return BackupStatusResponse(
            is_locked=True,
            operation_type=lock.operation_type,
            locked_by=lock.locked_by.username,
            locked_at=lock.locked_at
        )
    
    return BackupStatusResponse(is_locked=False)
