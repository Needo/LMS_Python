import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

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

@Injectable({
  providedIn: 'root'
})
export class CourseUploadService {
  private apiUrl = `${environment.apiUrl}/courses/upload`;

  constructor(private http: HttpClient) {}

  /**
   * Upload a course folder with all files
   */
  uploadCourseFolder(
    categoryId: number,
    courseName: string,
    files: FileUploadItem[]
  ): Observable<CourseUploadResponse> {
    const formData = new FormData();
    
    // Add metadata
    formData.append('categoryId', categoryId.toString());
    formData.append('courseName', courseName);
    
    // Add all files with their relative paths
    files.forEach((item, index) => {
      formData.append(`files`, item.file);
      formData.append(`paths`, item.relativePath);
    });

    return this.http.post<CourseUploadResponse>(this.apiUrl, formData, {
      reportProgress: true
    });
  }
}
