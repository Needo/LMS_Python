import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, map } from 'rxjs';
import { environment } from '../../../environments/environment';
import { SearchStateService, SearchResultItem } from './search-state.service';

export interface SearchResponse {
  courses: any[];
  files: any[];
  total: number;
  query: string;
}

@Injectable({
  providedIn: 'root'
})
export class SearchService {
  private apiUrl = `${environment.apiUrl}/search`;

  constructor(
    private http: HttpClient,
    private searchState: SearchStateService
  ) {}

  /**
   * Search all (courses + files) and update state
   */
  searchAll(query: string, limit: number = 50): Observable<SearchResultItem[]> {
    return this.http.get<SearchResponse>(`${this.apiUrl}?q=${encodeURIComponent(query)}&limit=${limit}`).pipe(
      map(response => {
        // Transform to unified format
        const results: SearchResultItem[] = [
          ...response.courses.map(c => ({
            id: c.id,
            name: c.name,
            type: 'course' as const,
            icon: c.icon || 'school',
            categoryId: c.category_id
          })),
          ...response.files.map(f => ({
            id: f.id,
            name: f.name,
            type: 'file' as const,
            icon: f.icon || 'insert_drive_file',
            path: f.path,
            courseId: f.course_id,
            fileType: f.file_type,
            fileSize: f.file_size
          }))
        ];

        // Update search state
        this.searchState.activateSearch(query, results);

        return results;
      })
    );
  }

  /**
   * Search courses only
   */
  searchCourses(query: string, limit: number = 20): Observable<any> {
    return this.http.get(`${this.apiUrl}/courses?q=${encodeURIComponent(query)}&limit=${limit}`);
  }

  /**
   * Search files only
   */
  searchFiles(query: string, fileType?: string, limit: number = 30): Observable<any> {
    let url = `${this.apiUrl}/files?q=${encodeURIComponent(query)}&limit=${limit}`;
    if (fileType) {
      url += `&file_type=${fileType}`;
    }
    return this.http.get(url);
  }

  /**
   * Get popular searches
   */
  getPopularSearches(limit: number = 10): Observable<any> {
    return this.http.get(`${this.apiUrl}/popular?limit=${limit}`);
  }

  /**
   * Get recent searches
   */
  getRecentSearches(limit: number = 5): Observable<any> {
    return this.http.get(`${this.apiUrl}/recent?limit=${limit}`);
  }

  /**
   * Close search and clear state
   */
  closeSearch(): void {
    this.searchState.closeSearch();
  }

  /**
   * Navigate to item
   */
  navigateToItem(item: SearchResultItem): void {
    this.searchState.navigateToItem(item);
  }

  /**
   * Return to search results
   */
  returnToSearch(): void {
    this.searchState.returnToSearch();
  }
}
