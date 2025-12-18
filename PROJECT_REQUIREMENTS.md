# Learning Management System - Project Requirements

## Session Date: December 16, 2025

## Project Overview
Building a Learning Management System with file system scanner, multi-format viewer, and user progress tracking.

## Tech Stack
- **Frontend**: Angular 19 (standalone components) + Angular Material
- **Backend**: Python FastAPI (latest version)
- **Database**: PostgreSQL (15 or later)

## Project Structure
```
Python_LMS_Advance/
├── frontend/          # Angular application
└── backend/           # Python FastAPI application
```

## Key Requirements

### 1. Admin Section
- Setup root folder functionality
- Button to scan root folder
- File system scanner that reads and indexes files

### 2. File System Structure & Categories
- Default categories (as root folders):
  1. Courses
  2. Books
  3. Novels
  4. Pictures
- Each root folder under category = a course
- All subfolders and files = course contents
- **Important**: Retain file system structure in database
- **Dynamic**: New root folders automatically become new categories

### 3. Scanner Features
- Efficient rescan capability
- Detect and delete removed files
- Detect and add new files
- Compare against existing database entries

### 4. Client Panel Layout
- **Left Panel**: TreeView showing:
  - All categories
  - All courses/subfolders under each category
  - File type icons (pdf, jpg, video, audio, txt, epub)
- **Right Panel**: Multi-format viewer supporting:
  - Text files (.txt)
  - Videos
  - Audio
  - PDF files
  - EPUB files
- **Resizable Divider**: Between left and right panels
- **Auto-fit**: Content should adjust on panel resize (both horizontal and vertical)

### 5. User Management
- User login system
- Users can run course scanner
- **No user-to-course restriction**: All users see all courses
- Track per user:
  - Viewed files
  - Progress/status
  - Last selected course/book in treeview
- Restore last position on login

### 6. Navigation
- Top bar with navigation between:
  - Client view
  - Admin view

### 7. Frontend Specifications
- Use Angular standalone components (latest approach)
- Use Angular Material for UI
- **Shared styles**: Keep in centralized stylesheet (avoid duplicating in components)
- **Events handling**: Use Angular signals (not CDK change detection)
- Ensure proper event handling with latest Angular

### 8. File Type Icons
TreeView should display appropriate icons for:
- PDF files
- JPG/Image files
- Video files
- Audio files
- Text files
- EPUB files

## Development Approach
- Generate PowerShell scripts for all file creation
- No manual copy-paste of component/class files
- Stop only for:
  - Prerequisites installation
  - Manual configuration steps
- Automate everything else via scripts

## Prerequisites Needed
1. Node.js (v18.19 or later)
2. Python (3.11 or later)
3. PostgreSQL (15 or later)
4. Git (optional)

## Verification Commands
```powershell
node --version
python --version
psql --version
```

## Scripts to Generate
1. **setup-project.ps1** - Creates entire folder structure
2. **setup-frontend.ps1** - Generates all Angular components/services
3. **setup-backend.ps1** - Generates all FastAPI files
4. **setup-database.ps1** - Creates DB schema
5. **install-dependencies.ps1** - Installs all packages

## Next Steps (When Resuming)
1. Confirm prerequisites are installed
2. Run generated PowerShell scripts
3. Configure database connection
4. Start development servers
5. Test scanner functionality

## Notes
- Use latest versions to avoid compatibility issues
- Ensure proper signal-based change detection in Angular
- Focus on efficient file system scanning algorithms
- Implement proper error handling for file operations
