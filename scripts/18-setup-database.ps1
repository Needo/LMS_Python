# Script 18: Setup Database
# This script creates the PostgreSQL database and initializes it

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Setting up Database..." -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

$dbName = "lms_db"
$dbUser = "postgres"
$dbPassword = "postgres123"

Write-Host "`nThis script will:" -ForegroundColor Yellow
Write-Host "1. Create PostgreSQL database '$dbName'" -ForegroundColor Yellow
Write-Host "2. Initialize database tables" -ForegroundColor Yellow
Write-Host "3. Create default admin user" -ForegroundColor Yellow

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "Step 1: Creating Database" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# Check if database exists
$checkDb = "SELECT 1 FROM pg_database WHERE datname='$dbName'" 
$result = psql -U $dbUser -t -c $checkDb 2>&1

if ($result -match "1") {
    Write-Host "Database '$dbName' already exists" -ForegroundColor Yellow
    $response = Read-Host "Do you want to drop and recreate it? (y/N)"
    if ($response -eq "y" -or $response -eq "Y") {
        Write-Host "Dropping existing database..." -ForegroundColor Yellow
        psql -U $dbUser -c "DROP DATABASE IF EXISTS $dbName;"
        Write-Host "Creating new database..." -ForegroundColor Yellow
        psql -U $dbUser -c "CREATE DATABASE $dbName;"
        Write-Host "✓ Database recreated successfully" -ForegroundColor Green
    } else {
        Write-Host "Using existing database" -ForegroundColor Yellow
    }
} else {
    Write-Host "Creating database..." -ForegroundColor Yellow
    psql -U $dbUser -c "CREATE DATABASE $dbName;"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Database created successfully" -ForegroundColor Green
    } else {
        Write-Host "✗ Failed to create database" -ForegroundColor Red
        Write-Host "Please ensure PostgreSQL is running and you have the correct credentials" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "Step 2: Installing Python Dependencies" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

$rootPath = "C:\Users\munawar\Documents\Python_LMS_V2"
$backendPath = Join-Path $rootPath "backend"

Set-Location $backendPath

Write-Host "Installing requirements..." -ForegroundColor Yellow
python -m pip install --break-system-packages -r requirements.txt

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Dependencies installed successfully" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to install dependencies" -ForegroundColor Red
    exit 1
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "Step 3: Initializing Database Tables" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

Write-Host "Running database initialization..." -ForegroundColor Yellow
python -m app.init_db

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Database initialized successfully" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to initialize database" -ForegroundColor Red
    exit 1
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "Database Setup Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "`nDefault Admin Credentials:" -ForegroundColor Yellow
Write-Host "  Username: admin" -ForegroundColor Cyan
Write-Host "  Password: admin123" -ForegroundColor Cyan
Write-Host "`nPlease change the admin password after first login!" -ForegroundColor Yellow
Write-Host "`nNext step: Run 19-run-application.ps1 to start the servers" -ForegroundColor Yellow

Set-Location $rootPath
