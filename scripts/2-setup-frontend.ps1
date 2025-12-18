# Script 2: Setup Angular Frontend (FIXED)
# This script creates the Angular application and all components

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Setting up Angular Frontend..." -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

$rootPath = "C:\Users\munawar\Documents\Python_LMS_V2"
$frontendPath = Join-Path $rootPath "frontend"

# Change to root directory
Set-Location $rootPath

# Check if Angular CLI is installed
Write-Host "`nChecking Angular CLI..." -ForegroundColor Yellow
$ngVersion = ng version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Angular CLI not found. Installing globally..." -ForegroundColor Yellow
    npm install -g @angular/cli@latest
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to install Angular CLI. Please run: npm install -g @angular/cli" -ForegroundColor Red
        exit 1
    }
}

# Create Angular application if it doesn't exist
if (-not (Test-Path (Join-Path $frontendPath "angular.json"))) {
    Write-Host "`nCreating Angular application..." -ForegroundColor Yellow
    ng new frontend --routing --style=scss --standalone --skip-git
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to create Angular app" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "`nAngular application already exists" -ForegroundColor Yellow
}

# Change to frontend directory
Set-Location $frontendPath

# Install Angular Material
Write-Host "`nInstalling Angular Material..." -ForegroundColor Yellow
npm install @angular/material @angular/cdk @angular/animations

# Install additional dependencies
Write-Host "`nInstalling additional dependencies..." -ForegroundColor Yellow
# Using epubjs instead of ngx-epub-viewer (which doesn't exist)
npm install epubjs pdfjs-dist

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "Frontend setup completed!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "`nNext step: Run 3-generate-frontend-files.ps1" -ForegroundColor Yellow

Set-Location $rootPath
