import { Injectable } from '@angular/core';
import { HttpClient, HttpEvent, HttpEventType } from '@angular/common/http';
import { Observable, throwError } from 'rxjs';
import { map, catchError, switchMap } from 'rxjs/operators';
import { environment } from '../../../environments/environment';
import { AuthService } from './auth.service';

export interface CourseUploadRequest {
  categoryId: number;
  courseName: string;
  files: FileUploadItem[];
}

export interface FileUploadItem {
  file: File;
  relativePath: string;
}

export interface CourseUploadResponse {
  courseId: number;
  courseName: string;
  filesUploaded: number;
  message: string;
}

export interface UploadProgress {
  progress: number;
  loaded: number;
  total: number;
}

@Injectable({
  providedIn: 'root'
})
export class CourseUploadService {
  private apiUrl = `${environment.apiUrl}/courses/upload`;

  constructor(
    private http: HttpClient,
    private authService: AuthService
  ) {}

  /**
   * Upload a course folder with all files
   * Refreshes token first to prevent expiration during upload
   */
  uploadCourseFolder(
    categoryId: number,
    courseName: string,
    files: FileUploadItem[]
  ): Observable<CourseUploadResponse | UploadProgress> {
    // First refresh the token to ensure we have a valid token for the entire upload
    return this.authService.refreshToken().pipe(
      switchMap(() => {
        const formData = new FormData();
        
        // Add metadata
        formData.append('categoryId', categoryId.toString());
        formData.append('courseName', courseName);
        
        // Add all files with their relative paths
        files.forEach((item) => {
          formData.append('files', item.file);
          formData.append('paths', item.relativePath);
        });

        return this.http.post<CourseUploadResponse>(this.apiUrl, formData, {
          reportProgress: true,
          observe: 'events'
        }).pipe(
          map(event => {
            if (event.type === HttpEventType.UploadProgress && event.total) {
              // Progress event
              return {
                progress: Math.round(100 * event.loaded / event.total),
                loaded: event.loaded,
                total: event.total
              } as UploadProgress;
            } else if (event.type === HttpEventType.Response) {
              // Complete
              return event.body as CourseUploadResponse;
            }
            // Other events, return empty progress
            return { progress: 0, loaded: 0, total: 0 } as UploadProgress;
          }),
          catchError(error => {
            console.error('Upload error:', error);
            return throwError(() => error);
          })
        );
      }),
      catchError(error => {
        console.error('Token refresh error:', error);
        return throwError(() => error);
      })
    );
  }
}
