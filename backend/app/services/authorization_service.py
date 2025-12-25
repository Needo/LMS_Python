"""
Authorization service for course access control
"""
from sqlalchemy.orm import Session
from app.models.user import User
from app.models.enrollment import Enrollment
from app.models.course import Course
from app.models.category import Category
from app.models.file_node import FileNode
from typing import List, Optional

class AuthorizationService:
    """
    Centralized authorization logic
    
    Rules:
    - Admin can access everything
    - Regular users can only access enrolled courses and their files
    """
    
    def __init__(self, db: Session):
        self.db = db
    
    def can_access_course(self, user: User, course_id: int) -> bool:
        """
        Check if user can access a course
        
        Returns:
            True if user is admin or enrolled in course
        """
        # Admin can access everything
        if user.is_admin:
            return True
        
        # Check enrollment
        enrollment = self.db.query(Enrollment).filter(
            Enrollment.user_id == user.id,
            Enrollment.course_id == course_id
        ).first()
        
        return enrollment is not None
    
    def can_access_file(self, user: User, file_id: int) -> bool:
        """
        Check if user can access a file
        
        Returns:
            True if user is admin or enrolled in file's course
        """
        # Admin can access everything
        if user.is_admin:
            return True
        
        # Get file's course
        file_node = self.db.query(FileNode).filter(FileNode.id == file_id).first()
        if not file_node:
            return False
        
        # Check enrollment in file's course
        return self.can_access_course(user, file_node.course_id)
    
    def can_access_category(self, user: User, category_id: int) -> bool:
        """
        Check if user can access a category
        
        Returns:
            True if user is admin or enrolled in at least one course in category
        """
        # Admin can access everything
        if user.is_admin:
            return True
        
        # Check if user is enrolled in any course in this category
        enrolled_in_category = self.db.query(Enrollment).join(
            Course, Enrollment.course_id == Course.id
        ).filter(
            Course.category_id == category_id,
            Enrollment.user_id == user.id
        ).first()
        
        return enrolled_in_category is not None
    
    def get_enrolled_course_ids(self, user: User) -> List[int]:
        """
        Get list of course IDs user is enrolled in
        
        Returns:
            List of course IDs (empty list for admin = all courses)
        """
        # Admin gets all courses
        if user.is_admin:
            all_courses = self.db.query(Course.id).all()
            return [c.id for c in all_courses]
        
        # Regular user gets enrolled courses
        enrollments = self.db.query(Enrollment.course_id).filter(
            Enrollment.user_id == user.id
        ).all()
        
        return [e.course_id for e in enrollments]
    
    def get_accessible_categories(self, user: User) -> List[Category]:
        """
        Get categories user can access
        
        Returns:
            List of categories with at least one enrolled course (all for admin)
        """
        # Admin gets all categories
        if user.is_admin:
            return self.db.query(Category).order_by(Category.name).all()
        
        # Optimized query with JOIN and DISTINCT
        # Prevents N+1 queries by loading categories with enrollments in one go
        categories = self.db.query(Category).join(
            Course, Category.id == Course.category_id
        ).join(
            Enrollment, Course.id == Enrollment.course_id
        ).filter(
            Enrollment.user_id == user.id
        ).distinct().order_by(Category.name).all()
        
        return categories
    
    def get_accessible_courses(self, user: User, category_id: Optional[int] = None) -> List[Course]:
        """
        Get courses user can access
        
        Args:
            category_id: Optional filter by category
            
        Returns:
            List of accessible courses
        """
        # Admin gets all courses
        if user.is_admin:
            query = self.db.query(Course).order_by(Course.name)
            if category_id:
                query = query.filter(Course.category_id == category_id)
            return query.all()
        
        # Optimized query for regular users
        # Single query with JOIN instead of separate queries per course
        query = self.db.query(Course).join(
            Enrollment, Course.id == Enrollment.course_id
        ).filter(
            Enrollment.user_id == user.id
        ).order_by(Course.name)
        
        if category_id:
            query = query.filter(Course.category_id == category_id)
        
        return query.all()
    
    def enroll_user(self, user_id: int, course_id: int, role: str = "student") -> Enrollment:
        """
        Enroll user in a course
        
        Args:
            user_id: User ID
            course_id: Course ID
            role: Enrollment role (student, instructor, ta)
            
        Returns:
            Enrollment object
            
        Raises:
            ValueError if already enrolled
        """
        # Check if already enrolled
        existing = self.db.query(Enrollment).filter(
            Enrollment.user_id == user_id,
            Enrollment.course_id == course_id
        ).first()
        
        if existing:
            raise ValueError("User already enrolled in this course")
        
        # Create enrollment
        enrollment = Enrollment(
            user_id=user_id,
            course_id=course_id,
            role=role
        )
        
        self.db.add(enrollment)
        self.db.commit()
        self.db.refresh(enrollment)
        
        return enrollment
    
    def unenroll_user(self, user_id: int, course_id: int) -> bool:
        """
        Unenroll user from a course
        
        Returns:
            True if enrollment was removed
        """
        enrollment = self.db.query(Enrollment).filter(
            Enrollment.user_id == user_id,
            Enrollment.course_id == course_id
        ).first()
        
        if enrollment:
            self.db.delete(enrollment)
            self.db.commit()
            return True
        
        return False
