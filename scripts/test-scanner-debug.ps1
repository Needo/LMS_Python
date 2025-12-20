# Test Scanner Manually with Debug Output
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Testing Scanner with Debug Output..." -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

cd C:\Users\munawar\Documents\Python_LMS_V2\backend

$testScript = @'
import os
from pathlib import Path
from app.db.database import SessionLocal
from app.models import Course, FileNode

db = SessionLocal()
try:
    # Get first course
    course = db.query(Course).first()
    if not course:
        print("No courses found")
        exit(0)
    
    print(f"\nCourse: {course.name}")
    print(f"Course Path: {course.path}")
    print(f"Course ID: {course.id}")
    
    normalized_course_path = os.path.normpath(course.path)
    print(f"Normalized Course Path: {normalized_course_path}")
    
    print("\n=== WALKING DIRECTORY ===")
    for root, dirs, files in os.walk(course.path):
        normalized_root = os.path.normpath(root)
        print(f"\nRoot: {root}")
        print(f"Normalized Root: {normalized_root}")
        print(f"Is root == course path? {normalized_root == normalized_course_path}")
        
        if dirs:
            print(f"  Directories ({len(dirs)}):")
            for d in dirs[:3]:
                print(f"    - {d}")
        
        if files:
            print(f"  Files ({len(files)}):")
            for f in files[:3]:
                print(f"    - {f}")
        
        # Test parent lookup
        if normalized_root != normalized_course_path:
            print(f"\n  Looking for parent folder in DB...")
            print(f"  Query: course_id={course.id}, path={normalized_root}, is_directory=True")
            
            parent = db.query(FileNode).filter(
                FileNode.course_id == course.id,
                FileNode.path == normalized_root,
                FileNode.is_directory == True
            ).first()
            
            if parent:
                print(f"  ✓ Found parent: {parent.name} (ID: {parent.id})")
            else:
                print(f"  ✗ Parent NOT found in database")
                
                # Check if ANY folder with this path exists
                any_folder = db.query(FileNode).filter(
                    FileNode.path == normalized_root
                ).first()
                
                if any_folder:
                    print(f"    But found folder: {any_folder.name} (course_id={any_folder.course_id}, is_dir={any_folder.is_directory})")
                else:
                    print(f"    No folder at all with path: {normalized_root}")
        
        break  # Only check first level
    
finally:
    db.close()
'@

$testScript | python

Write-Host "`n============================================" -ForegroundColor Cyan
