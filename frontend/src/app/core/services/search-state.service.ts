import { Injectable, signal, computed } from '@angular/core';
import { BehaviorSubject } from 'rxjs';

export interface SearchState {
  query: string;
  results: SearchResultItem[];
  isActive: boolean;
  timestamp: number;
}

export interface SearchResultItem {
  id: number;
  name: string;
  type: 'course' | 'file';
  icon: string;
  path?: string;
  courseId?: number;
  categoryId?: number;
  fileType?: string;
  fileSize?: number;
}

@Injectable({
  providedIn: 'root'
})
export class SearchStateService {
  // Active search state
  private searchState = signal<SearchState>({
    query: '',
    results: [],
    isActive: false,
    timestamp: 0
  });

  // Public signals
  query = computed(() => this.searchState().query);
  results = computed(() => this.searchState().results);
  isActive = computed(() => this.searchState().isActive);
  hasResults = computed(() => this.searchState().results.length > 0);
  resultsCount = computed(() => this.searchState().results.length);

  // View mode: 'tree' or 'search'
  private viewMode = signal<'tree' | 'search'>('tree');
  currentView = computed(() => this.viewMode());

  // Selected item for navigation back
  private selectedItem = signal<SearchResultItem | null>(null);
  currentSelection = computed(() => this.selectedItem());

  constructor() {}

  /**
   * Activate search mode with results
   */
  activateSearch(query: string, results: SearchResultItem[]): void {
    this.searchState.set({
      query,
      results,
      isActive: true,
      timestamp: Date.now()
    });
    this.viewMode.set('search');
  }

  /**
   * Navigate to item from search (switches to tree view)
   */
  navigateToItem(item: SearchResultItem): void {
    this.selectedItem.set(item);
    this.viewMode.set('tree');
    // Keep search state active so we can return
  }

  /**
   * Return to search results
   */
  returnToSearch(): void {
    if (this.searchState().isActive) {
      this.viewMode.set('search');
    }
  }

  /**
   * Close search and clear results
   */
  closeSearch(): void {
    this.searchState.set({
      query: '',
      results: [],
      isActive: false,
      timestamp: 0
    });
    this.viewMode.set('tree');
    this.selectedItem.set(null);
  }

  /**
   * Check if search is active
   */
  isSearchActive(): boolean {
    return this.searchState().isActive;
  }

  /**
   * Get current view mode
   */
  getViewMode(): 'tree' | 'search' {
    return this.viewMode();
  }
}
