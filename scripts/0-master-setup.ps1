# Master Setup Script - Run All Setup Scripts in Order
# This script automates the entire project setup

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "LMS PROJECT - MASTER SETUP" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

$rootPath = "C:\Users\munawar\Documents\Python_LMS_V2"
$scriptsPath = Join-Path $rootPath "scripts"

Write-Host "`nThis master script will run all setup steps automatically." -ForegroundColor Yellow
Write-Host "The setup process includes:" -ForegroundColor Yellow
Write-Host "  1. Create project structure" -ForegroundColor White
Write-Host "  2. Setup Angular frontend" -ForegroundColor White
Write-Host "  3. Generate all frontend files" -ForegroundColor White
Write-Host "  4. Generate frontend services" -ForegroundColor White
Write-Host "  5. Generate auth components" -ForegroundColor White
Write-Host "  6. Generate admin components" -ForegroundColor White
Write-Host "  7. Generate client components" -ForegroundColor White
Write-Host "  8. Generate file viewer" -ForegroundColor White
Write-Host "  9. Generate app configuration" -ForegroundColor White
Write-Host "  10. Generate backend structure" -ForegroundColor White
Write-Host "  11. Generate database models" -ForegroundColor White
Write-Host "  12. Generate backend schemas" -ForegroundColor White
Write-Host "  13. Generate backend services" -ForegroundColor White
Write-Host "  14. Generate auth service" -ForegroundColor White
Write-Host "  15. Generate API endpoints (Part 1)" -ForegroundColor White
Write-Host "  16. Generate API endpoints (Part 2)" -ForegroundColor White
Write-Host "  17. Generate main application" -ForegroundColor White
Write-Host "  18. Setup database" -ForegroundColor White

$response = Read-Host "`nDo you want to continue with automatic setup? (Y/n)"
if ($response -eq "n" -or $response -eq "N") {
    Write-Host "Setup cancelled. You can run individual scripts manually from the scripts folder." -ForegroundColor Yellow
    exit
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "Starting Automated Setup..." -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

$scripts = @(
    "1-setup-project-structure.ps1",
    "2-setup-frontend.ps1",
    "3-generate-frontend-files.ps1",
    "4-generate-frontend-services.ps1",
    "5-generate-frontend-components.ps1",
    "6-generate-admin-components.ps1",
    "7-generate-client-components.ps1",
    "8-generate-file-viewer.ps1",
    "9-generate-app-config.ps1",
    "10-generate-backend.ps1",
    "11-generate-backend-database.ps1",
    "12-generate-backend-schemas.ps1",
    "13-generate-backend-services.ps1",
    "14-generate-backend-auth.ps1",
    "15-generate-backend-endpoints.ps1",
    "16-generate-backend-endpoints-2.ps1",
    "17-generate-backend-main.ps1",
    "18-setup-database.ps1"
)

$currentStep = 1
$totalSteps = $scripts.Count

foreach ($script in $scripts) {
    $scriptPath = Join-Path $scriptsPath $script
    
    Write-Host "`n============================================" -ForegroundColor Cyan
    Write-Host "Step $currentStep of $totalSteps : $script" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    
    if (Test-Path $scriptPath) {
        & $scriptPath
        
        if ($LASTEXITCODE -ne 0 -and $null -ne $LASTEXITCODE) {
            Write-Host "`n✗ Error in step $currentStep" -ForegroundColor Red
            Write-Host "Please check the error above and fix any issues." -ForegroundColor Yellow
            Write-Host "You can resume by running script: $script" -ForegroundColor Yellow
            exit 1
        }
        
        Write-Host "`n✓ Step $currentStep completed successfully" -ForegroundColor Green
    } else {
        Write-Host "✗ Script not found: $scriptPath" -ForegroundColor Red
        exit 1
    }
    
    $currentStep++
    Start-Sleep -Seconds 2
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "SETUP COMPLETE!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan

Write-Host "`nYour LMS application is ready!" -ForegroundColor Green
Write-Host "`nTo start the application, run:" -ForegroundColor Yellow
Write-Host "  .\scripts\19-run-application.ps1" -ForegroundColor Cyan

Write-Host "`nDefault Admin Credentials:" -ForegroundColor Yellow
Write-Host "  Username: admin" -ForegroundColor Cyan
Write-Host "  Password: admin123" -ForegroundColor Cyan

Write-Host "`nAccess Points:" -ForegroundColor Yellow
Write-Host "  Frontend: http://localhost:4200" -ForegroundColor Cyan
Write-Host "  Backend API: http://localhost:8000" -ForegroundColor Cyan
Write-Host "  API Documentation: http://localhost:8000/docs" -ForegroundColor Cyan

Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "  1. Run the application using script 19" -ForegroundColor White
Write-Host "  2. Login with admin credentials" -ForegroundColor White
Write-Host "  3. Configure root folder in Admin panel" -ForegroundColor White
Write-Host "  4. Scan your learning materials" -ForegroundColor White
Write-Host "  5. Start learning!" -ForegroundColor White

Write-Host "`n============================================" -ForegroundColor Cyan
