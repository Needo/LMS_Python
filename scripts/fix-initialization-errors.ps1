# Fix "Used Before Initialization" Errors in All Components
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Fixing Property Initialization Errors..." -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

$frontendPath = "C:\Users\munawar\Documents\Python_LMS_V2\frontend\src\app"

Write-Host "`n1. Fixing admin.component.ts..." -ForegroundColor Yellow
$adminFile = "$frontendPath\features\admin\admin.component.ts"
$content = Get-Content $adminFile -Raw
# Move currentUser initialization to ngOnInit
$content = $content -replace "currentUser = this\.authService\.currentUser;", "currentUser: any;"
$content = $content -replace "ngOnInit\(\): void \{", @"
ngOnInit(): void {
    this.currentUser = this.authService.currentUser;
"@
Set-Content -Path $adminFile -Value $content -NoNewline
Write-Host "   ✓ Fixed admin component" -ForegroundColor Green

Write-Host "`n2. Fixing client.component.ts..." -ForegroundColor Yellow
$clientFile = "$frontendPath\features\client\client.component.ts"
$content = Get-Content $clientFile -Raw
$content = $content -replace "currentUser = this\.authService\.currentUser;", "currentUser: any;"
$content = $content -replace "ngOnInit\(\): void \{", @"
ngOnInit(): void {
    this.currentUser = this.authService.currentUser;
"@
Set-Content -Path $clientFile -Value $content -NoNewline
Write-Host "   ✓ Fixed client component" -ForegroundColor Green

Write-Host "`n3. Fixing file-viewer.component.ts..." -ForegroundColor Yellow
$viewerFile = "$frontendPath\features\client\components\file-viewer.component.ts"
if (Test-Path $viewerFile) {
    $content = Get-Content $viewerFile -Raw
    if ($content -match "currentUser = this\.authService\.currentUser") {
        $content = $content -replace "currentUser = this\.authService\.currentUser;", "currentUser: any;"
        if ($content -match "ngOnInit") {
            $content = $content -replace "ngOnInit\(\): void \{", @"
ngOnInit(): void {
    this.currentUser = this.authService.currentUser;
"@
        } else {
            # Add ngOnInit if it doesn't exist
            $content = $content -replace "(@Component[^)]+\))\s*(export class [^{]+\{)", @"
`$1
`$2
  ngOnInit(): void {
    this.currentUser = this.authService.currentUser;
  }

"@
        }
        Set-Content -Path $viewerFile -Value $content -NoNewline
        Write-Host "   ✓ Fixed file viewer component" -ForegroundColor Green
    }
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "Property Initialization Fixed!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "`nThe 'used before initialization' errors should be resolved." -ForegroundColor Yellow
