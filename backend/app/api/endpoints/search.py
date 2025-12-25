"""
Search API endpoints
"""
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from app.db.database import get_db
from app.models.user import User
from app.core.dependencies import get_current_user
from app.services.search_service import SearchService

router = APIRouter()

@router.get("/")
def search_all(
    q: str = Query(..., min_length=1, description="Search query"),
    limit: int = Query(50, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Unified search across courses and files
    """
    search_service = SearchService(db)
    results = search_service.search_all(q, current_user, limit)
    
    return results

@router.get("/courses")
def search_courses(
    q: str = Query(..., min_length=1),
    limit: int = Query(20, ge=1, le=50),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Search courses only
    """
    search_service = SearchService(db)
    results = search_service.search_courses(q, current_user, limit)
    
    return {
        'results': results,
        'total': len(results),
        'query': q
    }

@router.get("/files")
def search_files(
    q: str = Query(..., min_length=1),
    file_type: Optional[str] = None,
    limit: int = Query(30, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Search files only
    Optional file_type filter: pdf, doc, video, etc.
    """
    search_service = SearchService(db)
    results = search_service.search_files(q, current_user, limit, file_type)
    
    return {
        'results': results,
        'total': len(results),
        'query': q,
        'file_type': file_type
    }

@router.get("/popular")
def get_popular_searches(
    limit: int = Query(10, ge=1, le=20),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get most popular search queries
    """
    search_service = SearchService(db)
    results = search_service.get_popular_searches(limit)
    
    return {'popular_searches': results}

@router.get("/recent")
def get_recent_searches(
    limit: int = Query(5, ge=1, le=10),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get user's recent search queries
    """
    search_service = SearchService(db)
    results = search_service.get_recent_searches(current_user.id, limit)
    
    return {'recent_searches': results}
