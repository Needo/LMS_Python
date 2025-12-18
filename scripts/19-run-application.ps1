# Script 19: Run Application (Development Servers)
# This script starts both frontend and backend servers

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Starting LMS Application..." -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

$rootPath = "C:\Users\munawar\Documents\Python_LMS_V2"
$frontendPath = Join-Path $rootPath "frontend"
$backendPath = Join-Path $rootPath "backend"

Write-Host "`nThis script will start:" -ForegroundColor Yellow
Write-Host "  - Backend API (FastAPI) on http://localhost:8000" -ForegroundColor Cyan
Write-Host "  - Frontend (Angular) on http://localhost:4200" -ForegroundColor Cyan

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "Starting Backend Server..." -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# Start backend in a new window
$backendCommand = "cd '$backendPath'; uvicorn app.main:app --reload --host 0.0.0.0 --port 8000"
Start-Process powershell -ArgumentList "-NoExit", "-Command", $backendCommand

Write-Host "✓ Backend server starting in new window..." -ForegroundColor Green
Start-Sleep -Seconds 3

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "Starting Frontend Server..." -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# Start frontend in a new window
$frontendCommand = "cd '$frontendPath'; ng serve --open"
Start-Process powershell -ArgumentList "-NoExit", "-Command", $frontendCommand

Write-Host "✓ Frontend server starting in new window..." -ForegroundColor Green

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "Application Started!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan

Write-Host "`nAccess the application at:" -ForegroundColor Yellow
Write-Host "  Frontend: http://localhost:4200" -ForegroundColor Cyan
Write-Host "  Backend API: http://localhost:8000" -ForegroundColor Cyan
Write-Host "  API Docs: http://localhost:8000/docs" -ForegroundColor Cyan

Write-Host "`nDefault Login:" -ForegroundColor Yellow
Write-Host "  Username: admin" -ForegroundColor Cyan
Write-Host "  Password: admin123" -ForegroundColor Cyan

Write-Host "`nPress Ctrl+C in each server window to stop the servers" -ForegroundColor Yellow
