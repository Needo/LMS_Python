# 🚀 QUICK START GUIDE

## Prerequisites Check

Open PowerShell and run:
```powershell
node --version    # Should be v18.19 or higher
npm --version     # Should be v9.0 or higher
python --version  # Should be 3.9 or higher
psql --version    # Should be 15 or higher
```

If any are missing, install them first!

---

## Installation (5 Minutes)

### Step 1: Open PowerShell as Administrator
Right-click PowerShell → "Run as Administrator"

### Step 2: Navigate to Project
```powershell
cd C:\Users\munawar\Documents\Python_LMS_Claude_16DEC2025
```

### Step 3: Run Master Setup
```powershell
.\scripts\0-master-setup.ps1
```

This will:
- ✅ Create all project files
- ✅ Install Angular and dependencies
- ✅ Install Python packages
- ✅ Create PostgreSQL database
- ✅ Initialize with admin user

**Wait for completion** - This takes about 5-10 minutes depending on your internet speed.

---

## First Run

### Start the Application
```powershell
.\scripts\19-run-application.ps1
```

This opens two windows:
1. **Backend Server** (FastAPI) - Don't close this
2. **Frontend Server** (Angular) - Browser will open automatically

### Access the Application
- Browser automatically opens to: http://localhost:4200
- If not, manually open: http://localhost:4200

---

## First Login

### Admin Credentials
```
Username: admin
Password: admin123
```

⚠️ **Change this password after first login!**

---

## Setup Your Learning Materials

### 1. Organize Your Files
Create a folder structure like this:

```
C:\MyLearning\
├── Courses\
│   ├── Python Programming\
│   │   ├── intro.pdf
│   │   ├── lesson1.mp4
│   │   └── exercises.txt
│   └── Web Development\
├── Books\
│   ├── Clean Code.pdf
│   └── Design Patterns.epub
├── Novels\
└── Pictures\
```

### 2. Configure in Admin Panel
1. Click **"Admin Panel"** in top toolbar
2. Enter your root path: `C:\MyLearning`
3. Click **"Save Path"**
4. Click **"Scan Folder"**

### 3. Wait for Scan
The scanner will:
- Find all categories (Courses, Books, etc.)
- Index all courses
- Catalog all files
- Show results when complete

---

## Using the Application

### As a Student/User

1. **Login** with your credentials
2. **Browse** the tree on the left
   - Click arrows to expand folders
   - Click files to view them
3. **View files** in the right panel
   - PDFs, videos, images, text, EPUB all supported
4. **Your progress** is automatically tracked

### Tree View Tips
- 📁 Folder icons = Directories
- 📄 Different icons for different file types
- Selected files are highlighted in blue

### Creating More Users

1. Click **"Logout"**
2. Click **"Register"** on login page
3. Fill in details
4. New users can access all content immediately

---

## Stopping the Application

### To Stop Servers:
1. Go to each server window (Backend & Frontend)
2. Press `Ctrl + C`
3. Confirm with `Y` when asked

### To Restart:
```powershell
.\scripts\19-run-application.ps1
```

---

## Common Issues & Solutions

### Issue: "Port already in use"
**Solution:**
```powershell
# Kill process on port 8000 (backend)
netstat -ano | findstr :8000
taskkill /PID <PID_NUMBER> /F

# Kill process on port 4200 (frontend)
netstat -ano | findstr :4200
taskkill /PID <PID_NUMBER> /F
```

### Issue: "Cannot connect to database"
**Solution:**
1. Check if PostgreSQL is running:
   ```powershell
   Get-Service postgresql*
   ```
2. Start if stopped:
   ```powershell
   Start-Service postgresql-x64-XX
   ```

### Issue: "Angular CLI not found"
**Solution:**
```powershell
npm install -g @angular/cli
```

### Issue: "Python module not found"
**Solution:**
```powershell
cd backend
pip install --break-system-packages -r requirements.txt
```

---

## File Support

### ✅ Supported File Types:
- **Documents**: PDF, TXT, MD
- **Videos**: MP4, AVI, MKV, MOV, WebM
- **Audio**: MP3, WAV, OGG, M4A
- **Images**: JPG, PNG, GIF, BMP, WebP
- **eBooks**: EPUB

### ❌ Not Yet Supported:
- Microsoft Office files (Word, Excel, PowerPoint)
- Compressed archives (ZIP, RAR)

---

## Next Steps

1. ✅ **Add Content**: Organize your learning materials
2. ✅ **Scan**: Use admin panel to index content
3. ✅ **Create Users**: Register students/learners
4. ✅ **Learn**: Browse and view content
5. ✅ **Track Progress**: System automatically tracks what you've viewed

---

## Important URLs

| Service | URL |
|---------|-----|
| Application | http://localhost:4200 |
| API Backend | http://localhost:8000 |
| API Docs | http://localhost:8000/docs |
| Database | localhost:5432 (PostgreSQL) |

---

## Need Help?

1. Check **README.md** for detailed documentation
2. Run **.\scripts\README-SCRIPTS.ps1** to see what each script does
3. Check the **Troubleshooting** section in README.md

---

## Default Ports

- **Frontend**: 4200
- **Backend**: 8000
- **Database**: 5432

Make sure these ports are available!

---

**🎉 You're all set! Happy Learning!**
