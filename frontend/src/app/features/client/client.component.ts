import { Component, signal, OnInit, computed, HostListener } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { MatToolbarModule } from '@angular/material/toolbar';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatMenuModule } from '@angular/material/menu';
import { MatDividerModule } from '@angular/material/divider';
import { AuthService } from '../../core/services/auth.service';
import { CategoryService } from '../../core/services/category.service';
import { CourseService } from '../../core/services/course.service';
import { FileService } from '../../core/services/file.service';
import { ProgressService } from '../../core/services/progress.service';
import { TreeStateService } from '../../core/services/tree-state.service';
import { SearchService } from '../../core/services/search.service';
import { SearchStateService } from '../../core/services/search-state.service';
import { FileNode } from '../../core/models/file.model';
import { TreeViewComponent } from './components/tree-view.component';
import { FileViewerComponent } from './components/file-viewer.component';
import { SearchResultsGridComponent } from '../../shared/components/search-results-grid.component';
import { Subject } from 'rxjs';
import { debounceTime } from 'rxjs/operators';

@Component({
  selector: 'app-client',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    MatToolbarModule,
    MatButtonModule,
    MatIconModule,
    MatProgressSpinnerModule,
    MatFormFieldModule,
    MatInputModule,
    MatMenuModule,
    MatDividerModule,
    TreeViewComponent,
    FileViewerComponent,
    SearchResultsGridComponent
  ],
  templateUrl: './client.component.html',
  styleUrls: ['./client.component.scss']
})
export class ClientComponent implements OnInit {
  currentUser: any;
  selectedFile = signal<FileNode | null>(null);
  isLoading = signal(false);
  
  // Search
  searchQuery = '';
  isSearching = signal(false);
  private searchSubject = new Subject<string>();
  
  // View mode from search state
  currentView = this.searchState.currentView;
  searchResults = this.searchState.results;
  searchQueryText = this.searchState.query;
  
  leftPanelWidth = signal(300);
  isResizing = signal(false);

  constructor(
    private authService: AuthService,
    private categoryService: CategoryService,
    private courseService: CourseService,
    private fileService: FileService,
    private progressService: ProgressService,
    private treeState: TreeStateService,
    private searchService: SearchService,
    private searchState: SearchStateService,
    private router: Router
  ) {
    // Setup search debounce
    this.searchSubject.pipe(
      debounceTime(400)
    ).subscribe(query => {
      if (query.trim().length >= 2) {
        this.performSearch(query);
      } else if (query.trim().length === 0) {
        // Clear search when empty
        this.closeSearch();
      }
    });
  }

  ngOnInit(): void {
    this.currentUser = this.authService.currentUser;
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
    this.treeState.clearExpansionState();
    this.searchService.closeSearch();
    this.authService.logout();
    this.router.navigate(['/auth/login']);
  }

  // Search methods
  onSearchChange(): void {
    this.searchSubject.next(this.searchQuery);
  }

  performSearch(query: string): void {
    this.isSearching.set(true);
    
    this.searchService.searchAll(query).subscribe({
      next: () => {
        this.isSearching.set(false);
      },
      error: (error) => {
        console.error('Search failed:', error);
        this.isSearching.set(false);
      }
    });
  }

  onSearchItemSelect(item: any): void {
    // Navigate to item in tree view
    this.searchService.navigateToItem(item);
    
    // If it's a file, load it
    if (item.type === 'file') {
      this.fileService.getFileById(item.id).subscribe({
        next: (file) => {
          this.selectedFile.set(file);
        },
        error: (error) => {
          console.error('Error loading file:', error);
        }
      });
    }
  }

  returnToSearch(): void {
    this.searchService.returnToSearch();
  }

  closeSearch(): void {
    this.searchQuery = '';
    this.searchService.closeSearch();
  }

  canReturnToSearch(): boolean {
    return this.searchState.isSearchActive() && this.currentView() === 'tree';
  }

  @HostListener('document:mousemove', ['$event'])
  onDocumentMouseMove(event: MouseEvent): void {
    if (this.isResizing()) {
      this.onMouseMove(event);
    }
  }

  @HostListener('document:mouseup')
  onDocumentMouseUp(): void {
    if (this.isResizing()) {
      this.onMouseUp();
    }
  }
}
