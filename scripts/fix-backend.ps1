# Fix Backend Dependencies
Write-Host "Installing missing Python dependencies..." -ForegroundColor Yellow

cd C:\Users\munawar\Documents\Python_LMS_V2\backend

# Install missing email-validator
python -m pip install email-validator

# Upgrade bcrypt to fix the warning
python -m pip install --upgrade bcrypt

Write-Host "✓ Backend dependencies fixed!" -ForegroundColor Green
