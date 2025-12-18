# Start Backend Only
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Starting Backend Server..." -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

$backendPath = "C:\Users\munawar\Documents\Python_LMS_V2\backend"

cd $backendPath

Write-Host "`nStarting FastAPI server on http://localhost:8000" -ForegroundColor Yellow
Write-Host "API Documentation: http://localhost:8000/docs" -ForegroundColor Yellow
Write-Host "`nPress Ctrl+C to stop the server" -ForegroundColor Gray
Write-Host ""

python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
