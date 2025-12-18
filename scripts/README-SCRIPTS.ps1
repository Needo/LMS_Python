# Script Overview - Lists all setup scripts and their purpose
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "LMS PROJECT SETUP SCRIPTS" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

Write-Host "`nAll scripts are located in the 'scripts' folder" -ForegroundColor Yellow

Write-Host "`n📋 MASTER SCRIPT" -ForegroundColor Cyan
Write-Host "  0-master-setup.ps1" -ForegroundColor White
Write-Host "    → Runs all setup scripts automatically (RECOMMENDED)" -ForegroundColor Gray

Write-Host "`n📁 PROJECT STRUCTURE" -ForegroundColor Cyan
Write-Host "  1-setup-project-structure.ps1" -ForegroundColor White
Write-Host "    → Creates all folders and directory structure" -ForegroundColor Gray

Write-Host "`n🎨 FRONTEND SETUP (Angular)" -ForegroundColor Cyan
Write-Host "  2-setup-frontend.ps1" -ForegroundColor White
Write-Host "    → Creates Angular app and installs Angular Material" -ForegroundColor Gray

Write-Host "  3-generate-frontend-files.ps1" -ForegroundColor White
Write-Host "    → Generates models, styles, and environment files" -ForegroundColor Gray

Write-Host "  4-generate-frontend-services.ps1" -ForegroundColor White
Write-Host "    → Generates all Angular services (Auth, Category, Course, File, Progress, Scanner)" -ForegroundColor Gray

Write-Host "  5-generate-frontend-components.ps1" -ForegroundColor White
Write-Host "    → Generates authentication components (Login, Register) and guards" -ForegroundColor Gray

Write-Host "  6-generate-admin-components.ps1" -ForegroundColor White
Write-Host "    → Generates admin dashboard for scanner configuration" -ForegroundColor Gray

Write-Host "  7-generate-client-components.ps1" -ForegroundColor White
Write-Host "    → Generates client panel with tree view navigation" -ForegroundColor Gray

Write-Host "  8-generate-file-viewer.ps1" -ForegroundColor White
Write-Host "    → Generates multi-format file viewer (PDF, Video, Audio, Images, Text, EPUB)" -ForegroundColor Gray

Write-Host "  9-generate-app-config.ps1" -ForegroundColor White
Write-Host "    → Generates app configuration, routing, and main component" -ForegroundColor Gray

Write-Host "`n⚙️ BACKEND SETUP (Python FastAPI)" -ForegroundColor Cyan
Write-Host "  10-generate-backend.ps1" -ForegroundColor White
Write-Host "    → Creates backend structure, config, and security utilities" -ForegroundColor Gray

Write-Host "  11-generate-backend-database.ps1" -ForegroundColor White
Write-Host "    → Generates SQLAlchemy models (User, Category, Course, FileNode, Progress)" -ForegroundColor Gray

Write-Host "  12-generate-backend-schemas.ps1" -ForegroundColor White
Write-Host "    → Generates Pydantic schemas for validation" -ForegroundColor Gray

Write-Host "  13-generate-backend-services.ps1" -ForegroundColor White
Write-Host "    → Generates Scanner Service (file system scanning logic)" -ForegroundColor Gray

Write-Host "  14-generate-backend-auth.ps1" -ForegroundColor White
Write-Host "    → Generates authentication service and dependencies" -ForegroundColor Gray

Write-Host "  15-generate-backend-endpoints.ps1" -ForegroundColor White
Write-Host "    → Generates API endpoints (Auth, Categories, Courses)" -ForegroundColor Gray

Write-Host "  16-generate-backend-endpoints-2.ps1" -ForegroundColor White
Write-Host "    → Generates API endpoints (Files, Progress, Scanner)" -ForegroundColor Gray

Write-Host "  17-generate-backend-main.ps1" -ForegroundColor White
Write-Host "    → Generates main FastAPI application and database initialization" -ForegroundColor Gray

Write-Host "`n🗄️ DATABASE SETUP" -ForegroundColor Cyan
Write-Host "  18-setup-database.ps1" -ForegroundColor White
Write-Host "    → Creates PostgreSQL database, installs dependencies, and initializes DB" -ForegroundColor Gray

Write-Host "`n▶️ RUN APPLICATION" -ForegroundColor Cyan
Write-Host "  19-run-application.ps1" -ForegroundColor White
Write-Host "    → Starts both frontend and backend development servers" -ForegroundColor Gray

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "RECOMMENDED USAGE" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

Write-Host "`n✅ Quick Setup (Recommended):" -ForegroundColor Green
Write-Host "   .\scripts\0-master-setup.ps1" -ForegroundColor Cyan
Write-Host "   This runs all scripts automatically in the correct order`n" -ForegroundColor Gray

Write-Host "✅ Then Run Application:" -ForegroundColor Green
Write-Host "   .\scripts\19-run-application.ps1" -ForegroundColor Cyan
Write-Host "   This starts both servers`n" -ForegroundColor Gray

Write-Host "⚠️  Manual Setup:" -ForegroundColor Yellow
Write-Host "   Run scripts 1-18 in order if you need fine-grained control`n" -ForegroundColor Gray

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "PREREQUISITES" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  ✓ Node.js (v18.19+)" -ForegroundColor White
Write-Host "  ✓ Python (3.9+)" -ForegroundColor White
Write-Host "  ✓ PostgreSQL (15+)" -ForegroundColor White
Write-Host "  ✓ PowerShell (5.1+)" -ForegroundColor White

Write-Host "`n============================================" -ForegroundColor Cyan
