import { Component, Input, OnChanges, SimpleChanges, signal, ViewChild, ElementRef, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { DomSanitizer, SafeResourceUrl } from '@angular/platform-browser';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonModule } from '@angular/material/button';
import ePub from 'epubjs';
import { FileService } from '../../../core/services/file.service';
import { ProgressService } from '../../../core/services/progress.service';
import { AuthService } from '../../../core/services/auth.service';
import { FileNode, FileType } from '../../../core/models/file.model';
import { ProgressStatus } from '../../../core/models/progress.model';

@Component({
  selector: 'app-file-viewer',
  standalone: true,
  imports: [
    CommonModule,
    MatProgressSpinnerModule,
    MatIconModule,
    MatButtonModule
  ],
  templateUrl: './file-viewer.component.html',
  styleUrls: ['./file-viewer.component.scss']
})
export class FileViewerComponent implements OnChanges, OnDestroy {
  @Input() file!: FileNode;
  @ViewChild('epubViewer', { static: false }) epubViewerRef!: ElementRef;

  fileType = signal<FileType>(FileType.UNKNOWN);
  fileContent = signal<string | SafeResourceUrl | null>(null);
  isLoading = signal(false);
  error = signal<string | null>(null);

  // EPUB specific properties
  private epubBook: any = null;
  private epubRendition: any = null;
  epubReady = signal(false);

  FileType = FileType;

  constructor(
    private fileService: FileService,
    private progressService: ProgressService,
    private authService: AuthService,
    private sanitizer: DomSanitizer
  ) {}

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['file'] && this.file) {
      // Clean up previous EPUB if exists
      this.cleanupEpub();
      this.loadFile();
    }
  }

  ngOnDestroy(): void {
    this.cleanupEpub();
  }

  private cleanupEpub(): void {
    if (this.epubRendition) {
      this.epubRendition.destroy();
      this.epubRendition = null;
    }
    if (this.epubBook) {
      this.epubBook.destroy();
      this.epubBook = null;
    }
    this.epubReady.set(false);
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
    // Convert blob to ArrayBuffer for epub.js
    blob.arrayBuffer().then(buffer => {
      this.fileContent.set(buffer);
      this.isLoading.set(false);
      // Initialize EPUB after view is ready
      setTimeout(() => this.initializeEpub(buffer), 100);
    }).catch(error => {
      this.error.set('Error loading EPUB file');
      this.isLoading.set(false);
      console.error('Error loading EPUB:', error);
    });
  }

  private initializeEpub(buffer: ArrayBuffer): void {
    if (!this.epubViewerRef) {
      console.error('EPUB viewer element not found');
      return;
    }

    try {
      // Create the EPUB book
      this.epubBook = ePub(buffer);
      
      // Render to the viewer element
      this.epubRendition = this.epubBook.renderTo(this.epubViewerRef.nativeElement, {
        width: '100%',
        height: '100%',
        spread: 'none'
      });

      // Display the first page
      this.epubRendition.display();
      this.epubReady.set(true);
    } catch (error) {
      console.error('Error initializing EPUB:', error);
      this.error.set('Failed to initialize EPUB viewer');
    }
  }

  // Navigation methods for EPUB
  epubNext(): void {
    if (this.epubRendition) {
      this.epubRendition.next();
    }
  }

  epubPrev(): void {
    if (this.epubRendition) {
      this.epubRendition.prev();
    }
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
