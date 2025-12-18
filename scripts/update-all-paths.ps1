# Update All Script Paths to Python_LMS_V2
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Updating All Script Paths..." -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

$scriptsPath = "C:\Users\munawar\Documents\Python_LMS_V2\scripts"

$oldPath = "Python_LMS_Claude_16DEC2025"
$newPath = "Python_LMS_V2"
$count = 0

Write-Host "`nUpdating paths in all scripts..." -ForegroundColor Yellow

Get-ChildItem "$scriptsPath\*.ps1" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    
    if ($content -match $oldPath) {
        $content = $content -replace [regex]::Escape($oldPath), $newPath
        Set-Content -Path $_.FullName -Value $content -NoNewline
        Write-Host "  ✓ Updated: $($_.Name)" -ForegroundColor Green
        $count++
    }
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "Path Update Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "`nUpdated $count script(s)" -ForegroundColor Yellow
Write-Host "All scripts now use: C:\Users\munawar\Documents\Python_LMS_V2" -ForegroundColor Cyan
