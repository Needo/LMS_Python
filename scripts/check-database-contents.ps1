# Check Database Contents After Scan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Checking Database Contents..." -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

cd C:\Users\munawar\Documents\Python_LMS_V2\backend

$checkScript = @'
import sys
from app.db.database import SessionLocal
from app.models import Category, Course, FileNode, Settings

db = SessionLocal()
try:
    # Check settings
    settings = db.query(Settings).filter(Settings.key == "root_path").first()
    print("\n=== ROOT PATH ===")
    if settings:
        print(f"Root Path: {settings.value}")
    else:
        print("No root path configured")
    
    # Check categories
    categories = db.query(Category).all()
    print(f"\n=== CATEGORIES ({len(categories)}) ===")
    for cat in categories:
        print(f"  - {cat.name} (ID: {cat.id})")
    
    # Check courses
    courses = db.query(Course).all()
    print(f"\n=== COURSES ({len(courses)}) ===")
    for course in courses:
        cat = db.query(Category).filter(Category.id == course.category_id).first()
        print(f"  - {course.name} (Category: {cat.name if cat else 'Unknown'})")
    
    # Check files
    files = db.query(FileNode).all()
    print(f"\n=== FILES ({len(files)}) ===")
    if len(files) > 0:
        print(f"Total files in database: {len(files)}")
        print("\nFirst 10 files:")
        for file in files[:10]:
            type_icon = "📁" if file.is_directory else "📄"
            print(f"  {type_icon} {file.name} ({file.file_type})")
    else:
        print("No files found in database")
    
    # Check by course
    print("\n=== FILES BY COURSE ===")
    for course in courses:
        file_count = db.query(FileNode).filter(FileNode.course_id == course.id).count()
        print(f"  {course.name}: {file_count} files")
    
finally:
    db.close()
'@

$checkScript | python

Write-Host "`n============================================" -ForegroundColor Cyan
