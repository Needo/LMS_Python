# Script 4: Generate Frontend Services
# This script generates all Angular services

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Generating Frontend Services..." -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

$rootPath = "C:\Users\munawar\Documents\Python_LMS_V2"
$frontendPath = Join-Path $rootPath "frontend"
$appPath = Join-Path $frontendPath "src\app"

# Function to create file with content
function Create-File {
    param (
        [string]$Path,
        [string]$Content
    )
    $directory = Split-Path $Path -Parent
    if (-not (Test-Path $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    Set-Content -Path $Path -Value $Content -Encoding UTF8
    Write-Host "Created: $Path" -ForegroundColor Green
}

Write-Host "`n1. Creating Auth Service..." -ForegroundColor Yellow

$authServiceContent = @'
import { Injectable, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, tap } from 'rxjs';
import { environment } from '../../../environments/environment';
import { User, LoginRequest, LoginResponse, RegisterRequest } from '../models/user.model';

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private apiUrl = `${environment.apiUrl}/auth`;
  private currentUserSignal = signal<User | null>(null);
  private isAuthenticatedSignal = signal<boolean>(false);

  currentUser = this.currentUserSignal.asReadonly();
  isAuthenticated = this.isAuthenticatedSignal.asReadonly();

  constructor(private http: HttpClient) {
    this.loadUserFromStorage();
  }

  login(credentials: LoginRequest): Observable<LoginResponse> {
    return this.http.post<LoginResponse>(`${this.apiUrl}/login`, credentials)
      .pipe(
        tap(response => {
          this.setSession(response);
        })
      );
  }

  register(data: RegisterRequest): Observable<User> {
    return this.http.post<User>(`${this.apiUrl}/register`, data);
  }

  logout(): void {
    localStorage.removeItem('access_token');
    localStorage.removeItem('current_user');
    this.currentUserSignal.set(null);
    this.isAuthenticatedSignal.set(false);
  }

  getToken(): string | null {
    return localStorage.getItem('access_token');
  }

  private setSession(authResult: LoginResponse): void {
    localStorage.setItem('access_token', authResult.access_token);
    localStorage.setItem('current_user', JSON.stringify(authResult.user));
    this.currentUserSignal.set(authResult.user);
    this.isAuthenticatedSignal.set(true);
  }

  private loadUserFromStorage(): void {
    const token = localStorage.getItem('access_token');
    const userStr = localStorage.getItem('current_user');
    
    if (token && userStr) {
      try {
        const user = JSON.parse(userStr);
        this.currentUserSignal.set(user);
        this.isAuthenticatedSignal.set(true);
      } catch (e) {
        this.logout();
      }
    }
  }
}
'@

Create-File -Path (Join-Path $appPath "core\services\auth.service.ts") -Content $authServiceContent

Write-Host "`n2. Creating Category Service..." -ForegroundColor Yellow

$categoryServiceContent = @'
import { Injectable, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, tap } from 'rxjs';
import { environment } from '../../../environments/environment';
import { Category } from '../models/user.model';

@Injectable({
  providedIn: 'root'
})
export class CategoryService {
  private apiUrl = `${environment.apiUrl}/categories`;
  private categoriesSignal = signal<Category[]>([]);

  categories = this.categoriesSignal.asReadonly();

  constructor(private http: HttpClient) {}

  getCategories(): Observable<Category[]> {
    return this.http.get<Category[]>(this.apiUrl)
      .pipe(
        tap(categories => this.categoriesSignal.set(categories))
      );
  }

  getCategoryById(id: number): Observable<Category> {
    return this.http.get<Category>(`${this.apiUrl}/${id}`);
  }
}
'@

Create-File -Path (Join-Path $appPath "core\services\category.service.ts") -Content $categoryServiceContent

Write-Host "`n3. Creating Course Service..." -ForegroundColor Yellow

$courseServiceContent = @'
import { Injectable, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, tap } from 'rxjs';
import { environment } from '../../../environments/environment';
import { Course } from '../models/user.model';

@Injectable({
  providedIn: 'root'
})
export class CourseService {
  private apiUrl = `${environment.apiUrl}/courses`;
  private coursesSignal = signal<Course[]>([]);

  courses = this.coursesSignal.asReadonly();

  constructor(private http: HttpClient) {}

  getCoursesByCategory(categoryId: number): Observable<Course[]> {
    return this.http.get<Course[]>(`${this.apiUrl}/category/${categoryId}`)
      .pipe(
        tap(courses => this.coursesSignal.set(courses))
      );
  }

  getCourseById(id: number): Observable<Course> {
    return this.http.get<Course>(`${this.apiUrl}/${id}`);
  }

  getAllCourses(): Observable<Course[]> {
    return this.http.get<Course[]>(this.apiUrl)
      .pipe(
        tap(courses => this.coursesSignal.set(courses))
      );
  }
}
'@

Create-File -Path (Join-Path $appPath "core\services\course.service.ts") -Content $courseServiceContent

Write-Host "`n4. Creating File Service..." -ForegroundColor Yellow

$fileServiceContent = @'
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { FileNode, FileType } from '../models/user.model';

@Injectable({
  providedIn: 'root'
})
export class FileService {
  private apiUrl = `${environment.apiUrl}/files`;

  constructor(private http: HttpClient) {}

  getFilesByCourse(courseId: number): Observable<FileNode[]> {
    return this.http.get<FileNode[]>(`${this.apiUrl}/course/${courseId}`);
  }

  getFileById(id: number): Observable<FileNode> {
    return this.http.get<FileNode>(`${this.apiUrl}/${id}`);
  }

  getFileContent(id: number): Observable<Blob> {
    return this.http.get(`${this.apiUrl}/${id}/content`, { 
      responseType: 'blob' 
    });
  }

  getFileType(filename: string): FileType {
    const ext = filename.split('.').pop()?.toLowerCase();
    
    switch (ext) {
      case 'pdf':
        return FileType.PDF;
      case 'mp4':
      case 'avi':
      case 'mkv':
      case 'mov':
      case 'webm':
        return FileType.VIDEO;
      case 'mp3':
      case 'wav':
      case 'ogg':
      case 'm4a':
        return FileType.AUDIO;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
        return FileType.IMAGE;
      case 'txt':
      case 'md':
      case 'log':
        return FileType.TEXT;
      case 'epub':
        return FileType.EPUB;
      default:
        return FileType.UNKNOWN;
    }
  }

  getFileIcon(fileType: FileType): string {
    switch (fileType) {
      case FileType.PDF:
        return 'picture_as_pdf';
      case FileType.VIDEO:
        return 'video_library';
      case FileType.AUDIO:
        return 'audio_file';
      case FileType.IMAGE:
        return 'image';
      case FileType.TEXT:
        return 'description';
      case FileType.EPUB:
        return 'menu_book';
      case FileType.FOLDER:
        return 'folder';
      default:
        return 'insert_drive_file';
    }
  }
}
'@

Create-File -Path (Join-Path $appPath "core\services\file.service.ts") -Content $fileServiceContent

Write-Host "`n5. Creating Progress Service..." -ForegroundColor Yellow

$progressServiceContent = @'
import { Injectable, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, tap } from 'rxjs';
import { environment } from '../../../environments/environment';
import { UserProgress, LastViewed, ProgressStatus } from '../models/user.model';

@Injectable({
  providedIn: 'root'
})
export class ProgressService {
  private apiUrl = `${environment.apiUrl}/progress`;
  private currentProgressSignal = signal<UserProgress | null>(null);
  private lastViewedSignal = signal<LastViewed | null>(null);

  currentProgress = this.currentProgressSignal.asReadonly();
  lastViewed = this.lastViewedSignal.asReadonly();

  constructor(private http: HttpClient) {}

  getUserProgress(userId: number, fileId: number): Observable<UserProgress> {
    return this.http.get<UserProgress>(`${this.apiUrl}/user/${userId}/file/${fileId}`)
      .pipe(
        tap(progress => this.currentProgressSignal.set(progress))
      );
  }

  updateProgress(userId: number, fileId: number, status: ProgressStatus, lastPosition?: number): Observable<UserProgress> {
    return this.http.post<UserProgress>(`${this.apiUrl}`, {
      userId,
      fileId,
      status,
      lastPosition
    }).pipe(
      tap(progress => this.currentProgressSignal.set(progress))
    );
  }

  getLastViewed(userId: number): Observable<LastViewed> {
    return this.http.get<LastViewed>(`${this.apiUrl}/user/${userId}/last-viewed`)
      .pipe(
        tap(lastViewed => this.lastViewedSignal.set(lastViewed))
      );
  }

  setLastViewed(userId: number, courseId: number, fileId: number): Observable<LastViewed> {
    return this.http.post<LastViewed>(`${this.apiUrl}/last-viewed`, {
      userId,
      courseId,
      fileId
    }).pipe(
      tap(lastViewed => this.lastViewedSignal.set(lastViewed))
    );
  }

  getAllUserProgress(userId: number): Observable<UserProgress[]> {
    return this.http.get<UserProgress[]>(`${this.apiUrl}/user/${userId}`);
  }
}
'@

Create-File -Path (Join-Path $appPath "core\services\progress.service.ts") -Content $progressServiceContent

Write-Host "`n6. Creating Scanner Service..." -ForegroundColor Yellow

$scannerServiceContent = @'
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { ScanRequest, ScanResult } from '../models/user.model';

@Injectable({
  providedIn: 'root'
})
export class ScannerService {
  private apiUrl = `${environment.apiUrl}/scanner`;

  constructor(private http: HttpClient) {}

  scanRootFolder(request: ScanRequest): Observable<ScanResult> {
    return this.http.post<ScanResult>(`${this.apiUrl}/scan`, request);
  }

  rescanCourse(courseId: number): Observable<ScanResult> {
    return this.http.post<ScanResult>(`${this.apiUrl}/rescan/${courseId}`, {});
  }

  getRootPath(): Observable<{ rootPath: string }> {
    return this.http.get<{ rootPath: string }>(`${this.apiUrl}/root-path`);
  }

  setRootPath(rootPath: string): Observable<{ success: boolean }> {
    return this.http.post<{ success: boolean }>(`${this.apiUrl}/root-path`, { rootPath });
  }
}
'@

Create-File -Path (Join-Path $appPath "core\services\scanner.service.ts") -Content $scannerServiceContent

Write-Host "`n7. Creating services index file..." -ForegroundColor Yellow

$servicesIndexContent = @'
export * from './auth.service';
export * from './category.service';
export * from './course.service';
export * from './file.service';
export * from './progress.service';
export * from './scanner.service';
'@

Create-File -Path (Join-Path $appPath "core\services\index.ts") -Content $servicesIndexContent

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "Frontend Services Generated!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "`nNext step: Run 5-generate-frontend-components.ps1" -ForegroundColor Yellow
