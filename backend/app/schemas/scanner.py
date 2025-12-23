from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from enum import Enum

class ScanStatusEnum(str, Enum):
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    PARTIAL = "partial"

class ScanRequest(BaseModel):
    root_path: str

class ScanResult(BaseModel):
    success: bool
    message: str
    categories_found: int = 0
    courses_found: int = 0
    files_added: int = 0
    files_removed: int = 0
    files_updated: int = 0
    errors_count: int = 0
    scan_id: Optional[int] = None
    status: Optional[ScanStatusEnum] = None

class ScanErrorDetail(BaseModel):
    id: int
    file_path: str
    error_type: str
    error_message: str
    created_at: datetime
    
    class Config:
        from_attributes = True

class ScanHistoryResponse(BaseModel):
    id: int
    started_by_id: int
    started_at: datetime
    completed_at: Optional[datetime]
    status: ScanStatusEnum
    root_path: str
    categories_found: int
    courses_found: int
    files_added: int
    files_updated: int
    files_removed: int
    errors_count: int
    message: Optional[str]
    error_message: Optional[str]
    errors: List[ScanErrorDetail] = []
    
    class Config:
        from_attributes = True

class ScanStatusResponse(BaseModel):
    is_scanning: bool
    current_scan_id: Optional[int]
    status: Optional[ScanStatusEnum]
    started_at: Optional[datetime]
    locked_by_id: Optional[int]
    last_scan: Optional[ScanHistoryResponse]

class RootPathRequest(BaseModel):
    root_path: str

class RootPathResponse(BaseModel):
    root_path: Optional[str]
