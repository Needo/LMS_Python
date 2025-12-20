# Clear Database and Rescan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Clearing Old Data and Rescanning..." -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

cd C:\Users\munawar\Documents\Python_LMS_V2\backend

$clearScript = @'
from app.db.database import SessionLocal
from app.models import Category, Course, FileNode

db = SessionLocal()
try:
    # Delete all file nodes
    deleted_files = db.query(FileNode).delete()
    print(f"Deleted {deleted_files} file nodes")
    
    # Delete all courses
    deleted_courses = db.query(Course).delete()
    print(f"Deleted {deleted_courses} courses")
    
    # Delete all categories
    deleted_categories = db.query(Category).delete()
    print(f"Deleted {deleted_categories} categories")
    
    db.commit()
    print("\n✓ Database cleaned successfully")
    
except Exception as e:
    print(f"✗ Error: {e}")
    db.rollback()
finally:
    db.close()
'@

Write-Host "`nClearing old data from database..." -ForegroundColor Yellow
$clearScript | python

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "Database Cleared!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "`nNow go to Admin Panel and click 'Scan Folder' again" -ForegroundColor Yellow
Write-Host "Your structure should now show correctly:" -ForegroundColor Yellow
Write-Host "  Books (Category)" -ForegroundColor White
Write-Host "    └── Books 2025 (Course)" -ForegroundColor White
Write-Host "  Courses (Category)" -ForegroundColor White
Write-Host "    ├── Sample Course 1 (Course)" -ForegroundColor White
Write-Host "    ├── Sample Course 2 (Course)" -ForegroundColor White
Write-Host "    └── Udemy - Cursor AI (Course)" -ForegroundColor White
