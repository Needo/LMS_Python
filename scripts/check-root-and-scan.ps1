# Check Root Path and Scan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Checking Root Path Configuration..." -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

cd C:\Users\munawar\Documents\Python_LMS_V2\backend

$checkScript = @'
from app.db.database import SessionLocal
from app.models import Settings, Category, Course, FileNode

db = SessionLocal()
try:
    # Check root path
    setting = db.query(Settings).filter(Settings.key == "root_path").first()
    if setting:
        print(f"\nRoot Path: {setting.value}")
        
        import os
        if os.path.exists(setting.value):
            print(f"✓ Path exists")
            
            # List what's in the root
            items = os.listdir(setting.value)
            print(f"\nItems in root ({len(items)}):")
            for item in items:
                full_path = os.path.join(setting.value, item)
                if os.path.isdir(full_path):
                    print(f"  [DIR]  {item}")
                else:
                    print(f"  [FILE] {item}")
        else:
            print(f"✗ Path does NOT exist!")
    else:
        print("\n✗ No root path configured in settings table")
    
    # Check categories
    categories = db.query(Category).all()
    print(f"\n=== CATEGORIES IN DB ({len(categories)}) ===")
    for cat in categories:
        print(f"  - {cat.name} (ID: {cat.id})")
    
    # Check courses
    courses = db.query(Course).all()
    print(f"\n=== COURSES IN DB ({len(courses)}) ===")
    for course in courses:
        print(f"  - {course.name} (ID: {course.id}, Category ID: {course.category_id})")
    
    # Check files
    files = db.query(FileNode).all()
    print(f"\n=== FILES IN DB ({len(files)}) ===")
    if len(files) > 0:
        print(f"Total: {len(files)}")
        for f in files[:5]:
            print(f"  - {f.name} (parent_id: {f.parent_id})")
    else:
        print("  (none)")
    
finally:
    db.close()
'@

$checkScript | python

Write-Host "`n============================================" -ForegroundColor Cyan
