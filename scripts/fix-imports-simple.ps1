# Simple Fix - Replace Barrel Imports with Direct Imports
Write-Host "Fixing all import statements..." -ForegroundColor Cyan

$frontendPath = "C:\Users\munawar\Documents\Python_LMS_Claude_16DEC2025\frontend\src\app"

# Admin Component
Write-Host "Fixing admin.component.ts..." -ForegroundColor Yellow
(Get-Content "$frontendPath\features\admin\admin.component.ts" -Raw) `
    -replace "import \{ AuthService, ScannerService \} from '\.\.\/\.\.\/\.\.\/core\/services';", 
             "import { AuthService } from '../../../core/services/auth.service';`nimport { ScannerService } from '../../../core/services/scanner.service';" `
    -replace "import \{ ScanResult \} from '\.\.\/\.\.\/\.\.\/core\/models';",
             "import { ScanResult } from '../../../core/models/scan.model';" `
    | Set-Content "$frontendPath\features\admin\admin.component.ts" -NoNewline

# Client Component  
Write-Host "Fixing client.component.ts..." -ForegroundColor Yellow
(Get-Content "$frontendPath\features\client\client.component.ts" -Raw) `
    -replace "import \{ AuthService, CategoryService, CourseService, FileService, ProgressService \} from '\.\.\/\.\.\/\.\.\/core\/services';",
             "import { AuthService } from '../../../core/services/auth.service';`nimport { CategoryService } from '../../../core/services/category.service';`nimport { CourseService } from '../../../core/services/course.service';`nimport { FileService } from '../../../core/services/file.service';`nimport { ProgressService } from '../../../core/services/progress.service';" `
    -replace "import \{ FileNode \} from '\.\.\/\.\.\/\.\.\/core\/models';",
             "import { FileNode } from '../../../core/models/file.model';" `
    | Set-Content "$frontendPath\features\client\client.component.ts" -NoNewline

# Tree View Component
Write-Host "Fixing tree-view.component.ts..." -ForegroundColor Yellow
(Get-Content "$frontendPath\features\client\components\tree-view.component.ts" -Raw) `
    -replace "import \{ CategoryService, CourseService, FileService \} from '\.\.\/\.\.\/\.\.\/\.\.\/core\/services';",
             "import { CategoryService } from '../../../../core/services/category.service';`nimport { CourseService } from '../../../../core/services/course.service';`nimport { FileService } from '../../../../core/services/file.service';" `
    -replace "import \{ Category, Course, FileNode, FileType \} from '\.\.\/\.\.\/\.\.\/\.\.\/core\/models';",
             "import { Category } from '../../../../core/models/category.model';`nimport { Course } from '../../../../core/models/course.model';`nimport { FileNode, FileType } from '../../../../core/models/file.model';" `
    | Set-Content "$frontendPath\features\client\components\tree-view.component.ts" -NoNewline

# File Viewer Component
Write-Host "Fixing file-viewer.component.ts..." -ForegroundColor Yellow
(Get-Content "$frontendPath\features\client\components\file-viewer.component.ts" -Raw) `
    -replace "import \{ FileType, ProgressStatus \} from '\.\.\/\.\.\/\.\.\/\.\.\/core\/models';",
             "import { FileType } from '../../../../core/models/file.model';`nimport { ProgressStatus } from '../../../../core/models/progress.model';" `
    | Set-Content "$frontendPath\features\client\components\file-viewer.component.ts" -NoNewline

# Login Component
Write-Host "Fixing login.component.ts..." -ForegroundColor Yellow
(Get-Content "$frontendPath\features\auth\login.component.ts" -Raw) `
    -replace "import \{ AuthService \} from '\.\.\/\.\.\/\.\.\/core\/services';",
             "import { AuthService } from '../../../core/services/auth.service';" `
    | Set-Content "$frontendPath\features\auth\login.component.ts" -NoNewline

# Register Component
Write-Host "Fixing register.component.ts..." -ForegroundColor Yellow
(Get-Content "$frontendPath\features\auth\register.component.ts" -Raw) `
    -replace "import \{ AuthService \} from '\.\.\/\.\.\/\.\.\/core\/services';",
             "import { AuthService } from '../../../core/services/auth.service';" `
    | Set-Content "$frontendPath\features\auth\register.component.ts" -NoNewline

# Auth Guard
Write-Host "Fixing auth.guard.ts..." -ForegroundColor Yellow
(Get-Content "$frontendPath\core\guards\auth.guard.ts" -Raw) `
    -replace "import \{ AuthService \} from '\.\.\/services';",
             "import { AuthService } from '../services/auth.service';" `
    | Set-Content "$frontendPath\core\guards\auth.guard.ts" -NoNewline

# Admin Guard
Write-Host "Fixing admin.guard.ts..." -ForegroundColor Yellow
(Get-Content "$frontendPath\core\guards\admin.guard.ts" -Raw) `
    -replace "import \{ AuthService \} from '\.\.\/services';",
             "import { AuthService } from '../services/auth.service';" `
    | Set-Content "$frontendPath\core\guards\admin.guard.ts" -NoNewline

Write-Host "`n✓ All imports fixed!" -ForegroundColor Green
Write-Host "Try running the app now..." -ForegroundColor Yellow
