"""
Unified search service for courses and files
"""
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_, func
from app.models.user import User
from app.models.course import Course
from app.models.file_node import FileNode
from app.models.search import SearchLog
from app.services.authorization_service import AuthorizationService
from typing import List, Dict, Any
from datetime import datetime

class SearchService:
    """Unified search across courses and files"""
    
    def __init__(self, db: Session):
        self.db = db
        self.auth_service = AuthorizationService(db)
    
    def search_all(
        self,
        query: str,
        user: User,
        limit: int = 50
    ) -> Dict[str, Any]:
        """
        Search across courses and files
        
        Returns:
            {
                'courses': [...],
                'files': [...],
                'total': N
            }
        """
        courses = self.search_courses(query, user, limit)
        files = self.search_files(query, user, limit)
        
        total = len(courses) + len(files)
        
        # Log search
        self._log_search(user.id, query, total, 'all')
        
        return {
            'courses': courses,
            'files': files,
            'total': total,
            'query': query
        }
    
    def search_courses(
        self,
        query: str,
        user: User,
        limit: int = 20
    ) -> List[Dict[str, Any]]:
        """
        Search courses by name
        User only sees enrolled courses (unless admin)
        """
        query_lower = f"%{query.lower()}%"
        
        # Get accessible courses
        accessible_courses = self.auth_service.get_accessible_courses(user)
        course_ids = [c.id for c in accessible_courses]
        
        if not course_ids:
            return []
        
        # Search in accessible courses
        results = self.db.query(Course).filter(
            and_(
                Course.id.in_(course_ids),
                func.lower(Course.name).like(query_lower)
            )
        ).order_by(Course.name).limit(limit).all()
        
        return [
            {
                'id': course.id,
                'name': course.name,
                'category_id': course.category_id,
                'type': 'course',
                'icon': 'school'
            }
            for course in results
        ]
    
    def search_files(
        self,
        query: str,
        user: User,
        limit: int = 30,
        file_type: str = None
    ) -> List[Dict[str, Any]]:
        """
        Search files by name and path
        User only sees files in enrolled courses (unless admin)
        """
        query_lower = f"%{query.lower()}%"
        
        # Get accessible course IDs
        accessible_courses = self.auth_service.get_accessible_courses(user)
        course_ids = [c.id for c in accessible_courses]
        
        if not course_ids:
            return []
        
        # Build query
        file_query = self.db.query(FileNode).filter(
            and_(
                FileNode.course_id.in_(course_ids),
                FileNode.is_directory == False,  # Only files, not folders
                or_(
                    func.lower(FileNode.name).like(query_lower),
                    func.lower(FileNode.path).like(query_lower)
                )
            )
        )
        
        # Filter by file type if specified
        if file_type:
            file_query = file_query.filter(
                func.lower(FileNode.name).like(f"%.{file_type.lower()}")
            )
        
        results = file_query.order_by(FileNode.name).limit(limit).all()
        
        return [
            {
                'id': file.id,
                'name': file.name,
                'path': file.path,
                'course_id': file.course_id,
                'file_type': self._get_file_type(file.name),
                'file_size': file.size,
                'type': 'file',
                'icon': self._get_file_icon(file.name)
            }
            for file in results
        ]
    
    def search_by_type(
        self,
        query: str,
        user: User,
        search_type: str,
        limit: int = 50
    ) -> List[Dict[str, Any]]:
        """
        Search by specific type
        search_type: 'courses', 'files', 'pdf', 'video', 'document'
        """
        if search_type == 'courses':
            results = self.search_courses(query, user, limit)
        elif search_type == 'files':
            results = self.search_files(query, user, limit)
        elif search_type in ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'mp4', 'avi', 'mp3']:
            results = self.search_files(query, user, limit, file_type=search_type)
        else:
            results = []
        
        # Log search
        self._log_search(user.id, query, len(results), search_type)
        
        return results
    
    def get_popular_searches(self, limit: int = 10) -> List[Dict[str, Any]]:
        """Get most popular search queries"""
        results = self.db.query(
            SearchLog.query,
            func.count(SearchLog.id).label('count')
        ).group_by(
            SearchLog.query
        ).order_by(
            func.count(SearchLog.id).desc()
        ).limit(limit).all()
        
        return [
            {'query': r.query, 'count': r.count}
            for r in results
        ]
    
    def get_recent_searches(self, user_id: int, limit: int = 5) -> List[str]:
        """Get user's recent search queries"""
        results = self.db.query(SearchLog).filter(
            SearchLog.user_id == user_id
        ).order_by(
            SearchLog.created_at.desc()
        ).limit(limit).all()
        
        return [r.query for r in results]
    
    def _get_file_type(self, filename: str) -> str:
        """Get file type from filename"""
        if '.' not in filename:
            return 'unknown'
        
        ext = filename.rsplit('.', 1)[1].lower()
        
        # Map extensions to types
        type_map = {
            'pdf': 'pdf',
            'doc': 'document',
            'docx': 'document',
            'txt': 'text',
            'ppt': 'presentation',
            'pptx': 'presentation',
            'xls': 'spreadsheet',
            'xlsx': 'spreadsheet',
            'mp4': 'video',
            'avi': 'video',
            'mov': 'video',
            'mp3': 'audio',
            'wav': 'audio',
            'jpg': 'image',
            'jpeg': 'image',
            'png': 'image',
            'gif': 'image',
            'zip': 'archive',
            'rar': 'archive',
            'py': 'code',
            'js': 'code',
            'java': 'code',
            'cpp': 'code',
        }
        
        return type_map.get(ext, 'file')
    
    def _get_file_icon(self, filename: str) -> str:
        """Get Material icon for file type"""
        file_type = self._get_file_type(filename)
        
        icon_map = {
            'pdf': 'picture_as_pdf',
            'document': 'description',
            'text': 'article',
            'presentation': 'slideshow',
            'spreadsheet': 'table_chart',
            'video': 'movie',
            'audio': 'audiotrack',
            'image': 'image',
            'archive': 'folder_zip',
            'code': 'code',
            'file': 'insert_drive_file'
        }
        
        return icon_map.get(file_type, 'insert_drive_file')
    
    def _log_search(self, user_id: int, query: str, results_count: int, search_type: str):
        """Log search query for analytics"""
        try:
            log = SearchLog(
                user_id=user_id,
                query=query,
                results_count=results_count,
                search_type=search_type
            )
            self.db.add(log)
            self.db.commit()
        except Exception as e:
            print(f"Failed to log search: {e}")
            self.db.rollback()
