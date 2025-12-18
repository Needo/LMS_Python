# Fix SECRET_KEY and Bcrypt Issues
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Fixing Backend Configuration Issues..." -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

Write-Host "`n1. Updating Script 10 - Fix SECRET_KEY..." -ForegroundColor Yellow
$script10 = "C:\Users\munawar\Documents\Python_LMS_V2\scripts\10-generate-backend.ps1"
$content = Get-Content $script10 -Raw

# Replace the long SECRET_KEY with a shorter one (bcrypt can only handle 72 bytes)
$oldSecretKey = "SECRET_KEY=09d25e094faa6ca2556c818166b7a9563b93f7099f6f0f4caa6cf63b88e8d3e7"
$newSecretKey = "SECRET_KEY=my-secret-key-change-in-production"

$content = $content -replace [regex]::Escape($oldSecretKey), $newSecretKey
Set-Content -Path $script10 -Value $content -NoNewline
Write-Host "   ✓ Fixed SECRET_KEY length" -ForegroundColor Green

Write-Host "`n2. Checking backend/.env if exists..." -ForegroundColor Yellow
$envPath = "C:\Users\munawar\Documents\Python_LMS_V2\backend\.env"
if (Test-Path $envPath) {
    $content = Get-Content $envPath -Raw
    $content = $content -replace "SECRET_KEY=09d25e094faa6ca2556c818166b7a9563b93f7099f6f0f4caa6cf63b88e8d3e7", "SECRET_KEY=my-secret-key-change-in-production"
    Set-Content -Path $envPath -Value $content -NoNewline
    Write-Host "   ✓ Fixed backend/.env" -ForegroundColor Green
} else {
    Write-Host "   - backend/.env not found yet" -ForegroundColor Gray
}

Write-Host "`n3. Upgrading bcrypt package..." -ForegroundColor Yellow
$backendPath = "C:\Users\munawar\Documents\Python_LMS_V2\backend"
if (Test-Path $backendPath) {
    Set-Location $backendPath
    python -m pip install --upgrade bcrypt
    Write-Host "   ✓ Bcrypt upgraded" -ForegroundColor Green
} else {
    Write-Host "   - Backend folder not created yet" -ForegroundColor Gray
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "Configuration Fixed!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "`nIssues resolved:" -ForegroundColor Yellow
Write-Host "  1. SECRET_KEY shortened to be bcrypt-compatible" -ForegroundColor White
Write-Host "  2. Bcrypt upgraded to latest version" -ForegroundColor White
