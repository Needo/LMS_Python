# Phase 1 - Configuration & Environment Management

## ✅ Implementation Complete

All Phase 1 requirements have been implemented without breaking existing functionality.

---

## Backend Implementation

### 1. Environment Files Structure

```
backend/
├── .env.development   # Development config
├── .env.staging       # Staging config
├── .env.production    # Production config
└── .env               # Currently used (copy from one above)
```

### 2. Configuration Settings

All environments support:
- **ROOT_FOLDER_PATH**: Where learning materials are stored
- **MAX_FILE_SIZE**: Maximum allowed file size (bytes)
- **ALLOWED_EXTENSIONS**: Comma-separated list of allowed file types
- **SCAN_DEPTH**: Maximum directory depth to scan (1-50)
- **DEBUG**: Enable/disable debug mode
- **LOG_LEVEL**: Logging verbosity (DEBUG, INFO, WARNING, ERROR)

### 3. How to Switch Environments

Set the `ENV` variable before starting the server:

**Windows:**
```cmd
set ENV=development
uvicorn app.main:app --reload

# Or for staging:
set ENV=staging
uvicorn app.main:app --reload
```

**Linux/Mac:**
```bash
export ENV=development
uvicorn app.main:app --reload

# Or for staging:
export ENV=staging
uvicorn app.main:app --reload
```

### 4. Security Features

✅ **Secret Key Validation**: Production requires strong 32+ character keys
✅ **File Size Limits**: 1KB minimum, 5GB maximum
✅ **Scan Depth Limits**: 1-50 levels (prevents performance issues)
✅ **Root Path Validation**:
- Path must exist
- Must be readable
- Must be a directory
- Prevents system directories (C:\Windows, /etc, etc.)
- Returns canonical (absolute, normalized) path

### 5. API Endpoints

**GET /api/config/public**
- Returns public configuration
- Available to all authenticated users
- Response:
```json
{
  "max_file_size": 104857600,
  "allowed_extensions": [".pdf", ".mp4", ".mp3", ...],
  "scan_depth": 10,
  "environment": "development"
}
```

**POST /api/config/validate-root-path**
- Validates root folder path
- Admin only
- Request:
```json
{
  "path": "C:/LearningMaterials"
}
```
- Response:
```json
{
  "valid": true,
  "exists": true,
  "readable": true,
  "canonical": true,
  "path": "C:\\LearningMaterials",
  "error": null
}
```

---

## Frontend Implementation

### 1. Environment Files

```
frontend/src/environments/
├── environment.ts                    # Base (development)
├── environment.development.ts        # Development
├── environment.staging.ts            # Staging
└── environment.production.ts         # Production
```

### 2. Configuration Service

**Location:** `src/app/core/services/config.service.ts`

**Features:**
- Loads configuration from backend
- Validates file sizes
- Validates file extensions
- Formats file sizes for display
- Validates root paths (admin only)

**Usage Example:**
```typescript
// In any component
constructor(private configService: ConfigService) {}

ngOnInit() {
  // Load config
  this.configService.loadConfig().subscribe();
  
  // Check file size
  if (this.configService.isFileSizeAllowed(fileSize)) {
    // Upload file
  }
  
  // Check extension
  if (this.configService.isExtensionAllowed(filename)) {
    // Process file
  }
}
```

### 3. Admin UI Enhancements

The admin component now:
✅ Validates root path before saving
✅ Shows validation errors with specific messages
✅ Displays canonical path after validation
✅ Prevents saving invalid paths
✅ Shows loading indicator during validation

---

## Usage Examples

### Example 1: Development Setup

1. Copy development environment:
```cmd
cd backend
copy .env.development .env
```

2. Update ROOT_FOLDER_PATH in `.env`:
```env
ROOT_FOLDER_PATH=C:/LearningMaterials
```

3. Start backend:
```cmd
set ENV=development
uvicorn app.main:app --reload
```

4. Start frontend:
```cmd
cd frontend
ng serve
```

### Example 2: Production Deployment

1. Create `.env.production` with strong secrets:
```bash
# Generate strong secret key
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

2. Update `.env.production`:
```env
ENV=production
SECRET_KEY=YOUR_GENERATED_STRONG_KEY_HERE
DATABASE_URL=postgresql://user:pass@prod-db:5432/lms_prod
ROOT_FOLDER_PATH=/var/lms/content
DEBUG=false
LOG_LEVEL=WARNING
```

3. Copy to `.env`:
```bash
cp .env.production .env
```

4. Build frontend for production:
```bash
cd frontend
ng build --configuration=production
```

5. Start backend:
```bash
export ENV=production
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

---

## Configuration Reference

### Backend Environment Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| ENV | string | development | Environment name |
| DEBUG | boolean | false | Enable debug mode |
| LOG_LEVEL | string | INFO | Logging level |
| DATABASE_URL | string | required | PostgreSQL connection string |
| SECRET_KEY | string | required | JWT secret (32+ chars in prod) |
| ROOT_FOLDER_PATH | string | null | Root folder for learning materials |
| MAX_FILE_SIZE | integer | 104857600 | Max file size in bytes (100MB) |
| ALLOWED_EXTENSIONS | string | .pdf,.mp4,... | Comma-separated extensions |
| SCAN_DEPTH | integer | 10 | Max directory scan depth (1-50) |
| BACKUP_DIR | string | ./backups | Backup storage directory |
| POSTGRES_BIN_PATH | string | /usr/bin | Path to PostgreSQL binaries |

### Validation Rules

**SECRET_KEY (Production)**
- Minimum 32 characters
- Cannot contain: "my-secret-key", "change-this", "secret", "dev-secret"

**MAX_FILE_SIZE**
- Minimum: 1024 bytes (1KB)
- Maximum: 5368709120 bytes (5GB)

**SCAN_DEPTH**
- Minimum: 1
- Maximum: 50

**ROOT_FOLDER_PATH**
- Must exist on filesystem
- Must be a directory
- Must have read permissions
- Cannot be system directory
- Returns canonical (absolute) path

---

## Testing the Implementation

### 1. Test Configuration Loading

```bash
# Backend
curl http://localhost:8000/api/config/public

# Expected response:
{
  "max_file_size": 104857600,
  "allowed_extensions": [".pdf", ".mp4", ...],
  "scan_depth": 10,
  "environment": "development"
}
```

### 2. Test Path Validation (Admin Only)

```bash
# Valid path
curl -X POST http://localhost:8000/api/config/validate-root-path \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"path": "C:/LearningMaterials"}'

# Expected: {"valid": true, "exists": true, ...}
```

### 3. Test Invalid Paths

```bash
# Non-existent path
curl -X POST http://localhost:8000/api/config/validate-root-path \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"path": "C:/NonExistent"}'

# Expected: {"valid": false, "error": "Path does not exist: ..."}
```

### 4. Test Frontend Validation

1. Login as admin
2. Navigate to Admin Panel
3. Enter invalid path (e.g., "C:\Windows")
4. Click "Save Root Path"
5. Should show error: "Cannot use system directory as root folder"

---

## Migration from Old Setup

If you have existing `.env` file:

1. **Backup current `.env`:**
```bash
cp .env .env.backup
```

2. **Update with new variables:**
```bash
# Add these to your .env
ENV=development
ROOT_FOLDER_PATH=C:/LearningMaterials
MAX_FILE_SIZE=104857600
ALLOWED_EXTENSIONS=.pdf,.mp4,.mp3,.txt,.docx,.jpg,.png,.epub
SCAN_DEPTH=10
DEBUG=true
LOG_LEVEL=DEBUG
```

3. **Test the application:**
- Start backend
- Start frontend
- Login as admin
- Test root path validation

---

## Security Best Practices

### Development
✅ Use weak credentials for easier testing
✅ Enable DEBUG mode
✅ Use local file paths
✅ Allow CORS from localhost

### Staging
✅ Use environment-specific credentials
✅ Disable DEBUG mode
✅ Use staging domain for CORS
✅ Test with production-like settings

### Production
✅ **Strong SECRET_KEY (32+ characters)**
✅ **Unique database credentials**
✅ **HTTPS only**
✅ **Specific CORS origins**
✅ **Disable DEBUG**
✅ **LOG_LEVEL = WARNING or ERROR**
✅ **Regular backups**
✅ **Monitor file storage**

---

## Troubleshooting

### Issue: "SECRET_KEY is too weak for production"

**Solution:**
```bash
# Generate strong key
python -c "import secrets; print(secrets.token_urlsafe(32))"

# Add to .env.production
SECRET_KEY=generated_key_here
```

### Issue: "Path validation fails"

**Checks:**
1. Does the path exist?
2. Do you have read permissions?
3. Is it a directory (not a file)?
4. Is it a system directory?

**Solution:**
```bash
# Windows - Create directory
mkdir C:\LearningMaterials

# Linux/Mac
mkdir -p /var/lms/content
chmod 755 /var/lms/content
```

### Issue: "Config not loading in frontend"

**Solution:**
1. Check browser console for errors
2. Verify API endpoint is accessible
3. Check CORS settings
4. Ensure user is authenticated

---

## What's Next

Phase 1 is complete! Next phases:

- **Phase 2**: Enhanced file management
- **Phase 3**: User roles and permissions
- **Phase 4**: Progress tracking improvements
- **Phase 5**: Search and filtering
- **Phase 6**: Notifications
- **Phase 7**: Analytics and reporting

---

## Summary

✅ **Multi-environment support** (dev, staging, prod)
✅ **Secure configuration** with validation
✅ **Root path validation** with safety checks
✅ **Frontend enforcement** of file size/extension rules
✅ **Configuration API** for dynamic settings
✅ **Production-safe** with secret validation
✅ **Backward compatible** - existing features work unchanged

All requirements met with minimal complexity and production-ready implementation!
