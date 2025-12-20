{
  `path`: `C:\\Users\\munawar\\Documents\\Python_LMS_V2\\scripts\test-udemy-course.ps1`,
  `content`: `# Test Scanner on Course with Subdirectories
Write-Host \"============================================\" -ForegroundColor Cyan
Write-Host \"Testing Course with Subdirectories...\" -ForegroundColor Cyan
Write-Host \"============================================\" -ForegroundColor Cyan

cd C:\\Users\\munawar\\Documents\\Python_LMS_V2\\backend

$testScript = @'
import os
from pathlib import Path
from app.db.database import SessionLocal
from app.models import Course, FileNode

db = SessionLocal()
try:
    # Get Udemy course (ID: 16)
    course = db.query(Course).filter(Course.id == 16).first()
    if not course:
        print(\"Course not found\")
        exit(0)
    
    print(f\"\
Course: {course.name}\")
    print(f\"Course Path: {course.path}\")
    
    normalized_course_path = os.path.normpath(course.path)
    
    print(\"\
=== DIRECTORY STRUCTURE ===\")
    for root, dirs, files in os.walk(course.path):
        normalized_root = os.path.normpath(root)
        level = normalized_root.replace(normalized_course_path, '').count(os.sep)
        indent = '  ' * level
        
        print(f\"{indent}{os.path.basename(root)}/\")
        
        sub_indent = '  ' * (level + 1)
        for d in dirs:
            print(f\"{sub_indent}[DIR] {d}/\")
        
        for f in files[:2]:  # Show first 2 files
            print(f\"{sub_indent}[FILE] {f}\")
        
        if len(files) > 2:
            print(f\"{sub_indent}... and {len(files) - 2} more files\")
    
    print(\"\
=== FILES IN DATABASE FOR THIS COURSE ===\")
    files_in_db = db.query(FileNode).filter(FileNode.course_id == course.id).all()
    print(f\"Total: {len(files_in_db)}\")
    
    folders = [f for f in files_in_db if f.is_directory]
    print(f\"\
Folders ({len(folders)}):\")
    for folder in folders:
        print(f\"  {folder.name} (ID: {folder.id}, parent_id: {folder.parent_id})\")
    
    files = [f for f in files_in_db if not f.is_directory]
    print(f\"\
Files ({len(files)}):\")
    for file in files[:5]:
        parent_name = \"ROOT\"
        if file.parent_id:
            parent = db.query(FileNode).filter(FileNode.id == file.parent_id).first()
            parent_name = parent.name if parent else f\"ID:{file.parent_id}\"
        print(f\"  {file.name} → {parent_name}\")
    
finally:
    db.close()
'@

$testScript | python

Write-Host \"`n============================================\" -ForegroundColor Cyan
`
}
