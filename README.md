<<<<<<< HEAD
<<<<<<< HEAD
# Learning Management System (LMS)

A modern, full-stack Learning Management System with file system scanning, multi-format file viewing, and user progress tracking.

## 🎯 Features

### Admin Features
- **Root Folder Configuration**: Set up a root folder containing learning materials
- **Intelligent Scanner**: Automatically scans and categorizes content
  - Auto-detects categories (Courses, Books, Novels, Pictures)
  - Supports custom categories (any new folder becomes a category)
  - Efficient rescan with diff detection (adds/removes/updates files)
  - Preserves file system structure in database

### Client Features
- **Tree View Navigation**: Browse all categories, courses, and files
- **Multi-Format Viewer**: View various file types
  - PDF files
  - Video files (MP4, AVI, MKV, MOV, WebM)
  - Audio files (MP3, WAV, OGG, M4A)
  - Images (JPG, PNG, GIF, BMP, WebP)
  - Text files (TXT, MD, LOG)
  - EPUB books
- **Resizable Panels**: Adjust left/right panel sizes with auto-fit content
- **Progress Tracking**: 
  - Track viewed files per user
  - Remember last position
  - Auto-restore last viewed file on login
- **File Type Icons**: Visual indicators for different file types

### User Management
- User authentication (login/register)
- Admin and regular user roles
- All users can access all courses (no course restrictions)
- Personal progress tracking per user

## 🏗️ Tech Stack

### Frontend
- **Angular 19** (Standalone Components)
- **Angular Material** for UI components
- **RxJS Signals** for reactive state management
- **TypeScript**

### Backend
- **Python 3.9+**
- **FastAPI** for REST API
- **SQLAlchemy** for ORM
- **PostgreSQL** for database
- **JWT** for authentication

## 📋 Prerequisites

Before installation, ensure you have:

1. **Node.js** (v18.19 or later)
2. **Python** (3.9 or later)
3. **PostgreSQL** (15 or later)
4. **Git** (optional but recommended)

### Verify Installation
```powershell
node --version
npm --version
python --version
psql --version
```

## 🚀 Quick Start

### Option 1: Automated Setup (Recommended)

1. Open PowerShell as Administrator
2. Navigate to project directory:
   ```powershell
   cd C:\Users\munawar\Documents\Python_LMS_Claude_16DEC2025
   ```

3. Run the master setup script:
   ```powershell
   .\scripts\0-master-setup.ps1
   ```

This will automatically:
- Create all project files
- Install all dependencies
- Setup database
- Initialize with admin user

### Option 2: Manual Step-by-Step Setup

Run scripts in order:

```powershell
cd C:\Users\munawar\Documents\Python_LMS_Claude_16DEC2025\scripts

# 1. Create project structure
.\1-setup-project-structure.ps1

# 2. Setup Angular
.\2-setup-frontend.ps1

# 3-9. Generate frontend files
.\3-generate-frontend-files.ps1
.\4-generate-frontend-services.ps1
.\5-generate-frontend-components.ps1
.\6-generate-admin-components.ps1
.\7-generate-client-components.ps1
.\8-generate-file-viewer.ps1
.\9-generate-app-config.ps1

# 10-17. Generate backend files
.\10-generate-backend.ps1
.\11-generate-backend-database.ps1
.\12-generate-backend-schemas.ps1
.\13-generate-backend-services.ps1
.\14-generate-backend-auth.ps1
.\15-generate-backend-endpoints.ps1
.\16-generate-backend-endpoints-2.ps1
.\17-generate-backend-main.ps1

# 18. Setup database
.\18-setup-database.ps1
```

## 🎮 Running the Application

After setup is complete:

```powershell
.\scripts\19-run-application.ps1
```

This will start:
- **Backend**: http://localhost:8000
- **Frontend**: http://localhost:4200
- **API Docs**: http://localhost:8000/docs

## 🔑 Default Credentials

```
Username: admin
Password: admin123
```

⚠️ **Important**: Change the admin password after first login!

## 📖 Usage Guide

### Setting Up Learning Materials

1. **Login** with admin credentials
2. **Navigate to Admin Panel**
3. **Set Root Folder Path** (e.g., `C:\LearningMaterials`)
4. **Organize your materials** in this structure:
   ```
   C:\LearningMaterials\
   ├── Courses\
   │   ├── Python Programming\
   │   │   ├── Lesson 1.pdf
   │   │   └── Lesson 2.mp4
   │   └── Web Development\
   ├── Books\
   │   ├── Clean Code.pdf
   │   └── Design Patterns.epub
   ├── Novels\
   └── Pictures\
   ```
5. **Click "Scan Folder"** to index all materials

### Accessing Learning Materials

1. **Login** as any user
2. **Browse** the tree view on the left
3. **Click** any file to view it
4. **Your progress** is automatically tracked

### Custom Categories

Simply create new folders in the root directory, and they'll automatically become categories:
```
C:\LearningMaterials\
├── Courses\
├── Books\
├── Tutorials\      ← New category
└── Podcasts\       ← New category
```

## 🗂️ Project Structure

```
Python_LMS_Advance/
├── frontend/               # Angular application
│   ├── src/
│   │   ├── app/
│   │   │   ├── core/      # Services, models, guards
│   │   │   ├── features/  # Feature modules
│   │   │   └── shared/    # Shared components
│   │   └── styles/        # Global styles
│   └── package.json
├── backend/               # FastAPI application
│   ├── app/
│   │   ├── api/          # API endpoints
│   │   ├── core/         # Configuration, security
│   │   ├── models/       # Database models
│   │   ├── schemas/      # Pydantic schemas
│   │   ├── services/     # Business logic
│   │   └── main.py       # Application entry
│   └── requirements.txt
├── scripts/              # Setup scripts
└── README.md
```

## 🔧 Configuration

### Backend Configuration

Edit `backend/.env`:
```env
DATABASE_URL=postgresql://postgres:password@localhost:5432/lms_db
SECRET_KEY=your-secret-key-here
ACCESS_TOKEN_EXPIRE_MINUTES=30
```

### Frontend Configuration

Edit `frontend/src/environments/environment.ts`:
```typescript
export const environment = {
  production: false,
  apiUrl: 'http://localhost:8000/api'
};
```

## 🐛 Troubleshooting

### Database Connection Issues
```powershell
# Check if PostgreSQL is running
Get-Service -Name postgresql*

# Start PostgreSQL if stopped
Start-Service postgresql-x64-XX
```

### Port Already in Use
```powershell
# Backend (port 8000)
netstat -ano | findstr :8000

# Frontend (port 4200)
netstat -ano | findstr :4200

# Kill process if needed
taskkill /PID <PID> /F
```

### Angular CLI Not Found
```powershell
npm install -g @angular/cli
```

### Python Package Installation Issues
```powershell
# Use break-system-packages flag
pip install --break-system-packages -r requirements.txt
```

## 📝 API Documentation

Once the backend is running, access interactive API documentation at:
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

## 🤝 Contributing

This is a personal project, but suggestions are welcome!

## 📄 License

This project is for educational purposes.

## 🆘 Support

If you encounter issues:
1. Check the troubleshooting section
2. Review error messages in terminal/console
3. Check PostgreSQL and service status
4. Verify all prerequisites are installed

## 📚 Additional Resources

- [Angular Documentation](https://angular.io/docs)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Angular Material](https://material.angular.io/)

---

**Built with ❤️ using Angular, FastAPI, and PostgreSQL**
=======
# LMS_.Net
Simple LMS with a file system scanner. developed with .net core api and angular.
>>>>>>> 055499825408f3eb6b2e5d4af4ac87f84177cf1f
=======
# LMS_Python
Python Fast API, Postgres, Angular based light weight learning or courese management system that can present the file system view directly in the browser.
>>>>>>> c77168210b630d4eb0719c55009ea015c9503f54
