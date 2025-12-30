import { Component, Input, Output, EventEmitter, signal, OnInit, OnChanges } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatTableModule } from '@angular/material/table';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonModule } from '@angular/material/button';
import { FileService } from '../../../core/services/file.service';
import { FileNode, FileType } from '../../../core/models/file.model';
import { FileSizePipe } from '../../../shared/pipes/file-size.pipe';

@Component({
  selector: 'app-folder-viewer',
  standalone: true,
  imports: [
    CommonModule,
    MatTableModule,
    MatIconModule,
    MatButtonModule,
    FileSizePipe
  ],
  template: `
    <div class="folder-viewer-container">
      <!-- Header -->
      <div class="folder-header">
        <mat-icon>folder_open</mat-icon>
        <h2>{{ folderName }}</h2>
      </div>

      <!-- Contents Table -->
      <div class="table-container" *ngIf="!isLoading() && contents().length > 0">
        <table mat-table [dataSource]="contents()" class="contents-table">
          
          <!-- Icon Column -->
          <ng-container matColumnDef="icon">
            <th mat-header-cell *matHeaderCellDef>Type</th>
            <td mat-cell *matCellDef="let item">
              <mat-icon [class]="getIconClass(item)">
                {{ getIcon(item) }}
              </mat-icon>
            </td>
          </ng-container>

          <!-- Name Column -->
          <ng-container matColumnDef="name">
            <th mat-header-cell *matHeaderCellDef>Name</th>
            <td mat-cell *matCellDef="let item" class="name-cell">
              {{ item.name }}
            </td>
          </ng-container>

          <!-- Type Column -->
          <ng-container matColumnDef="type">
            <th mat-header-cell *matHeaderCellDef>Type</th>
            <td mat-cell *matCellDef="let item">
              {{ item.isDirectory ? 'Folder' : getFileTypeLabel(item.name) }}
            </td>
          </ng-container>

          <!-- Size Column -->
          <ng-container matColumnDef="size">
            <th mat-header-cell *matHeaderCellDef>Size</th>
            <td mat-cell *matCellDef="let item">
              <span *ngIf="!item.isDirectory && item.size">{{ item.size | fileSize }}</span>
              <span *ngIf="item.isDirectory || !item.size">-</span>
            </td>
          </ng-container>

          <!-- Action Column -->
          <ng-container matColumnDef="actions">
            <th mat-header-cell *matHeaderCellDef></th>
            <td mat-cell *matCellDef="let item">
              <mat-icon class="action-icon">
                {{ item.isDirectory ? 'chevron_right' : 'arrow_forward' }}
              </mat-icon>
            </td>
          </ng-container>

          <tr mat-header-row *matHeaderRowDef="displayedColumns"></tr>
          <tr mat-row *matRowDef="let row; columns: displayedColumns;" 
              class="content-row"
              (click)="onItemClick(row)"
              [class.folder-row]="row.isDirectory"
              [class.file-row]="!row.isDirectory"></tr>
        </table>
      </div>

      <!-- Empty State -->
      <div *ngIf="!isLoading() && contents().length === 0" class="empty-state">
        <mat-icon>folder_open</mat-icon>
        <p>This folder is empty</p>
      </div>

      <!-- Loading State -->
      <div *ngIf="isLoading()" class="loading-state">
        <mat-icon>hourglass_empty</mat-icon>
        <p>Loading folder contents...</p>
      </div>
    </div>
  `,
  styles: [`
    .folder-viewer-container {
      padding: 16px;
      height: 100%;
      overflow: auto;
    }

    .folder-header {
      display: flex;
      align-items: center;
      gap: 12px;
      margin-bottom: 16px;
      padding-bottom: 12px;
      border-bottom: 2px solid #e0e0e0;
    }

    .folder-header mat-icon {
      font-size: 32px;
      width: 32px;
      height: 32px;
      color: #fbbf24;
    }

    .folder-header h2 {
      margin: 0;
      font-size: 20px;
      font-weight: 500;
    }

    .table-container {
      overflow-x: auto;
      background: white;
      border-radius: 8px;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }

    .contents-table {
      width: 100%;
    }

    th.mat-header-cell {
      font-size: 14px;
      font-weight: 600;
      color: rgba(0,0,0,0.87);
      background: #f5f5f5;
    }

    td.mat-cell {
      padding: 12px 16px;
    }

    .name-cell {
      font-weight: 500;
      max-width: 400px;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }

    .content-row {
      transition: background 0.2s, transform 0.1s;
      cursor: pointer;
    }

    .content-row:hover {
      background: #f5f5f5;
      transform: scale(1.01);
    }

    .content-row:active {
      transform: scale(0.99);
    }

    .folder-row {
      border-left: 3px solid #fbbf24;
    }

    .file-row {
      border-left: 3px solid #4caf50;
    }

    .action-icon {
      color: rgba(0,0,0,0.4);
      transition: color 0.2s, transform 0.2s;
      font-size: 20px;
      width: 20px;
      height: 20px;
    }

    .content-row:hover .action-icon {
      color: #1976d2;
      transform: translateX(4px);
    }

    mat-icon.icon-folder {
      color: #fbbf24;
    }

    mat-icon.icon-pdf {
      color: #ef4444;
    }

    mat-icon.icon-video {
      color: #8b5cf6;
    }

    mat-icon.icon-image {
      color: #f59e0b;
    }

    mat-icon.icon-text {
      color: #6b7280;
    }

    mat-icon.icon-audio {
      color: #06b6d4;
    }

    mat-icon.icon-unknown {
      color: #9ca3af;
    }

    .empty-state, .loading-state {
      text-align: center;
      padding: 64px 32px;
      color: rgba(0,0,0,0.6);
    }

    .empty-state mat-icon, .loading-state mat-icon {
      font-size: 64px;
      width: 64px;
      height: 64px;
      opacity: 0.3;
      margin-bottom: 16px;
    }

    .empty-state p, .loading-state p {
      margin: 0;
      font-size: 16px;
    }
  `]
})
export class FolderViewerComponent implements OnInit, OnChanges {
  @Input() folderId!: number | null;
  @Input() folderName: string = 'Folder';
  @Input() courseId!: number;
  @Output() fileSelected = new EventEmitter<FileNode>();
  @Output() folderSelected = new EventEmitter<{ folderId: number | null; folderName: string; courseId: number }>();

  contents = signal<FileNode[]>([]);
  isLoading = signal(false);
  displayedColumns = ['icon', 'name', 'type', 'size', 'actions'];
  private allFiles: FileNode[] = [];
  private currentFolderId: number | null = null;
  private currentCourseId: number | null = null;

  constructor(private fileService: FileService) {}

  ngOnInit(): void {
    this.loadFiles();
  }

  ngOnChanges(): void {
    // Reload when folderId OR courseId changes
    if (this.folderId !== this.currentFolderId || this.courseId !== this.currentCourseId) {
      this.currentFolderId = this.folderId;
      this.currentCourseId = this.courseId;
      this.loadFiles();
    }
  }

  private loadFiles(): void {
    if (!this.courseId) return;
    
    this.isLoading.set(true);
    
    // Load all files for the course
    this.fileService.getFilesByCourse(this.courseId).subscribe({
      next: (files) => {
        this.allFiles = files;
        this.loadFolderContents();
        this.isLoading.set(false);
      },
      error: (error) => {
        console.error('Error loading files:', error);
        this.isLoading.set(false);
      }
    });
  }

  private loadFolderContents(): void {
    // If folderId is null, show root level items (parentId = null)
    // Otherwise, show items where parentId === folderId
    const folderContents = this.folderId === null 
      ? this.allFiles.filter(f => f.parentId === null)
      : this.allFiles.filter(f => f.parentId === this.folderId);
    
    console.log('=== Folder Viewer Debug ===');
    console.log('Looking for items with parentId:', this.folderId === null ? 'null (root level)' : this.folderId);
    console.log('Folder name:', this.folderName);
    console.log('CourseId:', this.courseId);
    console.log('Total files loaded:', this.allFiles.length);
    
    // Show all items and their parentIds
    console.log('All items in course:');
    this.allFiles.forEach(f => {
      console.log(`  - ${f.isDirectory ? '[DIR]' : '[FILE]'} ${f.name} (id: ${f.id}, parentId: ${f.parentId})`);
    });
    
    console.log('Folder contents found:', folderContents.length);
    console.log('Contents breakdown:', {
      folders: folderContents.filter(f => f.isDirectory).length,
      files: folderContents.filter(f => !f.isDirectory).length
    });
    
    if (folderContents.length > 0) {
      console.log('Items in folder:');
      folderContents.forEach(f => {
        console.log(`  - ${f.isDirectory ? '[DIR]' : '[FILE]'} ${f.name}`);
      });
    }
    
    // Sort: folders first, then files
    folderContents.sort((a, b) => {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      return a.name.localeCompare(b.name);
    });
    
    this.contents.set(folderContents);
  }

  // Method to set all files from parent (called when tree loads files)
  setAllFiles(files: FileNode[]): void {
    this.allFiles = files;
    this.loadFolderContents();
  }

  onItemClick(item: FileNode): void {
    if (item.isDirectory) {
      // Navigate to subfolder
      this.folderSelected.emit({ 
        folderId: item.id, 
        folderName: item.name,
        courseId: this.courseId 
      });
    } else {
      // Open file
      this.fileSelected.emit(item);
    }
  }

  getIcon(item: FileNode): string {
    if (item.isDirectory) {
      return 'folder';
    }
    const fileType = this.fileService.getFileType(item.name);
    return this.fileService.getFileIcon(fileType);
  }

  getIconClass(item: FileNode): string {
    if (item.isDirectory) {
      return 'icon-folder';
    }
    const fileType = this.fileService.getFileType(item.name);
    return `icon-${fileType}`;
  }

  getFileTypeLabel(filename: string): string {
    const fileType = this.fileService.getFileType(filename);
    return fileType.toUpperCase();
  }
}
