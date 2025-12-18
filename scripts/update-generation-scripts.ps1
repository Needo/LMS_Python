# Update All Generation Scripts to Use Correct Import Paths
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Updating Generation Scripts..." -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

$scriptsPath = "C:\Users\munawar\Documents\Python_LMS_V2\scripts"

Write-Host "`nFixing Script 5 (Guards)..." -ForegroundColor Yellow

# Fix Script 5 - Auth Guard
$script5Path = "$scriptsPath\5-generate-frontend-components.ps1"
$content = Get-Content $script5Path -Raw

# Fix auth guard import
$content = $content -replace "import \{ AuthService \} from '\.\.\/services';", "import { AuthService } from '../services/auth.service';"

Set-Content $script5Path -Value $content -NoNewline
Write-Host "✓ Fixed auth guard imports in script 5" -ForegroundColor Green

Write-Host "`nFixing Script 6 (Admin Component)..." -ForegroundColor Yellow
$script6Path = "$scriptsPath\6-generate-admin-components.ps1"
$content = Get-Content $script6Path -Raw

# Fix admin component imports
$content = $content -replace "import \{ AuthService, ScannerService \} from '\.\.\/\.\.\/\.\.\/core\/services';", 
    "import { AuthService } from '../../../core/services/auth.service';`nimport { ScannerService } from '../../../core/services/scanner.service';"
$content = $content -replace "import \{ ScanResult \} from '\.\.\/\.\.\/\.\.\/core\/models';",
    "import { ScanResult } from '../../../core/models/scan.model';"

Set-Content $script6Path -Value $content -NoNewline
Write-Host "✓ Fixed admin component imports" -ForegroundColor Green

Write-Host "`nFixing Script 7 (Client Component)..." -ForegroundColor Yellow
$script7Path = "$scriptsPath\7-generate-client-components.ps1"
$content = Get-Content $script7Path -Raw

# Fix client component imports
$content = $content -replace "import \{ AuthService, CategoryService, CourseService, FileService, ProgressService \} from '\.\.\/\.\.\/\.\.\/core\/services';",
    "import { AuthService } from '../../../core/services/auth.service';`nimport { CategoryService } from '../../../core/services/category.service';`nimport { CourseService } from '../../../core/services/course.service';`nimport { FileService } from '../../../core/services/file.service';`nimport { ProgressService } from '../../../core/services/progress.service';"
$content = $content -replace "import \{ FileNode \} from '\.\.\/\.\.\/\.\.\/core\/models';",
    "import { FileNode } from '../../../core/models/file.model';"

# Fix tree-view component
$content = $content -replace "import \{ CategoryService, CourseService, FileService \} from '\.\.\/\.\.\/\.\.\/\.\.\/core\/services';",
    "import { CategoryService } from '../../../../core/services/category.service';`nimport { CourseService } from '../../../../core/services/course.service';`nimport { FileService } from '../../../../core/services/file.service';"
$content = $content -replace "import \{ Category, Course, FileNode, FileType \} from '\.\.\/\.\.\/\.\.\/\.\.\/core\/models';",
    "import { Category } from '../../../../core/models/category.model';`nimport { Course } from '../../../../core/models/course.model';`nimport { FileNode, FileType } from '../../../../core/models/file.model';"

Set-Content $script7Path -Value $content -NoNewline
Write-Host "✓ Fixed client component imports" -ForegroundColor Green

Write-Host "`nFixing Script 8 (File Viewer)..." -ForegroundColor Yellow
$script8Path = "$scriptsPath\8-generate-file-viewer.ps1"
$content = Get-Content $script8Path -Raw

# Fix file viewer imports
$content = $content -replace "import \{ FileService, ProgressService, AuthService \} from '\.\.\/\.\.\/\.\.\/\.\.\/core\/services';",
    "import { FileService } from '../../../../core/services/file.service';`nimport { ProgressService } from '../../../../core/services/progress.service';`nimport { AuthService } from '../../../../core/services/auth.service';"
$content = $content -replace "import \{ FileNode, FileType, ProgressStatus \} from '\.\.\/\.\.\/\.\.\/\.\.\/core\/models';",
    "import { FileNode, FileType } from '../../../../core/models/file.model';`nimport { ProgressStatus } from '../../../../core/models/progress.model';"

Set-Content $script8Path -Value $content -NoNewline
Write-Host "✓ Fixed file viewer imports" -ForegroundColor Green

Write-Host "`nFixing Script 4 (Services)..." -ForegroundColor Yellow
$script4Path = "$scriptsPath\4-generate-frontend-services.ps1"
$content = Get-Content $script4Path -Raw

# Fix service imports of models
$content = $content -replace "from '\.\.\/models'", "from '../models/user.model'"
$content = $content -replace "import \{ Category \} from '\.\.\/models';", "import { Category } from '../models/category.model';"
$content = $content -replace "import \{ Course \} from '\.\.\/models';", "import { Course } from '../models/course.model';"
$content = $content -replace "import \{ FileNode, FileType \} from '\.\.\/models';", "import { FileNode, FileType } from '../models/file.model';"
$content = $content -replace "import \{ ScanRequest, ScanResult \} from '\.\.\/models';", "import { ScanRequest, ScanResult } from '../models/scan.model';"

Set-Content $script4Path -Value $content -NoNewline
Write-Host "✓ Fixed service imports" -ForegroundColor Green

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "All Generation Scripts Updated!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "`nScripts will now generate correct imports" -ForegroundColor Yellow
Write-Host "If you need to regenerate, the imports will be correct!" -ForegroundColor Yellow
