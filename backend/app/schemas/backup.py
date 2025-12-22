from pydantic import BaseModel
from datetime import datetime
from typing import Optional, Dict, Any, List

class BackupCreate(BaseModel):
    notes: Optional[str] = None

class BackupResponse(BaseModel):
    id: int
    filename: str
    file_size: int
    backup_type: str
    created_by: str
    created_at: datetime
    status: str
    notes: Optional[str]
    
    class Config:
        from_attributes = True

class BackupListResponse(BaseModel):
    backups: List[BackupResponse]
    total: int

class BackupStatusResponse(BaseModel):
    is_locked: bool
    operation_type: Optional[str] = None
    locked_by: Optional[str] = None
    locked_at: Optional[datetime] = None

class RestoreRequest(BaseModel):
    backup_id: int
    confirm: bool = False
