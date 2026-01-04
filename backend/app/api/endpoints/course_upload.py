"""
Course upload endpoint for uploading folders with files
"""
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.orm import Session
from typing import List
import os
import shutil
from pathlib import Path
from app.db.database import get_db
from app.models.user import User
from app.models.category import Category
from app.models.course import Course
from app.models.file_node import FileNode
from app.core.dependencies import get_admin_user

router = APIRouter()

@router.post("/upload")
async def upload_course_folder(
    categoryId: int = Form(...),
    courseName: str = Form(...),
    files: List[UploadFile] = File(...),
    paths: List[str] = Form(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_admin_user)
):
    """
    Upload a complete course folder with files and subdirectories.
    Admin only.
    """
    
    # Validate category exists
    category = db.query(Category).filter(Category.id == categoryId).first()
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")
    
    # Get the root folder path from settings
    from app.core.config import settings
    root_folder = Path(settings.ROOT_FOLDER_PATH)
    
    if not root_folder.exists():
        raise HTTPException(status_code=500, detail="Root folder not configured properly")
    
    # Create category folder if it doesn't exist
    category_folder = root_folder / category.name
    category_folder.mkdir(parents=True, exist_ok=True)
    
    # Create course folder
    course_folder = category_folder / courseName
    
    # Check if course folder already exists
    if course_folder.exists():
        raise HTTPException(
            status_code=400, 
            detail=f"Course '{courseName}' already exists in category '{category.name}'"
        )
    
    course_folder.mkdir(parents=True, exist_ok=True)
    
    try:
        # Create course in database
        course = Course(
            name=courseName,
            category_id=categoryId,
            path=str(course_folder),
            description=f"Uploaded course: {courseName}"
        )
        db.add(course)
        db.flush()  # Get course ID
        
        # Track created files for database
        file_records = []
        
        # Save all uploaded files
        for upload_file, relative_path in zip(files, paths):
            # Create full file path
            file_path = course_folder / relative_path
            
            # Create parent directories if needed
            file_path.parent.mkdir(parents=True, exist_ok=True)
            
            # Save file
            with open(file_path, "wb") as f:
                content = await upload_file.read()
                f.write(content)
            
            # Determine if this is a directory entry or file
            is_directory = False
            parent_id = None
            
            # Parse the path to determine parent
            path_parts = Path(relative_path).parts
            
            if len(path_parts) > 1:
                # This file is in a subdirectory
                # We need to find or create the parent folder record
                parent_path = str(Path(*path_parts[:-1]))
                
                # Find parent folder in file_records or create it
                parent_record = next(
                    (f for f in file_records if f['path'] == parent_path and f['is_directory']),
                    None
                )
                
                if parent_record:
                    parent_id = parent_record['id']
            
            # Create file record
            file_record = FileNode(
                name=upload_file.filename or path_parts[-1],
                path=str(file_path),
                course_id=course.id,
                file_type=upload_file.content_type or 'application/octet-stream',
                file_size=len(content),
                is_directory=False,
                parent_id=parent_id
            )
            
            db.add(file_record)
            db.flush()  # Get file ID
            
            file_records.append({
                'id': file_record.id,
                'path': relative_path,
                'is_directory': False
            })
        
        # Also create folder records for directories
        directories = set()
        for path in paths:
            path_parts = Path(path).parts
            for i in range(1, len(path_parts)):
                dir_path = str(Path(*path_parts[:i]))
                if dir_path not in directories:
                    directories.add(dir_path)
                    
                    # Find parent
                    parent_id = None
                    if i > 1:
                        parent_path = str(Path(*path_parts[:i-1]))
                        parent_record = next(
                            (f for f in file_records if f['path'] == parent_path and f['is_directory']),
                            None
                        )
                        if parent_record:
                            parent_id = parent_record['id']
                    
                    # Create folder record
                    folder_path = course_folder / dir_path
                    folder_record = FileNode(
                        name=path_parts[i-1],
                        path=str(folder_path),
                        course_id=course.id,
                        is_directory=True,
                        parent_id=parent_id
                    )
                    db.add(folder_record)
                    db.flush()
                    
                    file_records.append({
                        'id': folder_record.id,
                        'path': dir_path,
                        'is_directory': True
                    })
        
        db.commit()
        
        return {
            "courseId": course.id,
            "courseName": courseName,
            "filesUploaded": len(files),
            "message": f"Successfully uploaded {len(files)} files to course '{courseName}'"
        }
        
    except Exception as e:
        db.rollback()
        
        # Clean up created folder if upload fails
        if course_folder.exists():
            shutil.rmtree(course_folder)
        
        raise HTTPException(
            status_code=500,
            detail=f"Upload failed: {str(e)}"
        )
