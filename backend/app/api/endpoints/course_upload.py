"""
Course upload endpoint for uploading folders with files
"""
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.orm import Session
from typing import List
import os
import shutil
from pathlib import Path
import logging
from app.db.database import get_db
from app.models.user import User
from app.models.category import Category
from app.models.course import Course
from app.models.file_node import FileNode
from app.core.dependencies import get_admin_user

router = APIRouter()
logger = logging.getLogger(__name__)

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
    
    logger.info(f"Upload request - Category: {categoryId}, Course: {courseName}, Files: {len(files)}")
    
    try:
        # Validate category exists
        category = db.query(Category).filter(Category.id == categoryId).first()
        if not category:
            logger.error(f"Category not found: {categoryId}")
            raise HTTPException(status_code=404, detail="Category not found")
        
        logger.info(f"Category found: {category.name}")
        
        # Get the root folder path from database settings (not from .env)
        from app.models.settings import Settings as SettingsModel
        
        root_path_setting = db.query(SettingsModel).filter(
            SettingsModel.key == 'root_path'
        ).first()
        
        if not root_path_setting or not root_path_setting.value:
            logger.error("ROOT_FOLDER_PATH is not configured in database")
            raise HTTPException(
                status_code=500, 
                detail="Root folder path is not configured. Please set it in Admin panel > Folder Settings first."
            )
        
        root_folder = Path(root_path_setting.value)
        logger.info(f"Root folder from database: {root_folder}")
        
        if not root_folder.exists():
            logger.error(f"Root folder does not exist: {root_folder}")
            raise HTTPException(status_code=500, detail=f"Root folder does not exist: {root_folder}")
        
        # Check write permissions
        if not os.access(root_folder, os.W_OK):
            logger.error(f"No write permission for root folder: {root_folder}")
            raise HTTPException(status_code=500, detail="No write permission for root folder")
        
        # Create category folder if it doesn't exist
        category_folder = root_folder / category.name
        logger.info(f"Category folder: {category_folder}")
        
        try:
            category_folder.mkdir(parents=True, exist_ok=True)
        except Exception as e:
            logger.error(f"Failed to create category folder: {e}")
            raise HTTPException(status_code=500, detail=f"Failed to create category folder: {str(e)}")
        
        # Create course folder
        course_folder = category_folder / courseName
        logger.info(f"Course folder: {course_folder}")
        
        # Check if course folder already exists
        if course_folder.exists():
            logger.warning(f"Course folder already exists: {course_folder}")
            raise HTTPException(
                status_code=400, 
                detail=f"Course '{courseName}' already exists in category '{category.name}'"
            )
        
        try:
            course_folder.mkdir(parents=True, exist_ok=True)
        except Exception as e:
            logger.error(f"Failed to create course folder: {e}")
            raise HTTPException(status_code=500, detail=f"Failed to create course folder: {str(e)}")
        
        # Create course in database
        course = Course(
            name=courseName,
            category_id=categoryId,
            path=str(course_folder)
        )
        db.add(course)
        db.flush()  # Get course ID
        
        logger.info(f"Course created in DB with ID: {course.id}")
        
        # Track created files for database
        file_records = []
        folders_created = {}  # Track folder records by path
        
        # First, create all folder records
        directories = set()
        for path in paths:
            path_parts = Path(path).parts
            # Build all intermediate directory paths
            for i in range(1, len(path_parts)):
                dir_path = str(Path(*path_parts[:i]))
                if dir_path not in directories:
                    directories.add(dir_path)
        
        # Sort directories by depth to create parents first
        sorted_dirs = sorted(directories, key=lambda x: len(Path(x).parts))
        
        for dir_path in sorted_dirs:
            path_parts = Path(dir_path).parts
            
            # Find parent ID
            parent_id = None
            if len(path_parts) > 1:
                parent_path = str(Path(*path_parts[:-1]))
                if parent_path in folders_created:
                    parent_id = folders_created[parent_path]
            
            # Create folder on disk
            folder_disk_path = course_folder / dir_path
            try:
                folder_disk_path.mkdir(parents=True, exist_ok=True)
            except Exception as e:
                logger.error(f"Failed to create folder on disk: {folder_disk_path}, Error: {e}")
                raise HTTPException(status_code=500, detail=f"Failed to create folder: {str(e)}")
            
            # Create folder record in DB
            folder_record = FileNode(
                name=path_parts[-1],
                path=str(folder_disk_path),
                course_id=course.id,
                file_type='folder',  # Required field
                is_directory=True,
                parent_id=parent_id
            )
            db.add(folder_record)
            db.flush()
            
            folders_created[dir_path] = folder_record.id
            logger.debug(f"Created folder: {dir_path} with ID: {folder_record.id}")
        
        # Now save all uploaded files
        files_saved = 0
        for upload_file, relative_path in zip(files, paths):
            try:
                # Create full file path
                file_path = course_folder / relative_path
                
                # Create parent directories if needed
                file_path.parent.mkdir(parents=True, exist_ok=True)
                
                # Save file
                with open(file_path, "wb") as f:
                    content = await upload_file.read()
                    f.write(content)
                
                # Determine parent folder
                parent_id = None
                path_parts = Path(relative_path).parts
                
                if len(path_parts) > 1:
                    parent_path = str(Path(*path_parts[:-1]))
                    if parent_path in folders_created:
                        parent_id = folders_created[parent_path]
                
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
                files_saved += 1
                
                if files_saved % 10 == 0:
                    db.flush()  # Periodic flush for large uploads
                    logger.info(f"Saved {files_saved}/{len(files)} files")
                
            except Exception as e:
                logger.error(f"Failed to save file {relative_path}: {e}")
                # Continue with other files
                continue
        
        db.commit()
        logger.info(f"Upload completed. Course ID: {course.id}, Files saved: {files_saved}")
        
        return {
            "courseId": course.id,
            "courseName": courseName,
            "filesUploaded": files_saved,
            "message": f"Successfully uploaded {files_saved} files to course '{courseName}'"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Upload failed with error: {e}", exc_info=True)
        db.rollback()
        
        # Clean up created folder if upload fails
        try:
            if 'course_folder' in locals() and course_folder.exists():
                shutil.rmtree(course_folder)
                logger.info(f"Cleaned up course folder: {course_folder}")
        except Exception as cleanup_error:
            logger.error(f"Failed to clean up folder: {cleanup_error}")
        
        raise HTTPException(
            status_code=500,
            detail=f"Upload failed: {str(e)}"
        )
