import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MatDialogModule, MatDialogRef } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatSelectModule } from '@angular/material/select';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MatSnackBar } from '@angular/material/snack-bar';
import { CategoryService } from '../../../core/services/category.service';
import { CourseUploadService } from '../../../core/services/course-upload.service';
import { Category } from '../../../core/models/category.model';

@Component({
  selector: 'app-upload-course-dialog',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    MatDialogModule,
    MatFormFieldModule,
    MatSelectModule,
    MatButtonModule,
    MatIconModule,
    MatProgressBarModule
  ],
  template: `
    <h2 mat-dialog-title>Upload Course Folder</h2>
    <mat-dialog-content>
      <div class="upload-container">
        
        <!-- Category Selection -->
        <mat-form-field appearance="outline" class="full-width">
          <mat-label>Select Category</mat-label>
          <mat-select [(ngModel)]="selectedCategoryId" required>
            @for (category of categories(); track category.id) {
              <mat-option [value]="category.id">{{ category.name }}</mat-option>
            }
          </mat-select>
          <mat-icon matPrefix>category</mat-icon>
        </mat-form-field>

        <!-- Hidden File Input -->
        <input 
          #folderInput
          type="file" 
          webkitdirectory
          directory
          multiple
          style="display: none"
          (change)="onFolderSelected($event)"
          [disabled]="isUploading()">

        <!-- Folder Selection Button -->
        <div class="folder-select-section">
          <button 
            mat-raised-button 
            type="button"
            (click)="folderInput.click()"
            [disabled]="isUploading()">
            <mat-icon>folder_open</mat-icon>
            Select Course Folder
          </button>
          
          @if (selectedFolderName()) {
            <div class="selected-folder">
              <mat-icon>folder</mat-icon>
              <div class="folder-info">
                <span class="folder-name">{{ selectedFolderName() }}</span>
                <span class="file-count">{{ selectedFiles()?.length || 0 }} files</span>
              </div>
              <button 
                mat-icon-button 
                (click)="clearFolder()"
                [disabled]="isUploading()">
                <mat-icon>close</mat-icon>
              </button>
            </div>
          }
        </div>

        <!-- Upload Progress -->
        @if (isUploading()) {
          <div class="progress-section">
            <mat-progress-bar mode="indeterminate"></mat-progress-bar>
            <p class="progress-text">{{ uploadStatus() }}</p>
          </div>
        }

        <!-- Instructions -->
        <div class="instructions">
          <mat-icon>info</mat-icon>
          <div>
            <p><strong>Instructions:</strong></p>
            <ul>
              <li>Select a category where the course will be uploaded</li>
              <li>Choose a folder containing your course materials</li>
              <li>The folder and all its subfolders will be uploaded</li>
              <li>Files will be organized in the selected category</li>
            </ul>
          </div>
        </div>
      </div>
    </mat-dialog-content>
    <mat-dialog-actions align="end">
      <button mat-button (click)="cancel()" [disabled]="isUploading()">
        Cancel
      </button>
      <button 
        mat-raised-button 
        color="primary" 
        (click)="upload()"
        [disabled]="!canUpload()">
        <mat-icon>cloud_upload</mat-icon>
        Upload
      </button>
    </mat-dialog-actions>
  `,
  styles: [`
    mat-dialog-content {
      min-width: 500px;
      padding: 24px;
    }

    .upload-container {
      display: flex;
      flex-direction: column;
      gap: 24px;
    }

    .full-width {
      width: 100%;
    }

    .folder-select-section {
      display: flex;
      flex-direction: column;
      gap: 12px;
    }

    .selected-folder {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 12px;
      background: #f5f5f5;
      border-radius: 4px;
      border: 1px solid #e0e0e0;
    }

    .selected-folder mat-icon {
      color: #fbbf24;
      flex-shrink: 0;
    }

    .folder-info {
      flex: 1;
      display: flex;
      flex-direction: column;
      gap: 4px;
      min-width: 0;
    }

    .folder-name {
      font-size: 14px;
      font-weight: 500;
      word-break: break-all;
    }

    .file-count {
      font-size: 12px;
      color: #666;
    }

    .progress-section {
      display: flex;
      flex-direction: column;
      gap: 8px;
    }

    .progress-text {
      text-align: center;
      color: #666;
      font-size: 14px;
      margin: 0;
    }

    .instructions {
      display: flex;
      gap: 12px;
      padding: 16px;
      background: #e3f2fd;
      border-radius: 4px;
      border-left: 4px solid #2196f3;
    }

    .instructions mat-icon {
      color: #2196f3;
      flex-shrink: 0;
    }

    .instructions p {
      margin: 0 0 8px 0;
      font-weight: 500;
    }

    .instructions ul {
      margin: 0;
      padding-left: 20px;
    }

    .instructions li {
      margin-bottom: 4px;
      font-size: 14px;
    }

    mat-dialog-actions {
      padding: 16px 24px;
    }
  `]
})
export class UploadCourseDialogComponent implements OnInit {
  categories = signal<Category[]>([]);
  selectedCategoryId: number | null = null;
  selectedFolderName = signal<string | null>(null);
  selectedFiles = signal<File[] | null>(null);
  isUploading = signal(false);
  uploadStatus = signal('');

  constructor(
    public dialogRef: MatDialogRef<UploadCourseDialogComponent>,
    private categoryService: CategoryService,
    private courseUploadService: CourseUploadService,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit(): void {
    this.loadCategories();
  }

  loadCategories(): void {
    this.categoryService.getCategories().subscribe({
      next: (categories) => {
        this.categories.set(categories);
      },
      error: (error) => {
        console.error('Error loading categories:', error);
        this.snackBar.open('Failed to load categories', 'Close', { duration: 3000 });
      }
    });
  }

  onFolderSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    if (input.files && input.files.length > 0) {
      const fileList = Array.from(input.files);
      this.selectedFiles.set(fileList);
      
      // Get folder name from first file's path
      const firstFile = fileList[0];
      const fullPath = (firstFile as any).webkitRelativePath || firstFile.name;
      const folderName = fullPath.split('/')[0];
      
      this.selectedFolderName.set(folderName);
    }
  }

  clearFolder(): void {
    this.selectedFolderName.set(null);
    this.selectedFiles.set(null);
  }

  canUpload(): boolean {
    return !!(this.selectedCategoryId && this.selectedFiles() && !this.isUploading());
  }

  async upload(): Promise<void> {
    if (!this.canUpload()) return;

    const files = this.selectedFiles();
    if (!files) return;

    this.isUploading.set(true);
    this.uploadStatus.set('Preparing upload...');

    try {
      // Prepare file upload items with relative paths
      const fileItems = files.map(file => {
        const relativePath = (file as any).webkitRelativePath || file.name;
        // Remove the root folder name from the path
        const pathParts = relativePath.split('/');
        const relativePathWithoutRoot = pathParts.slice(1).join('/');
        
        return {
          file,
          relativePath: relativePathWithoutRoot
        };
      });

      this.uploadStatus.set(`Uploading ${files.length} files...`);

      // Upload files to server
      const result = await this.courseUploadService.uploadCourseFolder(
        this.selectedCategoryId!,
        this.selectedFolderName()!,
        fileItems
      ).toPromise();

      this.snackBar.open(`Successfully uploaded ${files.length} files`, 'Close', { duration: 3000 });
      this.dialogRef.close(result);
      
    } catch (error) {
      console.error('Upload failed:', error);
      this.snackBar.open('Upload failed. Please try again.', 'Close', { duration: 5000 });
    } finally {
      this.isUploading.set(false);
      this.uploadStatus.set('');
    }
  }

  cancel(): void {
    this.dialogRef.close();
  }
}
