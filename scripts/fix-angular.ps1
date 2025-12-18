# Fix Angular Import Issues
Write-Host "Fixing Angular barrel exports..." -ForegroundColor Yellow

$frontendPath = "C:\Users\munawar\Documents\Python_LMS_Claude_16DEC2025\frontend"

# Create barrel export for core/services
$servicesIndex = @'
export * from './auth.service';
export * from './scanner.service';
export * from './file.service';
export * from './progress.service';
'@

New-Item -Path "$frontendPath\src\app\core\services" -ItemType Directory -Force | Out-Null
Set-Content -Path "$frontendPath\src\app\core\services\index.ts" -Value $servicesIndex
Write-Host "✓ Created services/index.ts" -ForegroundColor Green

# Create barrel export for core/models
$modelsIndex = @'
export * from './user.model';
export * from './category.model';
export * from './course.model';
export * from './file-node.model';
export * from './progress.model';
export * from './scan-result.model';
'@

New-Item -Path "$frontendPath\src\app\core\models" -ItemType Directory -Force | Out-Null
Set-Content -Path "$frontendPath\src\app\core\models\index.ts" -Value $modelsIndex
Write-Host "✓ Created models/index.ts" -ForegroundColor Green

Write-Host "`n✓ Angular barrel exports fixed!" -ForegroundColor Green
Write-Host "Run the application again with: .\scripts\19-run-application.ps1" -ForegroundColor Yellow
