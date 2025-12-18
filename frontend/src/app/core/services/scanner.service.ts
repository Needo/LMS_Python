import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { ScanRequest, ScanResult } from '../models/scan.model';

@Injectable({
  providedIn: 'root'
})
export class ScannerService {
  private apiUrl = `${environment.apiUrl}/scanner`;

  constructor(private http: HttpClient) {}

  scanRootFolder(request: ScanRequest): Observable<ScanResult> {
    return this.http.post<ScanResult>(`${this.apiUrl}/scan`, request);
  }

  rescanCourse(courseId: number): Observable<ScanResult> {
    return this.http.post<ScanResult>(`${this.apiUrl}/rescan/${courseId}`, {});
  }

  getRootPath(): Observable<{ rootPath: string }> {
    return this.http.get<{ rootPath: string }>(`${this.apiUrl}/root-path`);
  }

  setRootPath(rootPath: string): Observable<{ success: boolean }> {
    return this.http.post<{ success: boolean }>(`${this.apiUrl}/root-path`, { rootPath });
  }
}
