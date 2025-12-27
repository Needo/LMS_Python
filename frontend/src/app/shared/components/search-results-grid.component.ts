import { Component, signal, input, output, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatTableModule } from '@angular/material/table';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonModule } from '@angular/material/button';
import { MatChipsModule } from '@angular/material/chips';
import { SearchResultItem } from '../../core/services/search-state.service';
import { FileSizePipe } from '../pipes/file-size.pipe';

@Component({
  selector: 'app-search-results-grid',
  standalone: true,
  imports: [
    CommonModule,
    MatTableModule,
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

      <!-- Results Table -->
      <div class="table-container">
        <table mat-table [dataSource]="filteredResults()" class="results-table">
          
          <!-- Icon Column -->
          <ng-container matColumnDef="icon">
            <th mat-header-cell *matHeaderCellDef>Type</th>
            <td mat-cell *matCellDef="let item">
              <mat-icon [class.course-icon]="item.type === 'course'" [class.file-icon]="item.type === 'file'">
                {{ item.icon }}
              </mat-icon>
            </td>
          </ng-container>

          <!-- Name Column -->
          <ng-container matColumnDef="name">
            <th mat-header-cell *matHeaderCellDef>Name</th>
            <td mat-cell *matCellDef="let item" class="name-cell">
              <div class="name-content">
                <span class="item-name">{{ item.name }}</span>
                <span class="item-type" *ngIf="item.type === 'file'">
                  {{ item.fileType?.toUpperCase() || 'FILE' }}
                </span>
              </div>
            </td>
          </ng-container>

          <!-- Path Column -->
          <ng-container matColumnDef="path">
            <th mat-header-cell *matHeaderCellDef>Location</th>
            <td mat-cell *matCellDef="let item" class="path-cell">
              <span *ngIf="item.path">{{ item.path }}</span>
              <span *ngIf="!item.path && item.type === 'course'">Course</span>
            </td>
          </ng-container>

          <!-- Size Column -->
          <ng-container matColumnDef="size">
            <th mat-header-cell *matHeaderCellDef>Size</th>
            <td mat-cell *matCellDef="let item">
              <span *ngIf="item.fileSize">{{ item.fileSize | fileSize }}</span>
              <span *ngIf="!item.fileSize">-</span>
            </td>
          </ng-container>

          <!-- Action Column -->
          <ng-container matColumnDef="actions">
            <th mat-header-cell *matHeaderCellDef></th>
            <td mat-cell *matCellDef="let item">
              <mat-icon class="action-icon">arrow_forward</mat-icon>
            </td>
          </ng-container>

          <tr mat-header-row *matHeaderRowDef="displayedColumns"></tr>
          <tr mat-row *matRowDef="let row; columns: displayedColumns;" 
              class="result-row"
              (click)="onSelectItem(row)"
              [class.course-row]="row.type === 'course'"
              [class.file-row]="row.type === 'file'"></tr>
        </table>
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
      padding: 16px;
      max-width: 1400px;
      margin: 0 auto;
    }

    .results-header {
      margin-bottom: 12px;
    }

    .header-content {
      display: flex;
      align-items: center;
      gap: 8px;
      margin-bottom: 8px;
    }

    .header-content mat-icon {
      font-size: 20px;
      width: 20px;
      height: 20px;
      color: #1976d2;
    }

    .header-content h2 {
      flex: 1;
      margin: 0;
      font-size: 16px;
      font-weight: 500;
    }

    .header-content button {
      width: 32px;
      height: 32px;
    }

    .results-info {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 6px 10px;
      background: #f5f5f5;
      border-radius: 4px;
    }

    .results-info span {
      font-size: 12px;
      color: rgba(0,0,0,0.6);
    }

    ::ng-deep .results-info mat-chip-set {
      margin: 0;
    }

    ::ng-deep .results-info mat-chip {
      min-height: 24px !important;
      font-size: 12px !important;
      padding: 4px 8px !important;
    }

    /* Table Container */
    .table-container {
      overflow-x: auto;
      background: white;
      border-radius: 8px;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }

    .results-table {
      width: 100%;
    }

    th.mat-header-cell {
      font-size: 14px;
      font-weight: 600;
      color: rgba(0,0,0,0.87);
      background: #f5f5f5;
    }

    td.mat-cell {
      padding: 16px;
    }

    /* Icon Column */
    mat-icon.course-icon {
      color: #1976d2;
    }

    mat-icon.file-icon {
      color: #4caf50;
    }

    /* Name Column */
    .name-cell {
      max-width: 400px;
    }

    .name-content {
      display: flex;
      flex-direction: column;
      gap: 4px;
    }

    .item-name {
      font-size: 16px;
      font-weight: 500;
      color: rgba(0,0,0,0.87);
    }

    .item-type {
      font-size: 11px;
      color: rgba(0,0,0,0.6);
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }

    /* Path Column */
    .path-cell {
      font-size: 13px;
      color: rgba(0,0,0,0.6);
      max-width: 300px;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }

    /* Row Styles */
    .result-row {
      transition: background 0.2s, transform 0.1s;
      cursor: pointer;
    }

    .result-row:hover {
      background: #f5f5f5;
      transform: scale(1.01);
    }

    .result-row:active {
      transform: scale(0.99);
    }

    .course-row {
      border-left: 3px solid #1976d2;
    }

    .file-row {
      border-left: 3px solid #4caf50;
    }

    .action-icon {
      color: rgba(0,0,0,0.4);
      transition: color 0.2s, transform 0.2s;
    }

    .result-row:hover .action-icon {
      color: #1976d2;
      transform: translateX(4px);
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

    /* Responsive */
    @media (max-width: 768px) {
      .table-container {
        overflow-x: scroll;
      }
    }
  `]
})
export class SearchResultsGridComponent {
  query = input.required<string>();
  results = input.required<SearchResultItem[]>();
  selectItem = output<SearchResultItem>();
  closeSearch = output<void>();

  filter = signal<'all' | 'courses' | 'files'>('all');
  
  displayedColumns = ['icon', 'name', 'path', 'size', 'actions'];

  courseCount = computed(() => {
    const resultsArray = this.results();
    return Array.isArray(resultsArray) ? resultsArray.filter(r => r.type === 'course').length : 0;
  });

  fileCount = computed(() => {
    const resultsArray = this.results();
    return Array.isArray(resultsArray) ? resultsArray.filter(r => r.type === 'file').length : 0;
  });

  totalResults = computed(() => {
    const resultsArray = this.results();
    return Array.isArray(resultsArray) ? resultsArray.length : 0;
  });

  filteredResults = computed(() => {
    const filterValue = this.filter();
    const resultsArray = this.results();
    
    if (!Array.isArray(resultsArray)) {
      return [];
    }
    
    if (filterValue === 'all') {
      return resultsArray;
    }
    return resultsArray.filter(r => {
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
