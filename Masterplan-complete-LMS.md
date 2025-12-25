# Simple LMS – Incremental Development Roadmap (Production-Ready)

Tech Stack:
- Frontend: Angular (latest stable)
- Backend: FastAPI (Python)
- Database: PostgreSQL
- Auth: JWT
- File Storage: Local filesystem

Core Philosophy:
- Simple, elegant, non-enterprise LMS
- File system is the source of truth
- Operational safety > feature count
- Incremental, testable development
- AI-assisted, developer-controlled

---

## CURRENT IMPLEMENTATION STATUS (Baseline)

### ✅ Already Implemented

#### Authentication
- Login
- JWT-based authentication
- Logout (top panel)

#### Admin Features
- Admin panel
- Root folder input (absolute path)
- Root path persisted
- Manual scan trigger
- Idempotent filesystem scanner
- Scan summary:
  - Added
  - Updated
  - Removed

#### File System Representation
- Categories and courses derived from folders
- File/folder hierarchy persisted in DB
- FileNode tree structure

#### Content Viewer (Working)
- Video
- Audio
- PDF
- TXT
- DOC / DOCX

#### Frontend Layout
- Left panel: Tree navigation
- Top panel:
  - Logout
  - Admin button (right side)
- Content area for file viewers

---

## PHASE 1 – Configuration & Environment Management

### Backend
- Environment-based configuration:
  - dev / staging / prod
- Configurable settings:
  - Root path
  - Max file size
  - Allowed extensions
  - Scan depth (optional)
- Secure secrets handling
- Root path validation:
  - Exists
  - Read permissions
  - Canonical path resolution

### Frontend
- Config-driven behavior
- Admin UI validation for root path



# Prompt
I am building a small, production-ready LMS:

- Frontend: Angular (latest)
- Backend: FastAPI (Python)
- Database: PostgreSQL
- File storage: local filesystem
- Auth: JWT

I want **Phase 1 – Configuration & Environment Management** implemented.

Requirements:

1. Backend:
   - Support dev, staging, prod environments
   - Configurable settings: root folder path, max file size, allowed extensions, scan depth
   - Secure secrets handling
   - Root path validation: exists, readable, canonical

2. Frontend:
   - Admin UI validates root folder input
   - Enforces config rules (e.g., max file size)

Constraints:
- Minimal complexity
- Production-safe
- Python 3.11+ / Angular latest
- Non-enterprise

Output:
- Folder structure for environment configs
- Sample environment files
- FastAPI code to load configs safely per environment
- Angular service/module for config enforcement and validation
- Root folder validation logic
- Copy-paste-ready code snippets only
- Short, clear explanations if necessary

---

## PHASE 2 – Security Hardening

### Backend
- Path traversal protection (`../`)
- Symlink detection & blocking
- MIME type validation
- File extension allow-list
- Per-file size limits
- Rate limiting on scan & admin endpoints

---

## PHASE 3 – Scanner Reliability & Failure Handling

### Backend
- Scan state machine:
  - Pending
  - Running
  - Completed
  - Failed
  - Partial
- Transaction boundaries for scans
- Partial scan handling
- Retry-safe idempotency
- Concurrent scan prevention (locking)

### Database
- Scan history table
- File-level scan error logging

### Frontend
- Disable scan during active run
- Show scan status & last run
- Partial/failure indicators

---

## PHASE 4 – Background Processing Model

### Backend
- Long-running scans executed in background
- Heartbeat / keep-alive
- Graceful shutdown handling
- Safe abort on application stop

---

## PHASE 5 – Logging & Observability

### Backend
- Structured logging
- Correlation ID per request & scan
- File-level scan logs
- Access logs for file streaming

### Admin
- View scan logs
- Filter by status/date

---

## PHASE 6 – Core Domain Finalization

### Backend Models
- User
- Category
- Course
- FileNode
- Enrollment
- ScanHistory
- ScanLog

### Data Integrity
- Unique constraints
- Case-normalization
- Orphan cleanup utilities

---

## PHASE 7 – Tree Navigation & Frontend State Control

### Frontend
- Centralized tree state service
- Expand/collapse persistence
- Lazy loading
- Refresh after scans
- Selected node sync

---

## PHASE 8 – Enrollment & Authorization Model

### Backend
- Enrollment table
- Action-level permission checks
- Admin override logic

### Frontend
- Tree filtering by enrollment
- Admin sees all

---

## PHASE 9 – Progress Tracking (Lightweight)

### Backend
- Last opened file
- Completion status
- Resume capability

### Frontend
- Visual progress indicators

---

## PHASE 10 – Admin Panel (Operational Control Center)

### Scanner Controls
- Scan entire root
- Scan single course
- View scan history
- View scan logs
- Cleanup orphaned DB entries

### Database Backup & Restore (NEW)

#### Backup
- Manual backup trigger from Admin UI
- Timestamped backups
- Metadata stored:
  - Backup date
  - Size
  - Triggered by user
- Download backup file

#### Restore
- Upload backup file via Admin UI
- Restore confirmation dialog (destructive warning)
- Automatic application maintenance mode during restore
- Post-restore integrity check
- Optional filesystem re-scan after restore

#### Safety Rules
- Admin-only access
- One operation at a time (lock)
- Clear success/failure feedback

---

## PHASE 11 – UX Polish & Performance

### Frontend
- Skeleton loaders
- Error boundaries
- Keyboard navigation
- Accessibility basics
- Mobile responsiveness

### Backend
- Query optimization
- Optional caching

---

## PHASE 12 – Disaster Recovery Strategy

### Strategy
- Admin-triggered DB backup & restore
- Filesystem as source of truth
- Full rescan as recovery path
- Clear recovery documentation

---
## PHASE 13 – Discovery, Search & Notifications

### Backend
- Unified search:
  - Courses
  - Files (name, path, type)
- Announcement support:
  - Course announcements
  - New course / new content updates
- Notification feed API:
  - Time-ordered updates
  - Lightweight read / unread tracking (optional)

### Frontend
- Global search (courses + files)
- Notification bell icon in top navigation
- Notification panel showing:
  - New courses
  - New files
  - Course announcements
- Click-through navigation from notification to content
- Simple visual indicators for new updates


## PHASE 14 – Dockerized Deployment

### Container Strategy
- Single Docker image including:
  - FastAPI backend
  - Angular frontend (production build)
  - All required dependencies
- Configuration via environment variables

### Filesystem Handling
- Configurable courses root path:
  - Inside container
  - OR external host path (bind mount)
- Support large content libraries via volumes

### Deployment
- Pull source from GitHub
- Build and run with Docker
- One-command launch (`docker run` or `docker-compose`)
- Clear documentation for:
  - Volume mounting
  - Path configuration
--

## Optional Future Enhancements

- Search (courses / files)
- Course announcements
- Certificates (PDF)
- Background workers
- S3-compatible storage

---

## Explicit Non-Goals

- SCORM / xAPI
- Payments
- Multi-tenancy
- HR integrations
- Enterprise reporting
- Marketplace features

---

## Guiding Principles

- File system remains source of truth
- Operational safety > features
- Simple architecture
- Explicit over clever
- AI assists, developers decide

---

End of roadmap.
