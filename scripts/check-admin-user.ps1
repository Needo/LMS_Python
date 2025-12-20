# Check Admin User in Database
Write-Host "Checking admin user in database..." -ForegroundColor Cyan

cd C:\Users\munawar\Documents\Python_LMS_V2\backend

$checkScript = @'
import sys
from app.db.database import SessionLocal
from app.models import User

db = SessionLocal()
try:
    admin = db.query(User).filter(User.username == "admin").first()
    if admin:
        print(f"✓ Admin user found:")
        print(f"  Username: {admin.username}")
        print(f"  Email: {admin.email}")
        print(f"  Password: {admin.hashed_password}")
        print(f"  Is Admin: {admin.is_admin}")
        print(f"  Password length: {len(admin.hashed_password)}")
    else:
        print("✗ Admin user not found")
finally:
    db.close()
'@

$checkScript | python

Write-Host "`nIf password is 'admin123' (plain text), login should work now" -ForegroundColor Yellow
