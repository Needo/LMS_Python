import { Component, signal, OnInit, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { MatToolbarModule } from '@angular/material/toolbar';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { AuthService } from '../../../core/services/auth.service';
import { CategoryService } from '../../../core/services/category.service';
import { CourseService } from '../../../core/services/course.service';
import { FileService } from '../../../core/services/file.service';
import { ProgressService } from '../../../core/services/progress.service';
import { FileNode } from '../../../core/models/file.model';
import { TreeViewComponent } from './components/tree-view.component';
import { FileViewerComponent } from './components/file-viewer.component';

@Component({
  selector: 'app-client',
  standalone: true,
  imports: [
    CommonModule,
    MatToolbarModule,
    MatButtonModule,
    MatIconModule,
    MatProgressSpinnerModule,
    TreeViewComponent,
    FileViewerComponent
  ],
  templateUrl: './client.component.html',
  styleUrls: ['./client.component.scss']
})
export class ClientComponent implements OnInit {
  currentUser = this.authService.currentUser;
  selectedFile = signal<FileNode | null>(null);
  isLoading = signal(false);
  
  leftPanelWidth = signal(300);
  isResizing = signal(false);

  constructor(
    private authService: AuthService,
    private categoryService: CategoryService,
    private courseService: CourseService,
    private fileService: FileService,
    private progressService: ProgressService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadLastViewed();
  }

  loadLastViewed(): void {
    const user = this.currentUser();
    if (user) {
      this.progressService.getLastViewed(user.id).subscribe({
        next: (lastViewed) => {
          if (lastViewed && lastViewed.fileId) {
            this.fileService.getFileById(lastViewed.fileId).subscribe({
              next: (file) => {
                this.selectedFile.set(file);
              },
              error: (error) => {
                console.error('Error loading last viewed file:', error);
              }
            });
          }
        },
        error: (error) => {
          console.error('Error loading last viewed:', error);
        }
      });
    }
  }

  onFileSelected(file: FileNode): void {
    this.selectedFile.set(file);
    
    const user = this.currentUser();
    if (user && file.courseId) {
      this.progressService.setLastViewed(user.id, file.courseId, file.id).subscribe({
        error: (error) => {
          console.error('Error saving last viewed:', error);
        }
      });
    }
  }

  onMouseDown(event: MouseEvent): void {
    this.isResizing.set(true);
    event.preventDefault();
  }

  onMouseMove(event: MouseEvent): void {
    if (this.isResizing()) {
      const newWidth = event.clientX;
      if (newWidth >= 200 && newWidth <= 600) {
        this.leftPanelWidth.set(newWidth);
      }
    }
  }

  onMouseUp(): void {
    this.isResizing.set(false);
  }

  navigateToAdmin(): void {
    this.router.navigate(['/admin']);
  }

  logout(): void {
    this.authService.logout();
    this.router.navigate(['/auth/login']);
  }
}
