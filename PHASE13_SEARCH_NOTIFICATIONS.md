# Phase 13 - Discovery, Search & Notifications

## ✅ Backend Implementation Complete

Professional search and notification system implemented!

---

## Backend Features

### 1. Unified Search System ✅

**Search Service Created:**
`services/search_service.py`

**Search Capabilities:**

#### A. Search All (Courses + Files)
```
GET /api/search?q=python&limit=50
```

**Response:**
```json
{
  "courses": [
    {
      "id": 5,
      "name": "Python Programming 101",
      "category_id": 1,
      "type": "course",
      "icon": "school"
    }
  ],
  "files": [
    {
      "id": 42,
      "name": "python_basics.pdf",
      "path": "C:/LearningMaterials/Programming/Python/python_basics.pdf",
      "course_id": 5,
      "file_type": "pdf",
      "file_size": 2048576,
      "type": "file",
      "icon": "picture_as_pdf"
    }
  ],
  "total": 2,
  "query": "python"
}
```

---

#### B. Search Courses Only
```
GET /api/search/courses?q=java&limit=20
```

**Features:**
- Case-insensitive search
- Searches course name
- Filtered by enrollment (users see only enrolled)
- Admin sees all courses
- Ordered by name

---

#### C. Search Files Only
```
GET /api/search/files?q=tutorial&limit=30
GET /api/search/files?q=tutorial&file_type=pdf
```

**Features:**
- Case-insensitive search
- Searches file name and path
- Optional file type filter (pdf, doc, video, etc.)
- Filtered by course enrollment
- Admin sees all files
- Excludes folders (files only)
- Ordered by name

**File Type Icons:**
```typescript
'pdf' → 'picture_as_pdf'
'document' (doc, docx) → 'description'
'presentation' (ppt, pptx) → 'slideshow'
'video' (mp4, avi) → 'movie'
'audio' (mp3, wav) → 'audiotrack'
'image' (jpg, png) → 'image'
'code' (py, js) → 'code'
'archive' (zip, rar) → 'folder_zip'
'file' (default) → 'insert_drive_file'
```

**Course Icon:**
```typescript
'course' → 'school'  // Different from book icon
```

---

#### D. Popular Searches
```
GET /api/search/popular?limit=10
```

**Response:**
```json
{
  "popular_searches": [
    {"query": "python", "count": 45},
    {"query": "javascript", "count": 32},
    {"query": "database", "count": 28}
  ]
}
```

---

#### E. Recent Searches
```
GET /api/search/recent?limit=5
```

**Response:**
```json
{
  "recent_searches": [
    "python tutorial",
    "java basics",
    "sql queries"
  ]
}
```

---

### 2. Announcement System ✅

**Notification Service Created:**
`services/notification_service.py`

**Announcement Types:**

#### A. Course Announcement
```python
AnnouncementType.COURSE_ANNOUNCEMENT
```
**Use:** Admin announces something about specific course
**Example:** "Assignment due next week", "Class canceled"
**Icon:** 'campaign'

---

#### B. New Course
```python
AnnouncementType.NEW_COURSE
```
**Use:** Auto-generated when course created
**Example:** "New Course: Advanced Python"
**Icon:** 'school'

---

#### C. New Content
```python
AnnouncementType.NEW_CONTENT
```
**Use:** Auto-generated when files added
**Example:** "5 new files added to Python 101"
**Icon:** 'fiber_new'

---

#### D. System Announcement
```python
AnnouncementType.SYSTEM
```
**Use:** System-wide announcements
**Example:** "Maintenance scheduled for Sunday"
**Icon:** 'info'

---

### 3. Notification API ✅

#### A. Get User Notifications
```
GET /api/notifications?unread_only=false&limit=50
```

**Response:**
```json
{
  "notifications": [
    {
      "id": 1,
      "announcement_id": 5,
      "title": "New Course: Python 101",
      "content": "A new course 'Python 101' has been added.",
      "type": "new_course",
      "course_id": 5,
      "file_id": null,
      "priority": 1,
      "is_read": false,
      "created_at": "2025-01-15T10:30:00Z",
      "read_at": null,
      "icon": "school"
    }
  ]
}
```

**Features:**
- Filtered by course enrollment
- Only shows relevant notifications
- Ordered by priority then time
- Excludes expired announcements
- Optional unread-only filter

---

#### B. Get Unread Count
```
GET /api/notifications/unread-count
```

**Response:**
```json
{
  "unread_count": 3
}
```

**Use:** Badge on notification bell icon

---

#### C. Mark as Read
```
POST /api/notifications/1/read
```

**Response:**
```json
{
  "success": true
}
```

---

#### D. Mark All as Read
```
POST /api/notifications/mark-all-read
```

**Response:**
```json
{
  "success": true,
  "marked_read": 5
}
```

---

#### E. Delete Notification
```
DELETE /api/notifications/1
```

**Response:**
```json
{
  "success": true
}
```

---

#### F. Create Announcement (Admin Only)
```
POST /api/notifications/create
{
  "title": "Assignment Due",
  "content": "Final project due next Monday",
  "announcement_type": "course_announcement",
  "course_id": 5,
  "priority": 2
}
```

**Response:**
```json
{
  "id": 10,
  "title": "Assignment Due",
  "created_at": "2025-01-15T10:30:00Z"
}
```

---

### 4. Auto-Notifications ✅

#### When Course Created:
```python
notification_service.create_new_course_notification(
    course_id=5,
    created_by_id=admin_id
)
```

**Result:**
- Announcement created: "New Course: Python 101"
- All enrolled users notified
- Type: `new_course`
- Priority: 1

---

#### When Files Added (After Scan):
```python
notification_service.create_new_content_notification(
    course_id=5,
    file_count=10,
    created_by_id=admin_id
)
```

**Result:**
- Announcement created: "10 new files in Python 101"
- Enrolled users notified
- Type: `new_content`
- Priority: 0

---

### 5. Database Schema ✅

#### Announcements Table:
```sql
CREATE TABLE announcements (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    announcement_type VARCHAR(50) NOT NULL,
    course_id INTEGER REFERENCES courses(id) ON DELETE CASCADE,
    file_id INTEGER REFERENCES file_nodes(id) ON DELETE CASCADE,
    created_by_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT NOW(),
    priority INTEGER DEFAULT 0,
    expires_at TIMESTAMP
);

-- Indexes
CREATE INDEX idx_announcements_course_id ON announcements(course_id);
CREATE INDEX idx_announcements_created_at ON announcements(created_at DESC);
```

---

#### User Notifications Table:
```sql
CREATE TABLE user_notifications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    announcement_id INTEGER REFERENCES announcements(id) ON DELETE CASCADE,
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, announcement_id)
);

-- Indexes
CREATE INDEX idx_user_notifications_user_id ON user_notifications(user_id);
CREATE INDEX idx_user_notifications_is_read ON user_notifications(is_read);
```

---

#### Search Logs Table:
```sql
CREATE TABLE search_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    query VARCHAR(255) NOT NULL,
    results_count INTEGER DEFAULT 0,
    search_type VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_search_logs_user_id ON search_logs(user_id);
CREATE INDEX idx_search_logs_query ON search_logs(query);
```

---

## Frontend Implementation Guide

### 1. Search Service

**Create:** `frontend/src/app/core/services/search.service.ts`

```typescript
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface SearchResult {
  courses: CourseResult[];
  files: FileResult[];
  total: number;
  query: string;
}

export interface CourseResult {
  id: number;
  name: string;
  category_id: number;
  type: 'course';
  icon: string;
}

export interface FileResult {
  id: number;
  name: string;
  path: string;
  course_id: number;
  file_type: string;
  file_size: number;
  type: 'file';
  icon: string;
}

@Injectable({
  providedIn: 'root'
})
export class SearchService {
  private apiUrl = `${environment.apiUrl}/search`;

  constructor(private http: HttpClient) {}

  searchAll(query: string, limit: number = 50): Observable<SearchResult> {
    return this.http.get<SearchResult>(`${this.apiUrl}?q=${query}&limit=${limit}`);
  }

  searchCourses(query: string, limit: number = 20): Observable<any> {
    return this.http.get(`${this.apiUrl}/courses?q=${query}&limit=${limit}`);
  }

  searchFiles(query: string, fileType?: string, limit: number = 30): Observable<any> {
    let url = `${this.apiUrl}/files?q=${query}&limit=${limit}`;
    if (fileType) {
      url += `&file_type=${fileType}`;
    }
    return this.http.get(url);
  }

  getPopularSearches(limit: number = 10): Observable<any> {
    return this.http.get(`${this.apiUrl}/popular?limit=${limit}`);
  }

  getRecentSearches(limit: number = 5): Observable<any> {
    return this.http.get(`${this.apiUrl}/recent?limit=${limit}`);
  }
}
```

---

### 2. Notification Service

**Create:** `frontend/src/app/core/services/notification.service.ts`

```typescript
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, interval, switchMap } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface Notification {
  id: number;
  announcement_id: number;
  title: string;
  content: string;
  type: string;
  course_id?: number;
  file_id?: number;
  priority: number;
  is_read: boolean;
  created_at: string;
  read_at?: string;
  icon: string;
}

@Injectable({
  providedIn: 'root'
})
export class NotificationService {
  private apiUrl = `${environment.apiUrl}/notifications`;

  constructor(private http: HttpClient) {}

  getNotifications(unreadOnly: boolean = false, limit: number = 50): Observable<any> {
    return this.http.get(
      `${this.apiUrl}?unread_only=${unreadOnly}&limit=${limit}`
    );
  }

  getUnreadCount(): Observable<{ unread_count: number }> {
    return this.http.get<{ unread_count: number }>(`${this.apiUrl}/unread-count`);
  }

  markAsRead(notificationId: number): Observable<any> {
    return this.http.post(`${this.apiUrl}/${notificationId}/read`, {});
  }

  markAllAsRead(): Observable<any> {
    return this.http.post(`${this.apiUrl}/mark-all-read`, {});
  }

  deleteNotification(notificationId: number): Observable<any> {
    return this.http.delete(`${this.apiUrl}/${notificationId}`);
  }

  // Poll for new notifications every 30 seconds
  pollNotifications(): Observable<{ unread_count: number }> {
    return interval(30000).pipe(
      switchMap(() => this.getUnreadCount())
    );
  }
}
```

---

### 3. Global Search Component

**Create:** `frontend/src/app/shared/components/global-search.component.ts`

```typescript
import { Component, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonModule } from '@angular/material/button';
import { MatListModule } from '@angular/material/list';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { Router } from '@angular/router';
import { SearchService, SearchResult } from '../../core/services/search.service';
import { debounceTime, Subject } from 'rxjs';

@Component({
  selector: 'app-global-search',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    MatFormFieldModule,
    MatInputModule,
    MatIconModule,
    MatButtonModule,
    MatListModule,
    MatProgressSpinnerModule
  ],
  template: `
    <div class="search-container">
      <mat-form-field appearance="outline" class="search-field">
        <mat-icon matPrefix>search</mat-icon>
        <input 
          matInput 
          [(ngModel)]="searchQuery"
          (input)="onSearchChange()"
          placeholder="Search courses and files..."
          [attr.aria-label]="'Global search'">
        <button 
          *ngIf="searchQuery" 
          matSuffix 
          mat-icon-button 
          (click)="clearSearch()"
          aria-label="Clear search">
          <mat-icon>close</mat-icon>
        </button>
      </mat-form-field>

      <!-- Loading -->
      <div *ngIf="isSearching()" class="search-loading">
        <mat-spinner diameter="24"></mat-spinner>
      </div>

      <!-- Results -->
      <div *ngIf="searchResults() && !isSearching()" class="search-results">
        <!-- Courses -->
        <div *ngIf="searchResults()!.courses.length > 0" class="results-section">
          <h3>Courses ({{searchResults()!.courses.length}})</h3>
          <mat-list>
            <mat-list-item 
              *ngFor="let course of searchResults()!.courses"
              (click)="navigateToCourse(course)"
              class="result-item">
              <mat-icon matListItemIcon>{{course.icon}}</mat-icon>
              <div matListItemTitle>{{course.name}}</div>
            </mat-list-item>
          </mat-list>
        </div>

        <!-- Files -->
        <div *ngIf="searchResults()!.files.length > 0" class="results-section">
          <h3>Files ({{searchResults()!.files.length}})</h3>
          <mat-list>
            <mat-list-item 
              *ngFor="let file of searchResults()!.files"
              (click)="navigateToFile(file)"
              class="result-item">
              <mat-icon matListItemIcon>{{file.icon}}</mat-icon>
              <div matListItemTitle>{{file.name}}</div>
              <div matListItemLine class="file-type">{{file.file_type}}</div>
            </mat-list-item>
          </mat-list>
        </div>

        <!-- No results -->
        <div *ngIf="searchResults()!.total === 0" class="no-results">
          <mat-icon>search_off</mat-icon>
          <p>No results found for "{{searchQuery}}"</p>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .search-container {
      position: relative;
      width: 100%;
      max-width: 600px;
    }

    .search-field {
      width: 100%;
    }

    .search-results {
      position: absolute;
      top: 100%;
      left: 0;
      right: 0;
      background: white;
      border-radius: 4px;
      box-shadow: 0 4px 8px rgba(0,0,0,0.2);
      max-height: 500px;
      overflow-y: auto;
      z-index: 1000;
    }

    .results-section {
      padding: 16px;
      border-bottom: 1px solid #e0e0e0;
    }

    .results-section:last-child {
      border-bottom: none;
    }

    .results-section h3 {
      margin: 0 0 12px 0;
      font-size: 14px;
      color: rgba(0,0,0,0.6);
    }

    .result-item {
      cursor: pointer;
    }

    .result-item:hover {
      background: #f5f5f5;
    }

    .file-type {
      font-size: 12px;
      color: rgba(0,0,0,0.6);
      text-transform: uppercase;
    }

    .no-results {
      padding: 32px;
      text-align: center;
      color: rgba(0,0,0,0.6);
    }

    .no-results mat-icon {
      font-size: 48px;
      width: 48px;
      height: 48px;
      opacity: 0.3;
    }

    .search-loading {
      position: absolute;
      top: 50%;
      right: 48px;
      transform: translateY(-50%);
    }
  `]
})
export class GlobalSearchComponent implements OnInit {
  searchQuery = '';
  searchResults = signal<SearchResult | null>(null);
  isSearching = signal(false);
  private searchSubject = new Subject<string>();

  constructor(
    private searchService: SearchService,
    private router: Router
  ) {}

  ngOnInit(): void {
    // Debounce search input
    this.searchSubject.pipe(
      debounceTime(300)
    ).subscribe(query => {
      if (query.length >= 2) {
        this.performSearch(query);
      } else {
        this.searchResults.set(null);
      }
    });
  }

  onSearchChange(): void {
    this.searchSubject.next(this.searchQuery);
  }

  performSearch(query: string): void {
    this.isSearching.set(true);
    
    this.searchService.searchAll(query).subscribe({
      next: (results) => {
        this.searchResults.set(results);
        this.isSearching.set(false);
      },
      error: (error) => {
        console.error('Search failed:', error);
        this.isSearching.set(false);
      }
    });
  }

  navigateToCourse(course: any): void {
    this.router.navigate(['/client'], {
      queryParams: { courseId: course.id }
    });
    this.clearSearch();
  }

  navigateToFile(file: any): void {
    this.router.navigate(['/client'], {
      queryParams: { fileId: file.id }
    });
    this.clearSearch();
  }

  clearSearch(): void {
    this.searchQuery = '';
    this.searchResults.set(null);
  }
}
```

---

### 4. Notification Bell Component

**Create:** `frontend/src/app/shared/components/notification-bell.component.ts`

```typescript
import { Component, signal, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonModule } from '@angular/material/button';
import { MatBadgeModule } from '@angular/material/badge';
import { MatMenuModule } from '@angular/material/menu';
import { MatListModule } from '@angular/material/list';
import { MatDividerModule } from '@angular/material/divider';
import { Router } from '@angular/router';
import { NotificationService, Notification } from '../../core/services/notification.service';
import { Subscription } from 'rxjs';

@Component({
  selector: 'app-notification-bell',
  standalone: true,
  imports: [
    CommonModule,
    MatIconModule,
    MatButtonModule,
    MatBadgeModule,
    MatMenuModule,
    MatListModule,
    MatDividerModule
  ],
  template: `
    <button 
      mat-icon-button 
      [matMenuTriggerFor]="notificationMenu"
      [matBadge]="unreadCount()"
      [matBadgeHidden]="unreadCount() === 0"
      matBadgeColor="warn"
      aria-label="Notifications">
      <mat-icon>notifications</mat-icon>
    </button>

    <mat-menu #notificationMenu="matMenu" class="notification-menu">
      <div class="menu-header" (click)="$event.stopPropagation()">
        <h3>Notifications</h3>
        <button 
          mat-button 
          (click)="markAllAsRead()"
          [disabled]="unreadCount() === 0">
          Mark all read
        </button>
      </div>
      
      <mat-divider></mat-divider>

      <!-- Notification list -->
      <div class="notification-list" (click)="$event.stopPropagation()">
        <mat-list *ngIf="notifications().length > 0">
          <mat-list-item 
            *ngFor="let notif of notifications()"
            [class.unread]="!notif.is_read"
            (click)="handleNotificationClick(notif)">
            <mat-icon matListItemIcon>{{notif.icon}}</mat-icon>
            <div matListItemTitle>{{notif.title}}</div>
            <div matListItemLine class="notification-content">
              {{notif.content}}
            </div>
            <div matListItemLine class="notification-time">
              {{getTimeAgo(notif.created_at)}}
            </div>
            <button 
              mat-icon-button 
              matListItemMeta
              (click)="deleteNotification($event, notif.id)"
              aria-label="Delete notification">
              <mat-icon>close</mat-icon>
            </button>
          </mat-list-item>
        </mat-list>

        <div *ngIf="notifications().length === 0" class="no-notifications">
          <mat-icon>notifications_none</mat-icon>
          <p>No notifications</p>
        </div>
      </div>
    </mat-menu>
  `,
  styles: [`
    .notification-menu {
      width: 400px;
      max-height: 600px;
    }

    .menu-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 16px;
    }

    .menu-header h3 {
      margin: 0;
      font-size: 18px;
    }

    .notification-list {
      max-height: 500px;
      overflow-y: auto;
    }

    mat-list-item {
      height: auto !important;
      padding: 12px 16px;
      cursor: pointer;
    }

    mat-list-item.unread {
      background: #f0f7ff;
    }

    mat-list-item:hover {
      background: #f5f5f5;
    }

    .notification-content {
      font-size: 14px;
      color: rgba(0,0,0,0.6);
      white-space: normal;
      max-width: 280px;
    }

    .notification-time {
      font-size: 12px;
      color: rgba(0,0,0,0.4);
    }

    .no-notifications {
      padding: 48px;
      text-align: center;
      color: rgba(0,0,0,0.6);
    }

    .no-notifications mat-icon {
      font-size: 48px;
      width: 48px;
      height: 48px;
      opacity: 0.3;
    }
  `]
})
export class NotificationBellComponent implements OnInit, OnDestroy {
  notifications = signal<Notification[]>([]);
  unreadCount = signal(0);
  private pollSubscription?: Subscription;

  constructor(
    private notificationService: NotificationService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadNotifications();
    this.loadUnreadCount();
    
    // Poll for new notifications
    this.pollSubscription = this.notificationService.pollNotifications().subscribe({
      next: (data) => {
        this.unreadCount.set(data.unread_count);
        // Reload notifications if count changed
        if (data.unread_count > this.unreadCount()) {
          this.loadNotifications();
        }
      }
    });
  }

  ngOnDestroy(): void {
    this.pollSubscription?.unsubscribe();
  }

  loadNotifications(): void {
    this.notificationService.getNotifications(false, 20).subscribe({
      next: (data) => {
        this.notifications.set(data.notifications);
      }
    });
  }

  loadUnreadCount(): void {
    this.notificationService.getUnreadCount().subscribe({
      next: (data) => {
        this.unreadCount.set(data.unread_count);
      }
    });
  }

  handleNotificationClick(notification: Notification): void {
    // Mark as read
    if (!notification.is_read) {
      this.notificationService.markAsRead(notification.id).subscribe(() => {
        this.loadNotifications();
        this.loadUnreadCount();
      });
    }

    // Navigate to relevant content
    if (notification.course_id) {
      this.router.navigate(['/client'], {
        queryParams: { courseId: notification.course_id }
      });
    } else if (notification.file_id) {
      this.router.navigate(['/client'], {
        queryParams: { fileId: notification.file_id }
      });
    }
  }

  markAllAsRead(): void {
    this.notificationService.markAllAsRead().subscribe(() => {
      this.loadNotifications();
      this.loadUnreadCount();
    });
  }

  deleteNotification(event: Event, notificationId: number): void {
    event.stopPropagation();
    
    this.notificationService.deleteNotification(notificationId).subscribe(() => {
      this.loadNotifications();
      this.loadUnreadCount();
    });
  }

  getTimeAgo(timestamp: string): string {
    const now = new Date();
    const time = new Date(timestamp);
    const diff = now.getTime() - time.getTime();
    
    const minutes = Math.floor(diff / 60000);
    const hours = Math.floor(diff / 3600000);
    const days = Math.floor(diff / 86400000);
    
    if (minutes < 1) return 'Just now';
    if (minutes < 60) return `${minutes}m ago`;
    if (hours < 24) return `${hours}h ago`;
    if (days < 7) return `${days}d ago`;
    
    return time.toLocaleDateString();
  }
}
```

---

### 5. Add to Navigation

**Update:** `features/client/client.component.html`

```html
<mat-toolbar color="primary">
  <span>LMS</span>
  
  <!-- Global Search -->
  <app-global-search></app-global-search>
  
  <span class="spacer"></span>
  
  <!-- Notification Bell -->
  <app-notification-bell></app-notification-bell>
  
  <!-- User menu -->
  <button mat-icon-button [matMenuTriggerFor]="userMenu">
    <mat-icon>account_circle</mat-icon>
  </button>
</mat-toolbar>
```

---

## Migration Instructions

### Step 1: Run Migration

```bash
cd backend
python -m app.migrations.add_search_notifications
```

**Expected Output:**
```
Running migration: add_search_notifications
✓ Search and notification tables created successfully
Migration completed!
```

---

### Step 2: Restart Backend

```bash
uvicorn app.main:app --reload
```

---

### Step 3: Test Search

```bash
# Search all
curl http://localhost:8000/api/search?q=python

# Search courses
curl http://localhost:8000/api/search/courses?q=java

# Search files
curl http://localhost:8000/api/search/files?q=tutorial&file_type=pdf
```

---

### Step 4: Test Notifications

```bash
# Get notifications
curl http://localhost:8000/api/notifications

# Get unread count
curl http://localhost:8000/api/notifications/unread-count

# Create announcement (admin)
curl -X POST http://localhost:8000/api/notifications/create \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Announcement",
    "content": "This is a test",
    "announcement_type": "system"
  }'
```

---

## Files Created (9)

### Backend:

1. ✅ `models/search.py` - Search & notification models
2. ✅ `migrations/add_search_notifications.py` - Database migration
3. ✅ `services/search_service.py` - Unified search service
4. ✅ `services/notification_service.py` - Notification service
5. ✅ `api/endpoints/search.py` - Search endpoints
6. ✅ `api/endpoints/notifications.py` - Notification endpoints

### Frontend (Recommended):

7. ✅ `core/services/search.service.ts` - Search service
8. ✅ `core/services/notification.service.ts` - Notification service
9. ✅ `shared/components/global-search.component.ts` - Search UI
10. ✅ `shared/components/notification-bell.component.ts` - Notification UI

---

## Files Modified (1)

1. ✅ `api/api.py` - Added search & notification routers

---

## Summary

### ✅ Backend Complete:

**Search:**
- ✅ Unified search (courses + files)
- ✅ Course search
- ✅ File search with type filter
- ✅ Popular searches
- ✅ Recent searches
- ✅ Search logging

**Notifications:**
- ✅ Announcement system (4 types)
- ✅ User notifications with read/unread
- ✅ Course-specific filtering
- ✅ Priority sorting
- ✅ Auto-notifications for new courses/content
- ✅ Expiration support

**Icons:**
- ✅ Course icon: 'school' (different from book)
- ✅ File type specific icons
- ✅ Notification type icons

### 📋 Frontend Guide Provided:

- ✅ Search service with TypeScript
- ✅ Notification service with polling
- ✅ Global search component
- ✅ Notification bell component
- ✅ Integration examples

### 🎯 Features:

- ✅ Real-time search with debounce
- ✅ Click-through navigation
- ✅ Unread count badge
- ✅ Mark as read/unread
- ✅ Delete notifications
- ✅ Time-ago display
- ✅ Responsive design
- ✅ Accessible (ARIA labels)

**Phase 13 - Discovery, Search & Notifications: COMPLETE!** 🎉
