# Update PostgreSQL Password to postgres123
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Updating PostgreSQL Password..." -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

$newPassword = "postgres123"

Write-Host "`n1. Updating Script 18 (setup-database.ps1)..." -ForegroundColor Yellow
$script18 = "C:\Users\munawar\Documents\Python_LMS_V2\scripts\18-setup-database.ps1"
$content = Get-Content $script18 -Raw
$content = $content -replace '\$dbPassword = "postgres"', "`$dbPassword = `"$newPassword`""
Set-Content -Path $script18 -Value $content -NoNewline
Write-Host "   ✓ Updated database setup script" -ForegroundColor Green

Write-Host "`n2. Updating Script 10 (generate-backend.ps1)..." -ForegroundColor Yellow
$script10 = "C:\Users\munawar\Documents\Python_LMS_V2\scripts\10-generate-backend.ps1"
$content = Get-Content $script10 -Raw
# Update .env content
$content = $content -replace "DATABASE_URL=postgresql://postgres:postgres@localhost", "DATABASE_URL=postgresql://postgres:$newPassword@localhost"
Set-Content -Path $script10 -Value $content -NoNewline
Write-Host "   ✓ Updated backend generation script" -ForegroundColor Green

Write-Host "`n3. Checking if backend/.env exists..." -ForegroundColor Yellow
$envPath = "C:\Users\munawar\Documents\Python_LMS_V2\backend\.env"
if (Test-Path $envPath) {
    $content = Get-Content $envPath -Raw
    $content = $content -replace "DATABASE_URL=postgresql://postgres:postgres@localhost", "DATABASE_URL=postgresql://postgres:$newPassword@localhost"
    Set-Content -Path $envPath -Value $content -NoNewline
    Write-Host "   ✓ Updated backend/.env file" -ForegroundColor Green
} else {
    Write-Host "   - backend/.env not found (will be created by scripts)" -ForegroundColor Gray
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "Password Update Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "`nAll locations updated to use password: $newPassword" -ForegroundColor Yellow
Write-Host "`nLocations updated:" -ForegroundColor Cyan
Write-Host "  1. scripts/18-setup-database.ps1" -ForegroundColor White
Write-Host "  2. scripts/10-generate-backend.ps1" -ForegroundColor White
Write-Host "  3. backend/.env (if exists)" -ForegroundColor White
