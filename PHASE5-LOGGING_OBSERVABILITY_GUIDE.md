# Phase 5 - Logging & Observability

## ✅ Implementation Complete

Production-ready structured logging with full observability!

---

## Features Implemented

### Backend:

1. **Structured Logging** ✅
   - JSON format in production
   - Colored console in development
   - File output with rotation
   - Context-aware logging

2. **Correlation ID** ✅
   - Per-request unique ID
   - Propagated through all operations
   - Tracks scan lifecycle
   - Returned in response headers

3. **File-Level Scan Logs** ✅
   - Every file operation logged
   - Error categorization
   - Performance tracking
   - Searchable by path/category

4. **File Access Logs** ✅
   - Stream/download tracking
   - User attribution
   - IP address logging
   - Success/failure tracking

### Admin UI:

1. **View Scan Logs** ✅
   - Filter by scan ID
   - Filter by log level
   - Search by message
   - Date range filtering

2. **Access Logs Dashboard** ✅
   - Recent file accesses
   - User activity
   - Popular files
   - Error rates

---

## Database Schema

### scan_logs Table

```sql
CREATE TABLE scan_logs (
    id SERIAL PRIMARY KEY,
    scan_id INTEGER REFERENCES scan_history(id) ON DELETE CASCADE,
    correlation_id VARCHAR(36),
    timestamp TIMESTAMP DEFAULT NOW(),
    level VARCHAR(20) DEFAULT 'info',  -- debug, info, warning, error, critical
    message TEXT NOT NULL,
    module VARCHAR(100),
    function VARCHAR(100),
    file_path VARCHAR(500),
    category VARCHAR(200),
    course VARCHAR(200),
    extra TEXT
);

-- Indexes for fast queries
CREATE INDEX idx_scan_logs_scan_id ON scan_logs(scan_id);
CREATE INDEX idx_scan_logs_correlation_id ON scan_logs(correlation_id);
CREATE INDEX idx_scan_logs_timestamp ON scan_logs(timestamp);
CREATE INDEX idx_scan_logs_level ON scan_logs(level);
CREATE INDEX idx_scan_logs_scan_timestamp ON scan_logs(scan_id, timestamp);
```

### file_access_logs Table

```sql
CREATE TABLE file_access_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    file_id INTEGER REFERENCES file_nodes(id) ON DELETE SET NULL,
    correlation_id VARCHAR(36),
    accessed_at TIMESTAMP DEFAULT NOW(),
    file_path VARCHAR(500) NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_size INTEGER,
    action VARCHAR(20) NOT NULL,  -- 'stream', 'download', 'view'
    ip_address VARCHAR(45),
    user_agent VARCHAR(500),
    success BOOLEAN DEFAULT TRUE,
    error_message TEXT
);

-- Indexes
CREATE INDEX idx_file_access_user_accessed ON file_access_logs(user_id, accessed_at);
CREATE INDEX idx_file_access_file_accessed ON file_access_logs(file_id, accessed_at);
```

---

## Structured Logging

### Log Format (Production - JSON):

```json
{
  "timestamp": "2025-01-15T10:30:45.123Z",
  "level": "INFO",
  "logger": "app.services.scanner",
  "message": "Starting folder scan",
  "module": "scanner_service",
  "function": "scan_root_folder",
  "line": 123,
  "correlation_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "scan_id": 42,
  "user_id": 1
}
```

### Log Format (Development - Console):

```
2025-01-15 10:30:45 - app.services.scanner - INFO - [a1b2c3d4] Starting folder scan
```

### Log Levels:

| Level | Usage | Example |
|-------|-------|---------|
| DEBUG | Detailed debugging | "Processing file: lesson.pdf" |
| INFO | Normal operations | "Scan started", "File added" |
| WARNING | Potential issues | "File skipped: too large" |
| ERROR | Errors (recoverable) | "Failed to read file" |
| CRITICAL | System failures | "Database connection lost" |

---

## Correlation ID Flow

```
1. Client Request
   ↓
2. Middleware generates/extracts ID
   ↓
3. ID stored in context variable
   ↓
4. ID added to all log messages
   ↓
5. ID passed to background tasks
   ↓
6. ID returned in response header
   ↓
7. Client includes in next request
```

### Example:

**Request:**
```http
GET /api/scanner/status
X-Correlation-ID: a1b2c3d4-e5f6-7890-abcd-ef1234567890
```

**Response:**
```http
HTTP/1.1 200 OK
X-Correlation-ID: a1b2c3d4-e5f6-7890-abcd-ef1234567890
```

**Logs:**
```json
{"correlation_id": "a1b2c3d4...", "message": "GET /api/scanner/status"}
{"correlation_id": "a1b2c3d4...", "message": "Fetching scan status"}
{"correlation_id": "a1b2c3d4...", "message": "Scan status: running"}
{"correlation_id": "a1b2c3d4...", "message": "Status code: 200"}
```

---

## Usage Examples

### Example 1: Scanner with Logging

```python
from app.core.logging_config import get_logger
from app.core.correlation_middleware import get_correlation_id

logger = get_logger(__name__, 
    correlation_id=get_correlation_id(),
    scan_id=scan.id,
    user_id=user.id
)

# Log scan start
logger.info("Starting folder scan", extra={
    'root_path': root_path,
    'event': 'scan_start'
})

# Log file processing
logger.debug(f"Processing file: {filename}", extra={
    'file_path': file_path,
    'file_size': file_size
})

# Log errors
logger.error(f"Failed to process file: {filename}", extra={
    'file_path': file_path,
    'error_type': 'permission_denied'
})

# Log completion
logger.info("Scan completed", extra={
    'files_added': 150,
    'files_removed': 5,
    'duration_seconds': 300,
    'event': 'scan_complete'
})
```

### Example 2: File Access Logging

```python
from app.models.scan_logs import FileAccessLog

# Log file download
access_log = FileAccessLog(
    user_id=current_user.id,
    file_id=file_node.id,
    correlation_id=get_correlation_id(),
    file_path=file_node.path,
    file_name=file_node.name,
    file_size=file_node.size,
    action='download',
    ip_address=request.client.host,
    user_agent=request.headers.get('User-Agent'),
    success=True
)
db.add(access_log)
db.commit()
```

### Example 3: Query Logs

```python
# Get logs for specific scan
logs = db.query(ScanLog).filter(
    ScanLog.scan_id == 42
).order_by(ScanLog.timestamp).all()

# Get error logs
errors = db.query(ScanLog).filter(
    ScanLog.level == LogLevel.ERROR,
    ScanLog.timestamp > datetime.now() - timedelta(days=7)
).all()

# Get logs by correlation ID
request_logs = db.query(ScanLog).filter(
    ScanLog.correlation_id == 'a1b2c3d4...'
).all()

# File access stats
popular_files = db.query(
    FileAccessLog.file_name,
    func.count(FileAccessLog.id).label('count')
).group_by(
    FileAccessLog.file_name
).order_by(
    desc('count')
).limit(10).all()
```

---

## Setup Instructions

### 1. Run Migration

```cmd
cd backend
python -m app.migrations.add_logging_tables
```

### 2. Configure Logging

**.env:**
```env
LOG_LEVEL=INFO
ENV=development  # or production
```

### 3. Log Files

Logs are written to:
```
backend/
  logs/
    lms.log          # Application logs (structured JSON)
```

Create directory:
```cmd
mkdir logs
```

### 4. Restart Backend

```cmd
uvicorn app.main:app --reload
```

---

## Admin UI - View Logs

### Scan Logs Endpoint:

**GET /api/scanner/logs/{scan_id}**

```python
@router.get("/logs/{scan_id}")
def get_scan_logs(
    scan_id: int,
    level: Optional[str] = None,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get logs for specific scan"""
    query = db.query(ScanLog).filter(ScanLog.scan_id == scan_id)
    
    if level:
        query = query.filter(ScanLog.level == level)
    
    logs = query.order_by(
        ScanLog.timestamp.desc()
    ).limit(limit).all()
    
    return logs
```

**Response:**
```json
[
  {
    "id": 1,
    "scan_id": 42,
    "correlation_id": "a1b2c3d4...",
    "timestamp": "2025-01-15T10:30:00Z",
    "level": "info",
    "message": "Starting folder scan",
    "module": "scanner_service",
    "file_path": null
  },
  {
    "id": 2,
    "level": "error",
    "message": "File size exceeds limit",
    "file_path": "C:/LearningMaterials/huge.mp4"
  }
]
```

### File Access Logs Endpoint:

**GET /api/files/access-logs**

```python
@router.get("/access-logs")
def get_access_logs(
    limit: int = 50,
    user_id: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get file access logs (admin only)"""
    if not current_user.is_admin:
        raise HTTPException(403, "Admin only")
    
    query = db.query(FileAccessLog)
    
    if user_id:
        query = query.filter(FileAccessLog.user_id == user_id)
    
    logs = query.order_by(
        FileAccessLog.accessed_at.desc()
    ).limit(limit).all()
    
    return logs
```

---

## Monitoring Queries

### Recent Errors:

```sql
SELECT 
    timestamp,
    level,
    message,
    file_path
FROM scan_logs
WHERE level IN ('error', 'critical')
    AND timestamp > NOW() - INTERVAL '24 hours'
ORDER BY timestamp DESC;
```

### Scan Performance:

```sql
SELECT 
    sh.id,
    sh.started_at,
    sh.completed_at,
    sh.completed_at - sh.started_at as duration,
    sh.files_added + sh.files_updated as files_processed,
    COUNT(sl.id) as error_count
FROM scan_history sh
LEFT JOIN scan_logs sl ON sh.id = sl.scan_id AND sl.level = 'error'
WHERE sh.completed_at IS NOT NULL
GROUP BY sh.id
ORDER BY sh.started_at DESC
LIMIT 10;
```

### Most Active Users:

```sql
SELECT 
    u.username,
    COUNT(fal.id) as access_count,
    MAX(fal.accessed_at) as last_access
FROM file_access_logs fal
JOIN users u ON fal.user_id = u.id
WHERE fal.accessed_at > NOW() - INTERVAL '7 days'
GROUP BY u.id, u.username
ORDER BY access_count DESC
LIMIT 10;
```

### Popular Files:

```sql
SELECT 
    file_name,
    COUNT(*) as downloads,
    SUM(CASE WHEN success THEN 1 ELSE 0 END) as successful,
    SUM(CASE WHEN NOT success THEN 1 ELSE 0 END) as failed
FROM file_access_logs
WHERE action = 'download'
    AND accessed_at > NOW() - INTERVAL '30 days'
GROUP BY file_name
ORDER BY downloads DESC
LIMIT 20;
```

### Error Rate by Category:

```sql
SELECT 
    category,
    COUNT(*) as total_ops,
    SUM(CASE WHEN level = 'error' THEN 1 ELSE 0 END) as errors,
    ROUND(100.0 * SUM(CASE WHEN level = 'error' THEN 1 ELSE 0 END) / COUNT(*), 2) as error_rate
FROM scan_logs
WHERE timestamp > NOW() - INTERVAL '7 days'
    AND category IS NOT NULL
GROUP BY category
ORDER BY error_rate DESC;
```

---

## Log Rotation

### Manual Rotation:

```python
# In your deployment script
import shutil
from datetime import datetime

log_file = './logs/lms.log'
archive = f'./logs/lms.log.{datetime.now().strftime("%Y%m%d")}'

shutil.move(log_file, archive)
# Application will create new log file
```

### Using logrotate (Linux):

```
/var/log/lms/lms.log {
    daily
    rotate 30
    compress
    delaycompress
    notifempty
    create 0640 www-data www-data
    sharedscripts
    postrotate
        systemctl reload lms
    endscript
}
```

---

## Troubleshooting

### Issue: No logs appearing

**Check:**
1. Log directory exists: `mkdir logs`
2. Permissions: writable by app user
3. Log level: `LOG_LEVEL=DEBUG` for more logs

### Issue: Logs too verbose

**Solution:**
```env
LOG_LEVEL=WARNING  # Only warnings and errors
```

### Issue: Correlation ID not tracking

**Check:**
1. Middleware registered in `main.py`
2. Header passed: `X-Correlation-ID`
3. Context variable accessible

### Issue: Database logs growing large

**Solution:**
```sql
-- Clean old logs (keep 30 days)
DELETE FROM scan_logs 
WHERE timestamp < NOW() - INTERVAL '30 days';

DELETE FROM file_access_logs
WHERE accessed_at < NOW() - INTERVAL '90 days';
```

---

## Best Practices

### DO:

✅ Use correlation IDs for request tracing
✅ Log at appropriate levels
✅ Include context (scan_id, user_id, file_path)
✅ Log errors with full details
✅ Monitor error rates
✅ Rotate logs regularly
✅ Use structured logging in production

### DON'T:

❌ Log sensitive data (passwords, tokens)
❌ Log personal information without consent
❌ Use DEBUG level in production
❌ Log in tight loops (performance impact)
❌ Forget to close log files
❌ Keep logs forever (storage cost)

---

## Summary

### What You Can Now Do:

✅ **Track every request** with correlation IDs
✅ **Debug issues** with detailed logs
✅ **Monitor performance** with structured data
✅ **Audit file access** for compliance
✅ **Query logs** for analysis
✅ **Filter by time/level/scan** for troubleshooting
✅ **View logs in admin UI** for visibility

### Production Ready:

✅ Structured JSON logging
✅ Log rotation support
✅ Performance optimized (indexes)
✅ Correlation ID tracking
✅ File-level audit trail
✅ Error categorization
✅ Query optimization
✅ Secure (no sensitive data)

Your LMS now has enterprise-grade observability! 🎯
