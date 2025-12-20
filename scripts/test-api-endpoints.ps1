# Test Backend API Endpoints
Write-Host "Testing backend API..." -ForegroundColor Cyan

$baseUrl = "http://localhost:8000/api"

Write-Host "`n1. Testing /categories endpoint..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/categories" -Method Get
    Write-Host "   Categories found: $($response.Count)" -ForegroundColor Green
    $response | ForEach-Object {
        Write-Host "   - $($_.name) (ID: $($_.id))" -ForegroundColor White
    }
} catch {
    Write-Host "   Error: $_" -ForegroundColor Red
}

Write-Host "`n2. Testing /courses endpoint..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/courses" -Method Get
    Write-Host "   Courses found: $($response.Count)" -ForegroundColor Green
    $response | ForEach-Object {
        Write-Host "   - $($_.name) (Category ID: $($_.category_id))" -ForegroundColor White
    }
} catch {
    Write-Host "   Error: $_" -ForegroundColor Red
}

Write-Host "`n3. Testing /files endpoint for first course..." -ForegroundColor Yellow
try {
    $courses = Invoke-RestMethod -Uri "$baseUrl/courses" -Method Get
    if ($courses.Count -gt 0) {
        $firstCourse = $courses[0]
        $files = Invoke-RestMethod -Uri "$baseUrl/files/course/$($firstCourse.id)" -Method Get
        Write-Host "   Files in '$($firstCourse.name)': $($files.Count)" -ForegroundColor Green
        $files | Select-Object -First 5 | ForEach-Object {
            $type = if ($_.is_directory) { "[DIR]" } else { "[FILE]" }
            Write-Host "   $type $($_.name)" -ForegroundColor White
        }
    }
} catch {
    Write-Host "   Error: $_" -ForegroundColor Red
}

Write-Host "`n============================================" -ForegroundColor Cyan
