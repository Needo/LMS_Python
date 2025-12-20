# Check File Nodes and Parent IDs
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Checking File Nodes Parent IDs..." -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

cd C:\Users\munawar\Documents\Python_LMS_V2\backend

$checkScript = @'
import sys
from app.db.database import SessionLocal
from app.models import FileNode, Course

db = SessionLocal()
try:
    # Get a sample course
    course = db.query(Course).first()
    if not course:
        print("No courses found")
        sys.exit(0)
    
    print(f"\n=== FILES IN COURSE: {course.name} ===")
    
    files = db.query(FileNode).filter(FileNode.course_id == course.id).all()
    print(f"Total files/folders: {len(files)}")
    
    print("\n=== ROOT LEVEL (parent_id = None) ===")
    root_files = [f for f in files if f.parent_id is None]
    print(f"Count: {len(root_files)}")
    for f in root_files[:10]:
        type_icon = "📁" if f.is_directory else "📄"
        print(f"  {type_icon} {f.name} (ID: {f.id})")
    
    print("\n=== WITH PARENTS (parent_id != None) ===")
    child_files = [f for f in files if f.parent_id is not None]
    print(f"Count: {len(child_files)}")
    for f in child_files[:10]:
        parent = db.query(FileNode).filter(FileNode.id == f.parent_id).first()
        type_icon = "📁" if f.is_directory else "📄"
        parent_name = parent.name if parent else "NOT FOUND"
        print(f"  {type_icon} {f.name} → Parent: {parent_name} (parent_id: {f.parent_id})")
    
    print("\n=== CHECKING PATHS ===")
    for f in files[:5]:
        print(f"\nName: {f.name}")
        print(f"Path: {f.path}")
        print(f"Parent ID: {f.parent_id}")
        if f.parent_id:
            parent = db.query(FileNode).filter(FileNode.id == f.parent_id).first()
            if parent:
                print(f"Parent Path: {parent.path}")
            else:
                print(f"ERROR: Parent ID {f.parent_id} not found in database!")
    
finally:
    db.close()
'@

$checkScript | python

Write-Host "`n============================================" -ForegroundColor Cyan
