import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, map } from 'rxjs';
import { environment } from '../../../environments/environment';
import { ScanRequest, ScanResult, ScanStatus, ScanHistory } from '../models/scan.model';

export interface ScanStatusResponse {
  is_scanning: boolean;
  current_scan_id: number | null;
  status: ScanStatus | null;
  started_at: string | null;
  locked_by_id: number | null;
  last_scan: ScanHistory | null;
}

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
        filesUpdated: response.files_updated,
        errorsCount: response.errors_count || 0,
        scanId: response.scan_id,
        status: response.status as ScanStatus
      }))
    );
  }

  getScanStatus(): Observable<ScanStatusResponse> {
    return this.http.get<ScanStatusResponse>(`${this.apiUrl}/status`);
  }

  getScanHistory(limit: number = 10): Observable<ScanHistory[]> {
    return this.http.get<ScanHistory[]>(`${this.apiUrl}/history?limit=${limit}`);
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
        filesUpdated: response.files_updated,
        errorsCount: response.errors_count || 0,
        scanId: response.scan_id,
        status: response.status as ScanStatus
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

  getScanLogs(scanId: number): Observable<any> {
    return this.http.get<any>(`${this.apiUrl}/logs/${scanId}`);
  }

  cleanupOrphanedEntries(): Observable<any> {
    return this.http.post<any>(`${this.apiUrl}/cleanup`, {});
  }
}
