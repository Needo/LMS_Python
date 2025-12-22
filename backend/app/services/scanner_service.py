import os
from pathlib import Path
from typing import List, Dict, Set
from sqlalchemy.orm import Session
from app.models import Category, Course, FileNode, Settings as SettingsModel
from app.schemas import ScanResult
from app.core.security_utils import SecurityValidator, is_safe_path
from app.core.config import settings

class ScannerService:
    # Default categories
    DEFAULT_CATEGORIES = ["Courses", "Books", "Novels", "Pictures"]
    
    # File extensions mapping
    FILE_TYPE_MAP = {
        '.pdf': 'pdf',
        '.mp4': 'video', '.avi': 'video', '.mkv': 'video', '.mov': 'video', '.webm': 'video',
        '.mp3': 'audio', '.wav': 'audio', '.ogg': 'audio', '.m4a': 'audio',
        '.jpg': 'image', '.jpeg': 'image', '.png': 'image', '.gif': 'image', '.bmp': 'image', '.webp': 'image',
        '.txt': 'text', '.md': 'text', '.log': 'text',
        '.epub': 'epub'
    }

    def __init__(self, db: Session):
        self.db = db

    def scan_root_folder(self, root_path: str) -> ScanResult:
        """
        Scan the root folder and populate database with categories, courses, and files.
        """
        if not os.path.exists(root_path):
            return ScanResult(
                success=False,
                message="Root path does not exist",
                categories_found=0,
                courses_found=0,
                files_added=0,
                files_removed=0,
                files_updated=0
            )

        try:
            categories_found = 0
            courses_found = 0
            files_added = 0
            files_removed = 0
            files_updated = 0

            # Get all directories in root (these are categories)
            category_dirs = [d for d in os.listdir(root_path) 
                           if os.path.isdir(os.path.join(root_path, d))]

            # Process each category
            for category_name in category_dirs:
                category_path = os.path.join(root_path, category_name)
                
                # Get or create category
                category = self.db.query(Category).filter(
                    Category.name == category_name
                ).first()
                
                if not category:
                    category = Category(name=category_name, path=category_path)
                    self.db.add(category)
                    self.db.flush()
                    categories_found += 1

                # Get all course directories in this category
                course_dirs = [d for d in os.listdir(category_path) 
                             if os.path.isdir(os.path.join(category_path, d))]

                for course_name in course_dirs:
                    course_path = os.path.join(category_path, course_name)
                    
                    # Get or create course
                    course = self.db.query(Course).filter(
                        Course.category_id == category.id,
                        Course.name == course_name
                    ).first()
                    
                    if not course:
                        course = Course(
                            category_id=category.id,
                            name=course_name,
                            path=course_path
                        )
                        self.db.add(course)
                        self.db.flush()
                        courses_found += 1

                    # Scan files in course
                    result = self._scan_course_files(course, course_path)
                    files_added += result['added']
                    files_removed += result['removed']
                    files_updated += result['updated']

            self.db.commit()

            return ScanResult(
                success=True,
                message="Scan completed successfully",
                categories_found=categories_found,
                courses_found=courses_found,
                files_added=files_added,
                files_removed=files_removed,
                files_updated=files_updated
            )

        except Exception as e:
            self.db.rollback()
            return ScanResult(
                success=False,
                message=f"Error during scan: {str(e)}",
                categories_found=0,
                courses_found=0,
                files_added=0,
                files_removed=0,
                files_updated=0
            )

    def _scan_course_files(self, course: Course, course_path: str) -> Dict[str, int]:
        """
        Scan all files in a course directory recursively.
        """
        added = 0
        removed = 0
        updated = 0

        # Get existing files from database
        existing_files = self.db.query(FileNode).filter(
            FileNode.course_id == course.id
        ).all()
        
        existing_paths = {f.path: f for f in existing_files}
        scanned_paths: Set[str] = set()
        
        # Normalize course path
        normalized_course_path = os.path.normpath(course_path)
        
        # Create a map to track newly created folders by path
        new_folders_map: Dict[str, FileNode] = {}

        # FIRST PASS: Scan and create all directories
        for root, dirs, files in os.walk(course_path):
            normalized_root = os.path.normpath(root)
            
            for dir_name in dirs:
                dir_path = os.path.join(root, dir_name)
                normalized_dir_path = os.path.normpath(dir_path)
                scanned_paths.add(normalized_dir_path)
                
                if normalized_dir_path not in existing_paths:
                    parent_id = None
                    
                    if normalized_root != normalized_course_path:
                        # Try to find parent in existing files
                        if normalized_root in existing_paths:
                            parent_id = existing_paths[normalized_root].id
                        # Try to find parent in newly created folders
                        elif normalized_root in new_folders_map:
                            parent_id = new_folders_map[normalized_root].id
                        else:
                            print(f"WARNING: Parent not found for {dir_name} at {normalized_root}")
                    
                    file_node = FileNode(
                        course_id=course.id,
                        name=dir_name,
                        path=normalized_dir_path,
                        file_type='folder',
                        parent_id=parent_id,
                        is_directory=True
                    )
                    self.db.add(file_node)
                    self.db.flush()  # Flush immediately to get ID
                    
                    # Store in our map for parent lookup
                    new_folders_map[normalized_dir_path] = file_node
                    added += 1

        # SECOND PASS: Scan and create all files
        for root, dirs, files in os.walk(course_path):
            normalized_root = os.path.normpath(root)
            
            for file_name in files:
                file_path = os.path.join(root, file_name)
                normalized_file_path = os.path.normpath(file_path)
                
                # Security validation
                # 1. Path traversal check
                if not is_safe_path(normalized_file_path, course_path):
                    print(f"SECURITY: Skipping file outside course path: {file_name}")
                    continue
                
                # 2. Extension validation
                is_valid_ext, ext_error = SecurityValidator.validate_extension(file_name)
                if not is_valid_ext:
                    print(f"SECURITY: Skipping file with invalid extension: {file_name}")
                    continue
                
                # 3. File size validation
                is_valid_size, size_error = SecurityValidator.validate_file_size(file_path)
                if not is_valid_size:
                    print(f"SECURITY: Skipping oversized file: {file_name}")
                    continue
                
                scanned_paths.add(normalized_file_path)
                
                if normalized_file_path not in existing_paths:
                    parent_id = None
                    
                    if normalized_root != normalized_course_path:
                        # Try existing files first
                        if normalized_root in existing_paths:
                            parent_id = existing_paths[normalized_root].id
                        # Try newly created folders
                        elif normalized_root in new_folders_map:
                            parent_id = new_folders_map[normalized_root].id
                        else:
                            print(f"WARNING: Parent not found for {file_name} at {normalized_root}")
                    
                    file_type = self._get_file_type(file_name)
                    file_size = os.path.getsize(file_path)
                    
                    file_node = FileNode(
                        course_id=course.id,
                        name=file_name,
                        path=normalized_file_path,
                        file_type=file_type,
                        parent_id=parent_id,
                        is_directory=False,
                        size=file_size
                    )
                    self.db.add(file_node)
                    added += 1
                else:
                    # Check if file was modified
                    existing_file = existing_paths[normalized_file_path]
                    new_size = os.path.getsize(file_path)
                    if existing_file.size != new_size:
                        existing_file.size = new_size
                        updated += 1

        # Remove files that no longer exist
        for path, file_node in existing_paths.items():
            if path not in scanned_paths:
                self.db.delete(file_node)
                removed += 1

        return {
            'added': added,
            'removed': removed,
            'updated': updated
        }

    def _get_file_type(self, filename: str) -> str:
        """
        Determine file type based on extension.
        """
        ext = Path(filename).suffix.lower()
        return self.FILE_TYPE_MAP.get(ext, 'unknown')

    def get_root_path(self) -> str:
        """
        Get the configured root path from database.
        """
        setting = self.db.query(SettingsModel).filter(
            SettingsModel.key == 'root_path'
        ).first()
        
        return setting.value if setting else None

    def set_root_path(self, root_path: str) -> bool:
        """
        Set the root path in database.
        """
        try:
            setting = self.db.query(SettingsModel).filter(
                SettingsModel.key == 'root_path'
            ).first()
            
            if setting:
                setting.value = root_path
            else:
                setting = SettingsModel(key='root_path', value=root_path)
                self.db.add(setting)
            
            self.db.commit()
            return True
        except Exception as e:
            self.db.rollback()
            print(f"Error setting root path: {e}")
            return False