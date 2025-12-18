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
