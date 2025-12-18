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
