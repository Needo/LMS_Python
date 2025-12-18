# Remove SSR from Angular Project - Complete
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Removing Server-Side Rendering (SSR)..." -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

$frontendPath = "C:\Users\munawar\Documents\Python_LMS_V2\frontend"
cd $frontendPath

Write-Host "`n1. Removing SSR files..." -ForegroundColor Yellow

# Remove SSR-related files
$filesToRemove = @(
    "src\app\app.config.server.ts",
    "src\app\app.routes.server.ts",
    "src\main.server.ts",
    "src\server.ts",
    "tsconfig.server.json"
)

foreach ($file in $filesToRemove) {
    if (Test-Path $file) {
        Remove-Item $file -Force
        Write-Host "   ✓ Removed: $file" -ForegroundColor Green
    } else {
        Write-Host "   - Not found: $file" -ForegroundColor Gray
    }
}

Write-Host "`n2. Updating package.json..." -ForegroundColor Yellow

# Read and update package.json manually
$packageContent = Get-Content "package.json" -Raw

# Remove SSR script
$packageContent = $packageContent -replace '    "serve:ssr:frontend": "node dist/frontend/server/server.mjs",?', ''

# Remove SSR dependencies
$packageContent = $packageContent -replace '    "@angular/platform-server": "[^"]+",?', ''
$packageContent = $packageContent -replace '    "@angular/ssr": "[^"]+",?', ''
$packageContent = $packageContent -replace '    "express": "[^"]+",?', ''
$packageContent = $packageContent -replace '    "@types/express": "[^"]+",?', ''

# Clean up double commas and trailing commas before closing braces
$packageContent = $packageContent -replace ',(\s*\n\s*[}\]])', '$1'
$packageContent = $packageContent -replace ',(\s*,)', ','

Set-Content "package.json" -Value $packageContent
Write-Host "   ✓ Removed SSR packages and scripts" -ForegroundColor Green

Write-Host "`n3. Updating angular.json..." -ForegroundColor Yellow

# Read angular.json
$angularContent = Get-Content "angular.json" -Raw

# Remove server configuration block (everything between "server": { and closing })
$angularContent = $angularContent -replace '"server":\s*\{[^}]*(?:\{[^}]*\}[^}]*)*\},?', ''

# Remove prerender and ssr options
$angularContent = $angularContent -replace '"prerender":\s*(true|false),?', ''
$angularContent = $angularContent -replace '"ssr":\s*\{[^}]*\},?', ''

# Clean up double commas and trailing commas
$angularContent = $angularContent -replace ',(\s*\n\s*[}\]])', '$1'
$angularContent = $angularContent -replace ',(\s*,)', ','

Set-Content "angular.json" -Value $angularContent
Write-Host "   ✓ Updated angular.json" -ForegroundColor Green

Write-Host "`n4. Cleaning and reinstalling dependencies..." -ForegroundColor Yellow
if (Test-Path "node_modules") {
    Write-Host "   Removing node_modules..." -ForegroundColor Cyan
    Remove-Item "node_modules" -Recurse -Force
}
if (Test-Path "package-lock.json") {
    Remove-Item "package-lock.json" -Force
}
Write-Host "   Installing dependencies (this may take a few minutes)..." -ForegroundColor Cyan
npm install
Write-Host "   ✓ Dependencies updated" -ForegroundColor Green

Write-Host "`n5. Clearing Angular cache..." -ForegroundColor Yellow
if (Test-Path ".angular") {
    Remove-Item ".angular" -Recurse -Force
    Write-Host "   ✓ Cache cleared" -ForegroundColor Green
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "SSR Removed Successfully!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "`nYour app is now client-side only!" -ForegroundColor Yellow
Write-Host "You can run: ng serve" -ForegroundColor Yellow
