# Remove SSR from Angular Project
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Removing Server-Side Rendering (SSR)..." -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

$frontendPath = "C:\Users\munawar\Documents\Python_LMS_Claude_16DEC2025\frontend"
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
    }
}

Write-Host "`n2. Updating angular.json..." -ForegroundColor Yellow

# Read angular.json
$angularJson = Get-Content "angular.json" -Raw | ConvertFrom-Json

# Remove server configuration
if ($angularJson.projects.frontend.architect.PSObject.Properties.Name -contains "server") {
    $angularJson.projects.frontend.architect.PSObject.Properties.Remove("server")
    Write-Host "   ✓ Removed server configuration" -ForegroundColor Green
}

# Update build configuration to remove prerender
if ($angularJson.projects.frontend.architect.build.options.PSObject.Properties.Name -contains "prerender") {
    $angularJson.projects.frontend.architect.build.options.PSObject.Properties.Remove("prerender")
}

if ($angularJson.projects.frontend.architect.build.options.PSObject.Properties.Name -contains "ssr") {
    $angularJson.projects.frontend.architect.build.options.PSObject.Properties.Remove("ssr")
}

# Save angular.json
$angularJson | ConvertTo-Json -Depth 100 | Set-Content "angular.json"
Write-Host "   ✓ Updated angular.json" -ForegroundColor Green

Write-Host "`n3. Updating package.json..." -ForegroundColor Yellow

# Read package.json
$packageJson = Get-Content "package.json" -Raw | ConvertFrom-Json

# Remove SSR-related dependencies
$ssrPackages = @(
    "@angular/ssr",
    "@angular/platform-server",
    "express"
)

$removed = $false
foreach ($pkg in $ssrPackages) {
    if ($packageJson.dependencies.PSObject.Properties.Name -contains $pkg) {
        $packageJson.dependencies.PSObject.Properties.Remove($pkg)
        Write-Host "   ✓ Removed dependency: $pkg" -ForegroundColor Green
        $removed = $true
    }
}

# Save package.json
$packageJson | ConvertTo-Json -Depth 100 | Set-Content "package.json"

if ($removed) {
    Write-Host "`n4. Reinstalling dependencies..." -ForegroundColor Yellow
    npm install
    Write-Host "   ✓ Dependencies updated" -ForegroundColor Green
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "SSR Removed Successfully!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "`nYou can now run: ng serve" -ForegroundColor Yellow
