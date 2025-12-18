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
