# Script 8: Generate File Viewer Component
# This script generates the file viewer that supports multiple formats

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Generating File Viewer Component..." -ForegroundColor Cyan
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

Write-Host "`n1. Creating File Viewer Component..." -ForegroundColor Yellow

$fileViewerComponentTs = @'
import { Component, Input, OnChanges, SimpleChanges, signal, effect } from '@angular/core';
import { CommonModule } from '@angular/common';
import { DomSanitizer, SafeResourceUrl } from '@angular/platform-browser';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatIconModule } from '@angular/material/icon';
import { FileService } from '../../../../core/services/file.service';
import { ProgressService } from '../../../../core/services/progress.service';
import { AuthService } from '../../../../core/services/auth.service';
import { FileNode, FileType } from '../../../../core/models/file.model';
import { ProgressStatus } from '../../../../core/models/progress.model';

@Component({
  selector: 'app-file-viewer',
  standalone: true,
  imports: [
    CommonModule,
    MatProgressSpinnerModule,
    MatIconModule
  ],
  templateUrl: './file-viewer.component.html',
  styleUrls: ['./file-viewer.component.scss']
})
export class FileViewerComponent implements OnChanges {
  @Input() file!: FileNode;

  fileType = signal<FileType>(FileType.UNKNOWN);
  fileContent = signal<string | SafeResourceUrl | null>(null);
  isLoading = signal(false);
  error = signal<string | null>(null);

  FileType = FileType;

  constructor(
    private fileService: FileService,
    private progressService: ProgressService,
    private authService: AuthService,
    private sanitizer: DomSanitizer
  ) {}

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['file'] && this.file) {
      this.loadFile();
    }
  }

  loadFile(): void {
    this.isLoading.set(true);
    this.error.set(null);
    this.fileContent.set(null);

    const fileType = this.fileService.getFileType(this.file.name);
    this.fileType.set(fileType);

    this.fileService.getFileContent(this.file.id).subscribe({
      next: (blob) => {
        this.processFileContent(blob, fileType);
        this.markAsViewed();
      },
      error: (error) => {
        this.isLoading.set(false);
        this.error.set('Error loading file content');
        console.error('Error:', error);
      }
    });
  }

  processFileContent(blob: Blob, fileType: FileType): void {
    switch (fileType) {
      case FileType.TEXT:
        this.loadTextFile(blob);
        break;
      case FileType.PDF:
        this.loadPdfFile(blob);
        break;
      case FileType.VIDEO:
        this.loadVideoFile(blob);
        break;
      case FileType.AUDIO:
        this.loadAudioFile(blob);
        break;
      case FileType.IMAGE:
        this.loadImageFile(blob);
        break;
      case FileType.EPUB:
        this.loadEpubFile(blob);
        break;
      default:
        this.error.set('Unsupported file type');
        this.isLoading.set(false);
    }
  }

  loadTextFile(blob: Blob): void {
    blob.text().then(text => {
      this.fileContent.set(text);
      this.isLoading.set(false);
    }).catch(error => {
      this.error.set('Error reading text file');
      this.isLoading.set(false);
    });
  }

  loadPdfFile(blob: Blob): void {
    const url = URL.createObjectURL(blob);
    this.fileContent.set(this.sanitizer.bypassSecurityTrustResourceUrl(url));
    this.isLoading.set(false);
  }

  loadVideoFile(blob: Blob): void {
    const url = URL.createObjectURL(blob);
    this.fileContent.set(this.sanitizer.bypassSecurityTrustResourceUrl(url));
    this.isLoading.set(false);
  }

  loadAudioFile(blob: Blob): void {
    const url = URL.createObjectURL(blob);
    this.fileContent.set(this.sanitizer.bypassSecurityTrustResourceUrl(url));
    this.isLoading.set(false);
  }

  loadImageFile(blob: Blob): void {
    const url = URL.createObjectURL(blob);
    this.fileContent.set(this.sanitizer.bypassSecurityTrustResourceUrl(url));
    this.isLoading.set(false);
  }

  loadEpubFile(blob: Blob): void {
    const url = URL.createObjectURL(blob);
    this.fileContent.set(url);
    this.isLoading.set(false);
  }

  markAsViewed(): void {
    const user = this.authService.currentUser();
    if (user) {
      this.progressService.updateProgress(
        user.id,
        this.file.id,
        ProgressStatus.IN_PROGRESS
      ).subscribe({
        error: (error) => {
          console.error('Error updating progress:', error);
        }
      });
    }
  }
}
'@

$fileViewerComponentHtml = @'
<div class="viewer-container">
  @if (isLoading()) {
    <div class="loading-spinner">
      <mat-spinner></mat-spinner>
      <p>Loading file...</p>
    </div>
  } @else if (error()) {
    <div class="error-state">
      <mat-icon>error</mat-icon>
      <p>{{ error() }}</p>
    </div>
  } @else if (fileContent()) {
    <div class="viewer-content">
      @switch (fileType()) {
        @case (FileType.TEXT) {
          <div class="text-viewer">{{ fileContent() }}</div>
        }
        @case (FileType.PDF) {
          <iframe 
            [src]="fileContent()" 
            class="pdf-viewer"
            frameborder="0">
          </iframe>
        }
        @case (FileType.VIDEO) {
          <video 
            [src]="fileContent()" 
            class="video-player" 
            controls>
            Your browser does not support video playback.
          </video>
        }
        @case (FileType.AUDIO) {
          <div class="audio-container">
            <div class="audio-info">
              <mat-icon>audio_file</mat-icon>
              <h3>{{ file.name }}</h3>
            </div>
            <audio 
              [src]="fileContent()" 
              class="audio-player" 
              controls>
              Your browser does not support audio playback.
            </audio>
          </div>
        }
        @case (FileType.IMAGE) {
          <div class="image-container">
            <img 
              [src]="fileContent()" 
              [alt]="file.name"
              class="image-viewer">
          </div>
        }
        @case (FileType.EPUB) {
          <div class="epub-container">
            <p class="epub-notice">
              <mat-icon>info</mat-icon>
              EPUB viewer will be implemented with ngx-epub-viewer library
            </p>
            <p>File: {{ file.name }}</p>
          </div>
        }
      }
    </div>
  }
</div>
'@

$fileViewerComponentScss = @'
.viewer-container {
  height: 100%;
  display: flex;
  flex-direction: column;
}

.viewer-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.text-viewer {
  flex: 1;
  overflow: auto;
  padding: 24px;
  background-color: white;
  font-family: 'Courier New', monospace;
  font-size: 14px;
  line-height: 1.6;
}

.pdf-viewer {
  flex: 1;
  width: 100%;
  height: 100%;
}

.video-player {
  width: 100%;
  max-height: 100%;
  background-color: black;
}

.audio-container {
  flex: 1;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  padding: 32px;
}

.audio-info {
  display: flex;
  align-items: center;
  gap: 16px;
  margin-bottom: 24px;
}

.audio-info mat-icon {
  font-size: 48px;
  width: 48px;
  height: 48px;
  color: #1976d2;
}

.audio-player {
  width: 100%;
  max-width: 600px;
}

.image-container {
  flex: 1;
  display: flex;
  justify-content: center;
  align-items: center;
  overflow: auto;
  padding: 16px;
  background-color: #f5f5f5;
}

.image-viewer {
  max-width: 100%;
  max-height: 100%;
  object-fit: contain;
}

.epub-container {
  flex: 1;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  padding: 32px;
}

.epub-notice {
  display: flex;
  align-items: center;
  gap: 8px;
  color: #666;
  margin-bottom: 16px;
}

.loading-spinner,
.error-state {
  flex: 1;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  gap: 16px;
}

.error-state {
  color: #f44336;
}

.error-state mat-icon {
  font-size: 64px;
  width: 64px;
  height: 64px;
}
'@

Create-File -Path (Join-Path $appPath "features\client\components\file-viewer.component.ts") -Content $fileViewerComponentTs
Create-File -Path (Join-Path $appPath "features\client\components\file-viewer.component.html") -Content $fileViewerComponentHtml
Create-File -Path (Join-Path $appPath "features\client\components\file-viewer.component.scss") -Content $fileViewerComponentScss

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "File Viewer Component Generated!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "`nNext step: Run 9-generate-app-config.ps1" -ForegroundColor Yellow
