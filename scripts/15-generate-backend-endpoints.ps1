# Script 15: Generate Backend API Endpoints (Part 1)
# This script generates API endpoints for auth, categories, courses

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Generating API Endpoints (Part 1)..." -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

$rootPath = "C:\Users\munawar\Documents\Python_LMS_V2"
$backendPath = Join-Path $rootPath "backend"

# Function to create file with content
function Create-File {
    param (
        [string]$Path,
        [string]$Content
    )
    $directory = Split-Path $Path -Parent
    if (-not (Test-Path $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    Set-Content -Path $Path -Value $Content -Encoding UTF8
    Write-Host "Created: $Path" -ForegroundColor Green
}

Write-Host "`n1. Creating Auth Endpoint..." -ForegroundColor Yellow

$authEndpointContent = @'
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.schemas import UserCreate, UserLogin, Token, User
from app.services import AuthService

router = APIRouter()

@router.post("/register", response_model=User, status_code=status.HTTP_201_CREATED)
def register(user_data: UserCreate, db: Session = Depends(get_db)):
    """
    Register a new user.
    """
    auth_service = AuthService(db)
    return auth_service.register_user(user_data)

@router.post("/login", response_model=Token)
def login(login_data: UserLogin, db: Session = Depends(get_db)):
    """
    Login and get access token.
    """
    auth_service = AuthService(db)
    return auth_service.authenticate_user(login_data)
'@

Create-File -Path (Join-Path $backendPath "app\api\endpoints\auth.py") -Content $authEndpointContent

Write-Host "`n2. Creating Categories Endpoint..." -ForegroundColor Yellow

$categoriesEndpointContent = @'
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app.db.database import get_db
from app.models import Category as CategoryModel, User
from app.schemas import Category
from app.core.dependencies import get_current_user

router = APIRouter()

@router.get("/", response_model=List[Category])
def get_categories(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get all categories.
    """
    categories = db.query(CategoryModel).all()
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
'@

Create-File -Path (Join-Path $backendPath "app\api\endpoints\categories.py") -Content $categoriesEndpointContent

Write-Host "`n3. Creating Courses Endpoint..." -ForegroundColor Yellow

$coursesEndpointContent = @'
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app.db.database import get_db
from app.models import Course as CourseModel, User
from app.schemas import Course
from app.core.dependencies import get_current_user

router = APIRouter()

@router.get("/", response_model=List[Course])
def get_all_courses(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get all courses.
    """
    courses = db.query(CourseModel).all()
    return courses

@router.get("/category/{category_id}", response_model=List[Course])
def get_courses_by_category(
    category_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get all courses in a specific category.
    """
    courses = db.query(CourseModel).filter(
        CourseModel.category_id == category_id
    ).all()
    return courses

@router.get("/{course_id}", response_model=Course)
def get_course(
    course_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get a specific course by ID.
    """
    course = db.query(CourseModel).filter(CourseModel.id == course_id).first()
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    return course
'@

Create-File -Path (Join-Path $backendPath "app\api\endpoints\courses.py") -Content $coursesEndpointContent

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "API Endpoints (Part 1) Created!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "`nNext step: Run 16-generate-backend-endpoints-2.ps1" -ForegroundColor Yellow
