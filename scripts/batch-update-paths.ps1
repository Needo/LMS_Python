# Update All Remaining Scripts
Write-Host "Updating all script paths..." -ForegroundColor Cyan

$scriptsPath = "C:\Users\munawar\Documents\Python_LMS_V2\scripts"
$oldPath = "Python_LMS_Claude_16DEC2025"
$newPath = "Python_LMS_V2"

$scriptsToUpdate = @(
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
    "18-setup-database.ps1",
    "start-backend.ps1",
    "complete-angular-fix.ps1",
    "fix-backend.ps1",
    "fix-zonejs.ps1",
    "remove-ssr-complete.ps1",
    "update-generation-scripts.ps1"
)

foreach ($scriptName in $scriptsToUpdate) {
    $scriptPath = Join-Path $scriptsPath $scriptName
    if (Test-Path $scriptPath) {
        $content = Get-Content $scriptPath -Raw
        $content = $content -replace [regex]::Escape($oldPath), $newPath
        Set-Content -Path $scriptPath -Value $content -NoNewline
        Write-Host "✓ Updated: $scriptName" -ForegroundColor Green
    }
}

Write-Host "`nAll scripts updated to use Python_LMS_V2!" -ForegroundColor Green
