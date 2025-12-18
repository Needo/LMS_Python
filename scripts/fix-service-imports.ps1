# Fix imports inside service files themselves
Write-Host "Fixing service file imports..." -ForegroundColor Cyan

$servicesPath = "C:\Users\munawar\Documents\Python_LMS_Claude_16DEC2025\frontend\src\app\core\services"

# Auth Service
(Get-Content "$servicesPath\auth.service.ts" -Raw) `
    -replace "from '\.\.\/models'", "from '../models/user.model'" `
    | Set-Content "$servicesPath\auth.service.ts" -NoNewline

# Category Service  
(Get-Content "$servicesPath\category.service.ts" -Raw) `
    -replace "from '\.\.\/models'", "from '../models/category.model'" `
    | Set-Content "$servicesPath\category.service.ts" -NoNewline

# Course Service
(Get-Content "$servicesPath\course.service.ts" -Raw) `
    -replace "import \{ Course \} from '\.\.\/models';", "import { Course } from '../models/course.model';" `
    | Set-Content "$servicesPath\course.service.ts" -NoNewline

# File Service
(Get-Content "$servicesPath\file.service.ts" -Raw) `
    -replace "import \{ FileNode, FileType \} from '\.\.\/models';", "import { FileNode, FileType } from '../models/file.model';" `
    | Set-Content "$servicesPath\file.service.ts" -NoNewline

# Progress Service
(Get-Content "$servicesPath\progress.service.ts" -Raw) `
    -replace "from '\.\.\/models'", "from '../models/progress.model'" `
    | Set-Content "$servicesPath\progress.service.ts" -NoNewline

# Scanner Service
(Get-Content "$servicesPath\scanner.service.ts" -Raw) `
    -replace "import \{ ScanRequest, ScanResult \} from '\.\.\/models';", "import { ScanRequest, ScanResult } from '../models/scan.model';" `
    | Set-Content "$servicesPath\scanner.service.ts" -NoNewline

Write-Host "✓ Service imports fixed!" -ForegroundColor Green
