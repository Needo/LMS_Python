# Complete Import Fix - All Files
Write-Host "Fixing ALL import statements..." -ForegroundColor Cyan

$frontendPath = "C:\Users\munawar\Documents\Python_LMS_Claude_16DEC2025\frontend\src\app"

# Fix Service Files
Write-Host "`n1. Fixing service files..." -ForegroundColor Yellow
$servicesPath = "$frontendPath\core\services"

(Get-Content "$servicesPath\auth.service.ts" -Raw) -replace "from '\.\.\/models'", "from '../models/user.model'" | Set-Content "$servicesPath\auth.service.ts" -NoNewline
(Get-Content "$servicesPath\category.service.ts" -Raw) -replace "from '\.\.\/models'", "from '../models/category.model'" | Set-Content "$servicesPath\category.service.ts" -NoNewline
(Get-Content "$servicesPath\course.service.ts" -Raw) -replace "import \{ Course \} from '\.\.\/models';", "import { Course } from '../models/course.model';" | Set-Content "$servicesPath\course.service.ts" -NoNewline
(Get-Content "$servicesPath\file.service.ts" -Raw) -replace "import \{ FileNode, FileType \} from '\.\.\/models';", "import { FileNode, FileType } from '../models/file.model';" | Set-Content "$servicesPath\file.service.ts" -NoNewline
(Get-Content "$servicesPath\progress.service.ts" -Raw) -replace "from '\.\.\/models'", "from '../models/progress.model'" | Set-Content "$servicesPath\progress.service.ts" -NoNewline
(Get-Content "$servicesPath\scanner.service.ts" -Raw) -replace "import \{ ScanRequest, ScanResult \} from '\.\.\/models';", "import { ScanRequest, ScanResult } from '../models/scan.model';" | Set-Content "$servicesPath\scanner.service.ts" -NoNewline

# Fix Component Files
Write-Host "2. Fixing component files..." -ForegroundColor Yellow

# File Viewer - Fix both services and models
(Get-Content "$frontendPath\features\client\components\file-viewer.component.ts" -Raw) `
    -replace "import \{ FileService, ProgressService, AuthService \} from '\.\.\/\.\.\/\.\.\/\.\.\/core\/services';", "import { FileService } from '../../../../core/services/file.service';`nimport { ProgressService } from '../../../../core/services/progress.service';`nimport { AuthService } from '../../../../core/services/auth.service';" `
    -replace "import \{ FileNode, FileType, ProgressStatus \} from '\.\.\/\.\.\/\.\.\/\.\.\/core\/models';", "import { FileNode, FileType } from '../../../../core/models/file.model';`nimport { ProgressStatus } from '../../../../core/models/progress.model';" `
    | Set-Content "$frontendPath\features\client\components\file-viewer.component.ts" -NoNewline

Write-Host "`n✓ All imports fixed!" -ForegroundColor Green
Write-Host "The app should recompile automatically..." -ForegroundColor Yellow
