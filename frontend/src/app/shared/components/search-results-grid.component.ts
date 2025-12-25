import { Component, signal, Input, Output, EventEmitter } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatCardModule } from '@angular/material/card';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonModule } from '@angular/material/button';
import { MatChipsModule } from '@angular/material/chips';
import { SearchResultItem } from '../../../core/services/search-state.service';
import { FileSizePipe } from '../../pipes/file-size.pipe';

@Component({
  selector: 'app-search-results-grid',
  standalone: true,
  imports: [
    CommonModule,
    MatCardModule,
    MatIconModule,
    MatButtonModule,
    MatChipsModule,
    FileSizePipe
  ],
  template: `
    <div class="search-results-container">
      <!-- Header -->
      <div class="results-header">
        <div class="header-content">
          <mat-icon>search</mat-icon>
          <h2>Search Results for "{{ query() }}"</h2>
          <button 
            mat-icon-button 
            (click)="onClose()"
            aria-label="Close search">
            <mat-icon>close</mat-icon>
          </button>
        </div>
        <div class="results-info">
          <span>{{ totalResults() }} results found</span>
          <mat-chip-set>
            <mat-chip 
              [highlighted]="filter() === 'all'" 
              (click)="setFilter('all')">
              All ({{ totalResults() }})
            </mat-chip>
            <mat-chip 
              [highlighted]="filter() === 'courses'" 
              (click)="setFilter('courses')">
              Courses ({{ courseCount() }})
            </mat-chip>
            <mat-chip 
              [highlighted]="filter() === 'files'" 
              (click)="setFilter('files')">
              Files ({{ fileCount() }})
            </mat-chip>
          </mat-chip-set>
        </div>
      </div>

      <!-- Results Grid -->
      <div class="results-grid">
        <!-- Course Cards -->
        <mat-card 
          *ngFor="let item of filteredResults()"
          class="result-card"
          [class.course-card]="item.type === 'course'"
          [class.file-card]="item.type === 'file'">
          
          <mat-card-header>
            <mat-icon mat-card-avatar [class.course-icon]="item.type === 'course'">
              {{ item.icon }}
            </mat-icon>
            <mat-card-title>{{ item.name }}</mat-card-title>
            <mat-card-subtitle *ngIf="item.type === 'file'">
              {{ item.fileType?.toUpperCase() || 'FILE' }}
              <span *ngIf="item.fileSize"> • {{ item.fileSize | fileSize }}</span>
            </mat-card-subtitle>
          </mat-card-header>

          <mat-card-content *ngIf="item.path">
            <div class="file-path">
              <mat-icon>folder</mat-icon>
              <span>{{ item.path }}</span>
            </div>
          </mat-card-content>

          <mat-card-actions>
            <button 
              mat-raised-button 
              color="primary"
              (click)="onSelectItem(item)"
              [attr.aria-label]="'Open ' + item.name">
              <mat-icon>{{ item.type === 'course' ? 'school' : 'launch' }}</mat-icon>
              {{ item.type === 'course' ? 'View Course' : 'Open File' }}
            </button>
          </mat-card-actions>
        </mat-card>
      </div>

      <!-- No Results -->
      <div *ngIf="filteredResults().length === 0" class="no-results">
        <mat-icon>search_off</mat-icon>
        <h3>No {{ filter() === 'all' ? '' : filter() }} found</h3>
        <p>Try different keywords or filters</p>
      </div>
    </div>
  `,
  styles: [`
    .search-results-container {
      padding: 24px;
      max-width: 1400px;
      margin: 0 auto;
    }

    .results-header {
      margin-bottom: 32px;
    }

    .header-content {
      display: flex;
      align-items: center;
      gap: 16px;
      margin-bottom: 16px;
    }

    .header-content mat-icon {
      font-size: 32px;
      width: 32px;
      height: 32px;
      color: #1976d2;
    }

    .header-content h2 {
      flex: 1;
      margin: 0;
      font-size: 24px;
      font-weight: 500;
    }

    .results-info {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 16px;
      background: #f5f5f5;
      border-radius: 8px;
    }

    .results-info span {
      font-size: 14px;
      color: rgba(0,0,0,0.6);
    }

    /* Grid Layout */
    .results-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
      gap: 24px;
      margin-top: 24px;
    }

    @media (max-width: 768px) {
      .results-grid {
        grid-template-columns: 1fr;
      }
    }

    /* Card Styles */
    .result-card {
      transition: transform 0.2s, box-shadow 0.2s;
      cursor: pointer;
    }

    .result-card:hover {
      transform: translateY(-4px);
      box-shadow: 0 8px 16px rgba(0,0,0,0.2);
    }

    .course-card {
      border-left: 4px solid #1976d2;
    }

    .file-card {
      border-left: 4px solid #4caf50;
    }

    mat-card-header {
      margin-bottom: 16px;
    }

    mat-icon[mat-card-avatar] {
      width: 48px;
      height: 48px;
      font-size: 48px;
      display: flex;
      align-items: center;
      justify-content: center;
    }

    mat-icon.course-icon {
      color: #1976d2;
    }

    mat-card-title {
      font-size: 18px;
      font-weight: 500;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }

    mat-card-subtitle {
      font-size: 12px;
      text-transform: uppercase;
      color: rgba(0,0,0,0.6);
    }

    .file-path {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 8px;
      background: #f5f5f5;
      border-radius: 4px;
      font-size: 12px;
      color: rgba(0,0,0,0.6);
      overflow: hidden;
    }

    .file-path mat-icon {
      font-size: 16px;
      width: 16px;
      height: 16px;
    }

    .file-path span {
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }

    mat-card-actions {
      padding: 16px;
      margin: 0;
    }

    mat-card-actions button {
      width: 100%;
    }

    /* No Results */
    .no-results {
      text-align: center;
      padding: 64px 32px;
      color: rgba(0,0,0,0.6);
    }

    .no-results mat-icon {
      font-size: 64px;
      width: 64px;
      height: 64px;
      opacity: 0.3;
      margin-bottom: 16px;
    }

    .no-results h3 {
      margin: 16px 0 8px 0;
      font-size: 20px;
    }

    .no-results p {
      margin: 0;
      font-size: 14px;
    }
  `]
})
export class SearchResultsGridComponent {
  @Input() query = signal('');
  @Input() results = signal<SearchResultItem[]>([]);
  @Output() selectItem = new EventEmitter<SearchResultItem>();
  @Output() closeSearch = new EventEmitter<void>();

  filter = signal<'all' | 'courses' | 'files'>('all');

  courseCount = computed(() => 
    this.results().filter(r => r.type === 'course').length
  );

  fileCount = computed(() => 
    this.results().filter(r => r.type === 'file').length
  );

  totalResults = computed(() => this.results().length);

  filteredResults = computed(() => {
    const filterValue = this.filter();
    if (filterValue === 'all') {
      return this.results();
    }
    return this.results().filter(r => {
      if (filterValue === 'courses') return r.type === 'course';
      if (filterValue === 'files') return r.type === 'file';
      return true;
    });
  });

  setFilter(filter: 'all' | 'courses' | 'files'): void {
    this.filter.set(filter);
  }

  onSelectItem(item: SearchResultItem): void {
    this.selectItem.emit(item);
  }

  onClose(): void {
    this.closeSearch.emit();
  }
}
