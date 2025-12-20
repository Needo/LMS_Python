import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, map } from 'rxjs';
import { environment } from '../../../environments/environment';
import { ScanRequest, ScanResult } from '../models/scan.model';

@Injectable({
  providedIn: 'root'
})
export class ScannerService {
  private apiUrl = `${environment.apiUrl}/scanner`;

  constructor(private http: HttpClient) {}

  scanRootFolder(request: ScanRequest): Observable<ScanResult> {
    return this.http.post<any>(`${this.apiUrl}/scan`, {
      root_path: request.rootPath
    }).pipe(
      map(response => ({
        success: response.success,
        message: response.message,
        categoriesFound: response.categories_found,
        coursesFound: response.courses_found,
        filesAdded: response.files_added,
        filesRemoved: response.files_removed,
        filesUpdated: response.files_updated
      }))
    );
  }

  rescanCourse(courseId: number): Observable<ScanResult> {
    return this.http.post<any>(`${this.apiUrl}/rescan/${courseId}`, {}).pipe(
      map(response => ({
        success: response.success,
        message: response.message,
        categoriesFound: response.categories_found,
        coursesFound: response.courses_found,
        filesAdded: response.files_added,
        filesRemoved: response.files_removed,
        filesUpdated: response.files_updated
      }))
    );
  }

  getRootPath(): Observable<{ rootPath: string }> {
    return this.http.get<any>(`${this.apiUrl}/root-path`).pipe(
      map(response => ({
        rootPath: response.root_path || ''
      }))
    );
  }

  setRootPath(rootPath: string): Observable<{ success: boolean }> {
    return this.http.post<{ success: boolean }>(`${this.apiUrl}/root-path`, { 
      root_path: rootPath
    });
  }
}
