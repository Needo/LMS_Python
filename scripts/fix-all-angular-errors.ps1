# Comprehensive Angular Fix Script
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Fixing All Angular Compilation Errors..." -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

$frontendPath = "C:\Users\munawar\Documents\Python_LMS_Claude_16DEC2025\frontend"

# Fix 1: Update services barrel export
Write-Host "`n1. Fixing services barrel export..." -ForegroundColor Yellow
$servicesIndex = @'
export * from './auth.service';
export * from './category.service';
export * from './course.service';
export * from './file.service';
export * from './progress.service';
export * from './scanner.service';
'@
Set-Content -Path "$frontendPath\src\app\core\services\index.ts" -Value $servicesIndex
Write-Host "   ✓ services/index.ts updated" -ForegroundColor Green

# Fix 2: Models barrel export already fixed above

# Fix 3: Check and create environment files if missing
Write-Host "`n2. Checking environment files..." -ForegroundColor Yellow
$envPath = "$frontendPath\src\environments"
if (-not (Test-Path $envPath)) {
    New-Item -Path $envPath -ItemType Directory -Force | Out-Null
}

$environmentContent = @'
export const environment = {
  production: false,
  apiUrl: 'http://localhost:8000/api'
};
'@

if (-not (Test-Path "$envPath\environment.ts")) {
    Set-Content -Path "$envPath\environment.ts" -Value $environmentContent
    Write-Host "   ✓ environment.ts created" -ForegroundColor Green
} else {
    Write-Host "   ✓ environment.ts exists" -ForegroundColor Green
}

$environmentProdContent = @'
export const environment = {
  production: true,
  apiUrl: 'http://localhost:8000/api'
};
'@

if (-not (Test-Path "$envPath\environment.prod.ts")) {
    Set-Content -Path "$envPath\environment.prod.ts" -Value $environmentProdContent
    Write-Host "   ✓ environment.prod.ts created" -ForegroundColor Green
} else {
    Write-Host "   ✓ environment.prod.ts exists" -ForegroundColor Green
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "Angular Fixes Applied Successfully!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "`nTry running the application again..." -ForegroundColor Yellow
