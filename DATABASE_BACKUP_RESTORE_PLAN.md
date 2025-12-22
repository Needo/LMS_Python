# Database Backup & Restore Implementation Plan

## Overview
Implement a complete database backup and restore system for the LMS admin panel, allowing administrators to create backups and restore from them safely.

---

## Architecture Design

### Core Components

#### 1. Backend Services
- **BackupService** - Handles PostgreSQL backup operations
- **RestoreService** - Handles PostgreSQL restore operations
- **LockService** - Ensures single operation at a time

#### 2. Backend API Endpoints
- `POST /api/admin/backup/create` - Trigger backup creation
- `GET /api/admin/backup/list` - List all available backups
- `GET /api/admin/backup/download/{backup_id}` - Download backup file
- `POST /api/admin/backup/restore/{backup_id}` - Restore from backup
- `DELETE /api/admin/backup/{backup_id}` - Delete backup file
- `GET /api/admin/backup/status` - Get current operation status

#### 3. Database Schema
```sql
-- New table: backup_history
CREATE TABLE backup_history (
    id SERIAL PRIMARY KEY,
    filename VARCHAR(255) NOT NULL UNIQUE,
    file_path VARCHAR(512) NOT NULL,
    file_size BIGINT,
    backup_type VARCHAR(50) DEFAULT 'manual',
    created_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW(),
    status VARCHAR(50) DEFAULT 'completed',
    metadata JSONB,
    notes TEXT
);

-- New table: operation_lock
CREATE TABLE operation_lock (
    id SERIAL PRIMARY KEY,
    operation_type VARCHAR(50) NOT NULL,
    locked_by INTEGER REFERENCES users(id),
    locked_at TIMESTAMP DEFAULT NOW(),
    status VARCHAR(50) DEFAULT 'in_progress'
);
```

#### 4. Frontend Components
- **BackupSection** component in admin panel
- **BackupListDialog** - Shows all backups
- **RestoreConfirmDialog** - Confirmation before restore
- **BackupProgressIndicator** - Shows operation progress

---

## Detailed Implementation Plan

### Phase 1: Backend Infrastructure

#### 1.1 Configuration Setup
**File**: `backend/app/core/config.py`

Add new settings:
```python
class Settings(BaseSettings):
    # ... existing settings ...
    
    # Backup Configuration
    BACKUP_DIR: str = "./backups"  # Where to store backups
    MAX_BACKUP_SIZE: int = 1073741824  # 1GB max backup size
    MAX_BACKUPS_TO_KEEP: int = 10  # Auto-cleanup old backups
    POSTGRES_BIN_PATH: str = "/usr/bin"  # Path to pg_dump/pg_restore
```

#### 1.2 Backup Storage Directory
**Location**: `backend/backups/`

Structure:
```
backups/
  ├── backup_20241221_143022.sql
  ├── backup_20241220_091545.sql
  └── metadata/
      ├── backup_20241221_143022.json
      └── backup_20241220_091545.json
```

#### 1.3 Database Models
**File**: `backend/app/models/backup.py`

```python
from sqlalchemy import Column, Integer, String, BigInteger, DateTime, ForeignKey, Text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import relationship
from app.db.database import Base
import datetime

class BackupHistory(Base):
    __tablename__ = "backup_history"
    
    id = Column(Integer, primary_key=True, index=True)
    filename = Column(String(255), nullable=False, unique=True)
    file_path = Column(String(512), nullable=False)
    file_size = Column(BigInteger)
    backup_type = Column(String(50), default='manual')
    created_by_id = Column(Integer, ForeignKey('users.id'))
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    status = Column(String(50), default='completed')
    metadata = Column(JSONB)
    notes = Column(Text)
    
    created_by = relationship("User")

class OperationLock(Base):
    __tablename__ = "operation_lock"
    
    id = Column(Integer, primary_key=True, index=True)
    operation_type = Column(String(50), nullable=False)
    locked_by_id = Column(Integer, ForeignKey('users.id'))
    locked_at = Column(DateTime, default=datetime.datetime.utcnow)
    status = Column(String(50), default='in_progress')
    
    locked_by = relationship("User")
```

#### 1.4 Pydantic Schemas
**File**: `backend/app/schemas/backup.py`

```python
from pydantic import BaseModel
from datetime import datetime
from typing import Optional, Dict, Any

class BackupCreate(BaseModel):
    notes: Optional[str] = None

class BackupResponse(BaseModel):
    id: int
    filename: str
    file_size: int
    backup_type: str
    created_by: str
    created_at: datetime
    status: str
    notes: Optional[str]
    
    class Config:
        from_attributes = True

class BackupListResponse(BaseModel):
    backups: list[BackupResponse]
    total: int

class BackupStatusResponse(BaseModel):
    is_locked: bool
    operation_type: Optional[str]
    locked_by: Optional[str]
    locked_at: Optional[datetime]

class RestoreRequest(BaseModel):
    backup_id: int
    confirm: bool = False
```

---

### Phase 2: Backend Services

#### 2.1 Backup Service
**File**: `backend/app/services/backup_service.py`

**Key Methods:**
```python
class BackupService:
    def __init__(self, db: Session):
        self.db = db
        
    async def create_backup(self, user_id: int, notes: Optional[str] = None) -> BackupHistory:
        """
        Creates a new database backup using pg_dump
        
        Steps:
        1. Check if backup operation is already running (lock check)
        2. Create operation lock
        3. Generate unique filename with timestamp
        4. Execute pg_dump command
        5. Calculate file size
        6. Create BackupHistory record
        7. Release lock
        8. Return backup info
        """
        
    def list_backups(self, limit: int = 50, offset: int = 0) -> List[BackupHistory]:
        """List all backups with pagination"""
        
    def get_backup_by_id(self, backup_id: int) -> Optional[BackupHistory]:
        """Get specific backup details"""
        
    def delete_backup(self, backup_id: int, user_id: int) -> bool:
        """Delete backup file and record (admin only)"""
        
    def cleanup_old_backups(self) -> int:
        """Auto-cleanup old backups beyond MAX_BACKUPS_TO_KEEP"""
```

**Implementation Details:**

**PostgreSQL Backup Command:**
```python
import subprocess
import os
from urllib.parse import urlparse

def _execute_pg_dump(self, output_file: str) -> bool:
    """
    Execute pg_dump command
    
    Command format:
    pg_dump -h host -p port -U username -d database -F c -f output_file
    
    Environment variable PGPASSWORD for password
    """
    # Parse DATABASE_URL
    db_url = urlparse(settings.DATABASE_URL)
    
    env = os.environ.copy()
    env['PGPASSWORD'] = db_url.password
    
    cmd = [
        os.path.join(settings.POSTGRES_BIN_PATH, 'pg_dump'),
        '-h', db_url.hostname,
        '-p', str(db_url.port),
        '-U', db_url.username,
        '-d', db_url.path[1:],  # Remove leading /
        '-F', 'c',  # Custom format (compressed)
        '-f', output_file
    ]
    
    result = subprocess.run(cmd, env=env, capture_output=True, text=True)
    return result.returncode == 0
```

#### 2.2 Restore Service
**File**: `backend/app/services/restore_service.py`

**Key Methods:**
```python
class RestoreService:
    def __init__(self, db: Session):
        self.db = db
        
    async def restore_backup(self, backup_id: int, user_id: int) -> bool:
        """
        Restore database from backup
        
        Steps:
        1. Check if any operation is running (CRITICAL)
        2. Create restore lock
        3. Validate backup file exists
        4. Close all existing database connections
        5. Drop and recreate database (or use pg_restore --clean)
        6. Execute pg_restore command
        7. Run database migrations if needed
        8. Release lock
        9. Return success/failure
        
        SAFETY NOTES:
        - This is a DESTRUCTIVE operation
        - All current data will be lost
        - Application should be in maintenance mode
        """
        
    def _execute_pg_restore(self, backup_file: str) -> bool:
        """Execute pg_restore command"""
        
    def _verify_database_integrity(self) -> bool:
        """Run basic integrity checks after restore"""
```

**Implementation Details:**

**PostgreSQL Restore Command:**
```python
def _execute_pg_restore(self, backup_file: str) -> bool:
    """
    Execute pg_restore command
    
    Command format:
    pg_restore -h host -p port -U username -d database --clean --if-exists backup_file
    
    Options:
    --clean: Drop objects before recreating
    --if-exists: Don't error if objects don't exist
    """
    db_url = urlparse(settings.DATABASE_URL)
    
    env = os.environ.copy()
    env['PGPASSWORD'] = db_url.password
    
    cmd = [
        os.path.join(settings.POSTGRES_BIN_PATH, 'pg_restore'),
        '-h', db_url.hostname,
        '-p', str(db_url.port),
        '-U', db_url.username,
        '-d', db_url.path[1:],
        '--clean',
        '--if-exists',
        backup_file
    ]
    
    result = subprocess.run(cmd, env=env, capture_output=True, text=True)
    return result.returncode == 0
```

#### 2.3 Lock Service
**File**: `backend/app/services/lock_service.py`

```python
class LockService:
    def __init__(self, db: Session):
        self.db = db
    
    def acquire_lock(self, operation_type: str, user_id: int) -> bool:
        """
        Try to acquire a lock for the operation
        Returns True if lock acquired, False if already locked
        """
        
    def release_lock(self, operation_type: str) -> bool:
        """Release the operation lock"""
        
    def check_lock_status(self) -> Optional[OperationLock]:
        """Check current lock status"""
        
    def force_release_lock(self, user_id: int) -> bool:
        """Force release lock (admin emergency use only)"""
```

---

### Phase 3: Backend API Endpoints

#### 3.1 Backup Router
**File**: `backend/app/api/routes/backup.py`

```python
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from app.api.deps import get_db, get_current_active_admin
from app.schemas.backup import *
from app.services.backup_service import BackupService
from app.services.restore_service import RestoreService
from app.services.lock_service import LockService

router = APIRouter()

@router.post("/create", response_model=BackupResponse)
async def create_backup(
    backup_data: BackupCreate,
    current_user = Depends(get_current_active_admin),
    db: Session = Depends(get_db)
):
    """Create a new database backup"""
    
@router.get("/list", response_model=BackupListResponse)
def list_backups(
    skip: int = 0,
    limit: int = 50,
    current_user = Depends(get_current_active_admin),
    db: Session = Depends(get_db)
):
    """List all available backups"""
    
@router.get("/download/{backup_id}")
async def download_backup(
    backup_id: int,
    current_user = Depends(get_current_active_admin),
    db: Session = Depends(get_db)
):
    """Download a backup file"""
    # Return FileResponse with backup file
    
@router.post("/restore/{backup_id}")
async def restore_backup(
    backup_id: int,
    restore_data: RestoreRequest,
    current_user = Depends(get_current_active_admin),
    db: Session = Depends(get_db)
):
    """Restore database from backup (DESTRUCTIVE)"""
    
@router.delete("/{backup_id}")
async def delete_backup(
    backup_id: int,
    current_user = Depends(get_current_active_admin),
    db: Session = Depends(get_db)
):
    """Delete a backup"""
    
@router.get("/status", response_model=BackupStatusResponse)
def get_backup_status(
    current_user = Depends(get_current_active_admin),
    db: Session = Depends(get_db)
):
    """Get current backup/restore operation status"""
```

---

### Phase 4: Frontend Implementation

#### 4.1 Backup Service
**File**: `frontend/src/app/core/services/backup.service.ts`

```typescript
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface Backup {
  id: number;
  filename: string;
  file_size: number;
  backup_type: string;
  created_by: string;
  created_at: Date;
  status: string;
  notes?: string;
}

export interface BackupListResponse {
  backups: Backup[];
  total: number;
}

export interface BackupStatus {
  is_locked: boolean;
  operation_type?: string;
  locked_by?: string;
  locked_at?: Date;
}

@Injectable({
  providedIn: 'root'
})
export class BackupService {
  private apiUrl = `${environment.apiUrl}/admin/backup`;

  constructor(private http: HttpClient) {}

  createBackup(notes?: string): Observable<Backup> {
    return this.http.post<Backup>(`${this.apiUrl}/create`, { notes });
  }

  listBackups(): Observable<BackupListResponse> {
    return this.http.get<BackupListResponse>(`${this.apiUrl}/list`);
  }

  downloadBackup(backupId: number): Observable<Blob> {
    return this.http.get(`${this.apiUrl}/download/${backupId}`, {
      responseType: 'blob'
    });
  }

  restoreBackup(backupId: number, confirm: boolean): Observable<any> {
    return this.http.post(`${this.apiUrl}/restore/${backupId}`, { confirm });
  }

  deleteBackup(backupId: number): Observable<any> {
    return this.http.delete(`${this.apiUrl}/${backupId}`);
  }

  getStatus(): Observable<BackupStatus> {
    return this.http.get<BackupStatus>(`${this.apiUrl}/status`);
  }
}
```

#### 4.2 Update Admin Component
**File**: `frontend/src/app/features/admin/admin.component.ts`

Add new signals and methods:
```typescript
export class AdminComponent implements OnInit {
  // ... existing code ...
  
  // New backup-related signals
  backups = signal<Backup[]>([]);
  isBackupInProgress = signal(false);
  isRestoreInProgress = signal(false);
  backupStatus = signal<BackupStatus | null>(null);
  
  constructor(
    // ... existing dependencies ...
    private backupService: BackupService,
    private dialog: MatDialog
  ) {}
  
  ngOnInit(): void {
    // ... existing code ...
    this.loadBackups();
    this.checkBackupStatus();
  }
  
  loadBackups(): void {
    this.backupService.listBackups().subscribe({
      next: (response) => this.backups.set(response.backups),
      error: (error) => console.error('Error loading backups:', error)
    });
  }
  
  createBackup(): void {
    // Open dialog for notes, then create backup
  }
  
  downloadBackup(backup: Backup): void {
    // Download backup file
  }
  
  restoreBackup(backup: Backup): void {
    // Open confirmation dialog, then restore
  }
  
  deleteBackup(backup: Backup): void {
    // Confirm and delete backup
  }
  
  checkBackupStatus(): void {
    // Poll status every 5 seconds if operation in progress
  }
}
```

#### 4.3 Admin Component Template
**File**: `frontend/src/app/features/admin/admin.component.html`

Add new card for backup/restore section:
```html
<!-- Add after existing cards -->

<mat-card class="backup-card">
  <mat-card-header>
    <mat-card-title>Database Backup & Restore</mat-card-title>
  </mat-card-header>
  <mat-card-content>
    <p>Create backups and restore your database.</p>
    
    <div class="backup-actions">
      <button mat-raised-button 
              color="primary" 
              (click)="createBackup()"
              [disabled]="isBackupInProgress() || isRestoreInProgress()">
        <mat-icon>backup</mat-icon>
        Create Backup
      </button>
      
      <button mat-button (click)="loadBackups()">
        <mat-icon>refresh</mat-icon>
        Refresh List
      </button>
    </div>
    
    @if (backupStatus()?.is_locked) {
      <mat-progress-bar mode="indeterminate"></mat-progress-bar>
      <p class="status-text">
        Operation in progress: {{ backupStatus()?.operation_type }}
      </p>
    }
    
    <!-- Backups List -->
    <div class="backups-list">
      @if (backups().length === 0) {
        <p class="no-backups">No backups available</p>
      } @else {
        @for (backup of backups(); track backup.id) {
          <mat-card class="backup-item">
            <div class="backup-info">
              <mat-icon>folder_zip</mat-icon>
              <div class="backup-details">
                <h4>{{ backup.filename }}</h4>
                <p>{{ backup.file_size | fileSize }} | {{ backup.created_at | date:'medium' }}</p>
                <p>Created by: {{ backup.created_by }}</p>
              </div>
            </div>
            
            <div class="backup-actions">
              <button mat-icon-button 
                      (click)="downloadBackup(backup)"
                      title="Download">
                <mat-icon>download</mat-icon>
              </button>
              
              <button mat-icon-button 
                      color="warn"
                      (click)="restoreBackup(backup)"
                      [disabled]="isBackupInProgress() || isRestoreInProgress()"
                      title="Restore">
                <mat-icon>restore</mat-icon>
              </button>
              
              <button mat-icon-button 
                      color="warn"
                      (click)="deleteBackup(backup)"
                      title="Delete">
                <mat-icon>delete</mat-icon>
              </button>
            </div>
          </mat-card>
        }
      }
    </div>
  </mat-card-content>
</mat-card>
```

#### 4.4 Confirmation Dialogs

**Restore Confirmation Dialog:**
```typescript
@Component({
  selector: 'app-restore-confirm-dialog',
  template: `
    <h2 mat-dialog-title>⚠️ Restore Database</h2>
    <mat-dialog-content>
      <p class="warning-text">
        <strong>WARNING: This is a destructive operation!</strong>
      </p>
      <p>Restoring this backup will:</p>
      <ul>
        <li>Delete ALL current data in the database</li>
        <li>Replace it with data from: <strong>{{ data.backup.filename }}</strong></li>
        <li>Disconnect all active users</li>
        <li>Require everyone to log in again</li>
      </ul>
      <p>This action <strong>CANNOT BE UNDONE</strong>.</p>
      
      <mat-checkbox [(ngModel)]="confirmed">
        I understand this will delete all current data
      </mat-checkbox>
    </mat-dialog-content>
    <mat-dialog-actions>
      <button mat-button (click)="onCancel()">Cancel</button>
      <button mat-raised-button 
              color="warn" 
              [disabled]="!confirmed"
              (click)="onConfirm()">
        Restore Database
      </button>
    </mat-dialog-actions>
  `,
  styles: [`
    .warning-text {
      color: #f44336;
      font-size: 16px;
      font-weight: 500;
      margin-bottom: 16px;
    }
    ul {
      margin: 16px 0;
    }
  `]
})
export class RestoreConfirmDialogComponent {
  confirmed = false;
  
  constructor(
    public dialogRef: MatDialogRef<RestoreConfirmDialogComponent>,
    @Inject(MAT_DIALOG_DATA) public data: { backup: Backup }
  ) {}
  
  onCancel(): void {
    this.dialogRef.close(false);
  }
  
  onConfirm(): void {
    this.dialogRef.close(true);
  }
}
```

---

### Phase 5: Safety & Error Handling

#### 5.1 Operation Locking Strategy
```
Backup Operation:
1. Check if ANY operation is running → Reject if yes
2. Acquire "backup" lock
3. Execute backup
4. Release lock
5. Handle errors → Release lock in finally block

Restore Operation:
1. Check if ANY operation is running → Reject if yes
2. Acquire "restore" lock
3. Execute restore
4. Release lock
5. Handle errors → Release lock in finally block

Scan Operation (existing):
1. Check if ANY operation is running → Reject if yes
2. Acquire "scan" lock
3. Execute scan
4. Release lock
```

#### 5.2 Error Scenarios & Handling

| Scenario | Backend Response | Frontend Action |
|----------|------------------|-----------------|
| Backup fails (disk full) | 500 error with message | Show error, release lock |
| Restore fails (corrupted file) | 500 error with message | Show error, release lock, recommend re-scan |
| Operation already running | 409 Conflict | Show "operation in progress" message |
| File not found | 404 Not Found | Refresh backup list |
| Insufficient permissions | 403 Forbidden | Show permission error |
| Database connection lost | 500 error | Show error, attempt reconnection |

#### 5.3 Rollback Strategy

**If Restore Fails:**
1. Backup service should keep at least 1 previous backup before restore
2. Auto-create emergency backup before restore (optional)
3. If restore fails, recommend:
   - Restore from previous backup
   - OR re-scan filesystem to rebuild database

---

### Phase 6: Testing Strategy

#### Unit Tests
- `test_backup_service.py` - Test backup creation, listing, deletion
- `test_restore_service.py` - Test restore operations
- `test_lock_service.py` - Test locking mechanism

#### Integration Tests
- Test complete backup → restore → verify cycle
- Test concurrent operation prevention
- Test file download
- Test cleanup of old backups

#### Manual Testing Checklist
- [ ] Create backup successfully
- [ ] List backups
- [ ] Download backup file
- [ ] Restore from backup
- [ ] Delete backup
- [ ] Try backup while scan running (should fail)
- [ ] Try restore while backup running (should fail)
- [ ] Test large database backup (>100MB)
- [ ] Test restore with corrupted file
- [ ] Test UI responsiveness during operations

---

### Phase 7: Documentation

#### Admin User Guide
Create: `docs/BACKUP_RESTORE_GUIDE.md`

Topics:
- How to create a backup
- How to download a backup
- How to restore from a backup
- What to do if restore fails
- Best practices for backup management
- Recovery procedures

#### Developer Documentation
Topics:
- Architecture overview
- Database schema
- API endpoints
- Service methods
- Adding automated backups (future)

---

## Implementation Timeline

### Week 1: Backend Foundation
- [ ] Database migrations for new tables
- [ ] Create models and schemas
- [ ] Implement BackupService
- [ ] Implement LockService
- [ ] Test backup creation locally

### Week 2: Backend Complete
- [ ] Implement RestoreService
- [ ] Create API endpoints
- [ ] Add error handling
- [ ] Write unit tests
- [ ] Test with real PostgreSQL

### Week 3: Frontend Implementation
- [ ] Create BackupService
- [ ] Update admin component
- [ ] Create dialogs
- [ ] Add UI for backup list
- [ ] Wire up all actions

### Week 4: Testing & Polish
- [ ] Integration testing
- [ ] Manual testing all scenarios
- [ ] UI/UX improvements
- [ ] Documentation
- [ ] Code review

---

## Security Considerations

1. **Admin-Only Access**
   - All endpoints require admin authentication
   - Use `get_current_active_admin` dependency

2. **File Path Validation**
   - Validate backup file paths to prevent path traversal
   - Only allow access to files in BACKUP_DIR

3. **Rate Limiting**
   - Limit backup creation to 1 per hour per user
   - Prevent backup spam

4. **Audit Logging**
   - Log all backup/restore operations
   - Include user ID, timestamp, and result

5. **Backup Encryption (Future)**
   - Consider encrypting backup files at rest
   - Use application-level encryption

---

## Optional Enhancements (Future)

1. **Automated Backups**
   - Scheduled backups (daily, weekly)
   - Backup retention policies

2. **Backup Verification**
   - Automatically verify backup integrity after creation
   - Test restore in isolated environment

3. **Incremental Backups**
   - Only backup changes since last backup
   - Reduce backup size and time

4. **Cloud Storage Integration**
   - Upload backups to S3/Azure/GCS
   - Disaster recovery from cloud

5. **Backup Comparison**
   - Compare two backups
   - Show what changed

6. **Email Notifications**
   - Notify admins when backup completes
   - Alert on backup failures

---

## Risks & Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Backup fails mid-process | High | Transactional backup, cleanup on failure |
| Restore corrupts database | Critical | Pre-restore backup, verification step |
| Disk space exhausted | High | Check free space before backup, auto-cleanup |
| Long restore time | Medium | Show progress, async operation |
| User triggers restore accidentally | Critical | Strong confirmation dialog, admin-only |
| Concurrent operations | High | Robust locking mechanism |

---

## Success Criteria

✅ Admin can create database backup
✅ Admin can download backup file
✅ Admin can restore from backup
✅ Admin can delete old backups
✅ System prevents concurrent operations
✅ Clear error messages on failure
✅ Backup/restore status visible in UI
✅ All operations logged
✅ Recovery path documented

---

End of Implementation Plan
