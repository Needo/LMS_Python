# Script 6: Generate Admin Components
# This script generates the admin panel components

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Generating Admin Components..." -ForegroundColor Cyan
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

Write-Host "`n1. Creating Admin Dashboard Component..." -ForegroundColor Yellow

$adminComponentTs = @'
import { Component, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { MatToolbarModule } from '@angular/material/toolbar';
import { MatButtonModule } from '@angular/material/button';
import { MatCardModule } from '@angular/material/card';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';
import { MatIconModule } from '@angular/material/icon';
import { AuthService } from '../../../core/services/auth.service';
import { ScannerService } from '../../../core/services/scanner.service';
import { ScanResult } from '../../../core/models/scan.model';

@Component({
  selector: 'app-admin',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    MatToolbarModule,
    MatButtonModule,
    MatCardModule,
    MatFormFieldModule,
    MatInputModule,
    MatProgressSpinnerModule,
    MatSnackBarModule,
    MatIconModule
  ],
  templateUrl: './admin.component.html',
  styleUrls: ['./admin.component.scss']
})
export class AdminComponent implements OnInit {
  rootPath = signal<string>('');
  isScanning = signal(false);
  scanResult = signal<ScanResult | null>(null);
  currentUser = this.authService.currentUser;

  constructor(
    private authService: AuthService,
    private scannerService: ScannerService,
    private router: Router,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit(): void {
    this.loadRootPath();
  }

  loadRootPath(): void {
    this.scannerService.getRootPath().subscribe({
      next: (response) => {
        this.rootPath.set(response.rootPath || '');
      },
      error: (error) => {
        console.error('Error loading root path:', error);
      }
    });
  }

  saveRootPath(): void {
    const path = this.rootPath();
    if (!path) {
      this.snackBar.open('Please enter a valid path', 'Close', { duration: 3000 });
      return;
    }

    this.scannerService.setRootPath(path).subscribe({
      next: () => {
        this.snackBar.open('Root path saved successfully', 'Close', { duration: 3000 });
      },
      error: (error) => {
        this.snackBar.open('Error saving root path', 'Close', { duration: 3000 });
        console.error('Error:', error);
      }
    });
  }

  scanFolder(): void {
    const path = this.rootPath();
    if (!path) {
      this.snackBar.open('Please enter and save a root path first', 'Close', { duration: 3000 });
      return;
    }

    this.isScanning.set(true);
    this.scanResult.set(null);

    this.scannerService.scanRootFolder({ rootPath: path }).subscribe({
      next: (result) => {
        this.isScanning.set(false);
        this.scanResult.set(result);
        if (result.success) {
          this.snackBar.open('Scan completed successfully!', 'Close', { duration: 3000 });
        } else {
          this.snackBar.open('Scan completed with errors', 'Close', { duration: 3000 });
        }
      },
      error: (error) => {
        this.isScanning.set(false);
        this.snackBar.open('Error during scan', 'Close', { duration: 3000 });
        console.error('Scan error:', error);
      }
    });
  }

  navigateToClient(): void {
    this.router.navigate(['/client']);
  }

  logout(): void {
    this.authService.logout();
    this.router.navigate(['/auth/login']);
  }
}
'@

$adminComponentHtml = @'
<div class="full-height">
  <mat-toolbar class="app-toolbar">
    <span>LMS Admin Panel</span>
    <span class="toolbar-spacer"></span>
    <span class="user-info">{{ currentUser()?.username }}</span>
    <button mat-button (click)="navigateToClient()">
      <mat-icon>school</mat-icon>
      Client View
    </button>
    <button mat-button (click)="logout()">
      <mat-icon>logout</mat-icon>
      Logout
    </button>
  </mat-toolbar>

  <div class="content-container">
    <div class="admin-content">
      <mat-card class="settings-card">
        <mat-card-header>
          <mat-card-title>Root Folder Settings</mat-card-title>
        </mat-card-header>
        <mat-card-content>
          <p>Configure the root folder containing your learning materials.</p>
          <p class="hint">The system will automatically scan for Categories (Courses, Books, Novels, Pictures) and any custom folders.</p>
          
          <mat-form-field class="full-width">
            <mat-label>Root Folder Path</mat-label>
            <input matInput 
                   [(ngModel)]="rootPath" 
                   placeholder="e.g., C:\LearningMaterials"
                   (ngModelChange)="rootPath.set($event)">
          </mat-form-field>

          <div class="action-buttons">
            <button mat-raised-button color="primary" (click)="saveRootPath()">
              <mat-icon>save</mat-icon>
              Save Path
            </button>
            <button mat-raised-button 
                    color="accent" 
                    (click)="scanFolder()" 
                    [disabled]="isScanning() || !rootPath()">
              @if (isScanning()) {
                <mat-spinner diameter="20"></mat-spinner>
                Scanning...
              } @else {
                <mat-icon>folder_open</mat-icon>
                Scan Folder
              }
            </button>
          </div>
        </mat-card-content>
      </mat-card>

      @if (scanResult()) {
        <mat-card class="results-card">
          <mat-card-header>
            <mat-card-title>Scan Results</mat-card-title>
          </mat-card-header>
          <mat-card-content>
            <div class="scan-result">
              <div class="result-item">
                <mat-icon class="icon-success">check_circle</mat-icon>
                <span>Status: {{ scanResult()!.message }}</span>
              </div>
              <div class="result-item">
                <mat-icon>category</mat-icon>
                <span>Categories Found: {{ scanResult()!.categoriesFound }}</span>
              </div>
              <div class="result-item">
                <mat-icon>school</mat-icon>
                <span>Courses Found: {{ scanResult()!.coursesFound }}</span>
              </div>
              <div class="result-item">
                <mat-icon>add</mat-icon>
                <span>Files Added: {{ scanResult()!.filesAdded }}</span>
              </div>
              <div class="result-item">
                <mat-icon>remove</mat-icon>
                <span>Files Removed: {{ scanResult()!.filesRemoved }}</span>
              </div>
              <div class="result-item">
                <mat-icon>update</mat-icon>
                <span>Files Updated: {{ scanResult()!.filesUpdated }}</span>
              </div>
            </div>
          </mat-card-content>
        </mat-card>
      }
    </div>
  </div>
</div>
'@

$adminComponentScss = @'
.admin-content {
  max-width: 800px;
  margin: 24px auto;
  padding: 16px;
}

.settings-card,
.results-card {
  margin-bottom: 24px;
}

.full-width {
  width: 100%;
}

.hint {
  color: #666;
  font-size: 14px;
  margin-bottom: 16px;
}

.user-info {
  margin-right: 16px;
  font-weight: 500;
}

.scan-result {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.result-item {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 16px;
}

.icon-success {
  color: #4caf50;
}

mat-icon {
  vertical-align: middle;
}
'@

Create-File -Path (Join-Path $appPath "features\admin\admin.component.ts") -Content $adminComponentTs
Create-File -Path (Join-Path $appPath "features\admin\admin.component.html") -Content $adminComponentHtml
Create-File -Path (Join-Path $appPath "features\admin\admin.component.scss") -Content $adminComponentScss

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "Admin Components Generated!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "`nNext step: Run 7-generate-client-components.ps1" -ForegroundColor Yellow
