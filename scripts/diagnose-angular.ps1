# Diagnostic Script for Angular Issues
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Diagnosing Angular Project..." -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

$frontendPath = "C:\Users\munawar\Documents\Python_LMS_Claude_16DEC2025\frontend"
cd $frontendPath

Write-Host "`nChecking Angular version..." -ForegroundColor Yellow
ng version

Write-Host "`n`nChecking tsconfig.json..." -ForegroundColor Yellow
if (Test-Path "tsconfig.json") {
    Write-Host "✓ tsconfig.json exists" -ForegroundColor Green
} else {
    Write-Host "✗ tsconfig.json missing!" -ForegroundColor Red
}

Write-Host "`nChecking angular.json..." -ForegroundColor Yellow
if (Test-Path "angular.json") {
    Write-Host "✓ angular.json exists" -ForegroundColor Green
} else {
    Write-Host "✗ angular.json missing!" -ForegroundColor Red
}

Write-Host "`nChecking package.json..." -ForegroundColor Yellow
if (Test-Path "package.json") {
    Write-Host "✓ package.json exists" -ForegroundColor Green
    Get-Content "package.json" | Select-String "@angular"
} else {
    Write-Host "✗ package.json missing!" -ForegroundColor Red
}

Write-Host "`nChecking node_modules..." -ForegroundColor Yellow
if (Test-Path "node_modules") {
    Write-Host "✓ node_modules exists" -ForegroundColor Green
} else {
    Write-Host "✗ node_modules missing! Run: npm install" -ForegroundColor Red
}

Write-Host "`nChecking environment files..." -ForegroundColor Yellow
if (Test-Path "src\environments\environment.ts") {
    Write-Host "✓ environment.ts exists" -ForegroundColor Green
} else {
    Write-Host "✗ environment.ts missing!" -ForegroundColor Red
}

Write-Host "`nChecking barrel exports..." -ForegroundColor Yellow
Write-Host "Services:" -ForegroundColor Cyan
Get-Content "src\app\core\services\index.ts"
Write-Host "`nModels:" -ForegroundColor Cyan
Get-Content "src\app\core\models\index.ts"

Write-Host "`n`nTrying to compile..." -ForegroundColor Yellow
Write-Host "Running: ng build --configuration development" -ForegroundColor Cyan
ng build --configuration development 2>&1 | Select-Object -First 50
