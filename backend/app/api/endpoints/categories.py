from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app.db.database import get_db
from app.models import Category as CategoryModel, User
from app.schemas import Category
from app.core.dependencies import get_current_user
from app.core.authorization import get_auth_service
from app.services.authorization_service import AuthorizationService
from app.core.cache import cached

router = APIRouter()

@router.get("/", response_model=List[Category])
@cached(ttl_seconds=300, key_prefix="categories")  # Cache for 5 minutes
def get_categories(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
    auth_service: AuthorizationService = Depends(get_auth_service)
):
    """
    Get categories accessible to current user.
    Admin sees all, regular users see only categories with enrolled courses.
    Cached for 5 minutes.
    """
    categories = auth_service.get_accessible_categories(current_user)
    return categories

@router.get("/{category_id}", response_model=Category)
def get_category(
    category_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get a specific category by ID.
    """
    category = db.query(CategoryModel).filter(CategoryModel.id == category_id).first()
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")
    return category
