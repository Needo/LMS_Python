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
