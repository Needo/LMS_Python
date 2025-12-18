# Script 1: Create Project Structure
# This script creates the complete folder structure for the LMS project

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Creating LMS Project Structure..." -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

$rootPath = "C:\Users\munawar\Documents\Python_LMS_V2"

# Create main directories
$directories = @(
    "frontend",
    "frontend\src",
    "frontend\src\app",
    "frontend\src\app\core",
    "frontend\src\app\core\models",
    "frontend\src\app\core\services",
    "frontend\src\app\core\guards",
    "frontend\src\app\core\interceptors",
    "frontend\src\app\shared",
    "frontend\src\app\shared\components",
    "frontend\src\app\shared\directives",
    "frontend\src\app\shared\pipes",
    "frontend\src\app\features",
    "frontend\src\app\features\auth",
    "frontend\src\app\features\admin",
    "frontend\src\app\features\client",
    "frontend\src\app\features\client\components",
    "frontend\src\assets",
    "frontend\src\assets\icons",
    "frontend\src\styles",
    "backend",
    "backend\app",
    "backend\app\api",
    "backend\app\api\endpoints",
    "backend\app\core",
    "backend\app\models",
    "backend\app\schemas",
    "backend\app\services",
    "backend\app\db",
    "backend\tests",
    "database",
    "database\migrations"
)

foreach ($dir in $directories) {
    $fullPath = Join-Path $rootPath $dir
    if (-not (Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Write-Host "Created: $dir" -ForegroundColor Green
    } else {
        Write-Host "Exists:  $dir" -ForegroundColor Yellow
    }
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "Project structure created successfully!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "`nNext step: Run 2-setup-frontend.ps1" -ForegroundColor Yellow
