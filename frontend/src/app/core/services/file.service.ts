import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, map } from 'rxjs';
import { environment } from '../../../environments/environment';
import { FileNode, FileType } from '../models/file.model';

@Injectable({
  providedIn: 'root'
})
export class FileService {
  private apiUrl = `${environment.apiUrl}/files`;

  constructor(private http: HttpClient) {}

  getFilesByCourse(courseId: number): Observable<FileNode[]> {
    return this.http.get<any[]>(`${this.apiUrl}/course/${courseId}`)
      .pipe(
        map(files => files.map(file => ({
          id: file.id,
          courseId: file.course_id,
          name: file.name,
          path: file.path,
          fileType: file.file_type,
          parentId: file.parent_id,
          isDirectory: file.is_directory,
          size: file.size,
          createdAt: file.created_at ? new Date(file.created_at) : undefined
        })))
      );
  }

  getFileById(id: number): Observable<FileNode> {
    return this.http.get<any>(`${this.apiUrl}/${id}`)
      .pipe(
        map(file => ({
          id: file.id,
          courseId: file.course_id,
          name: file.name,
          path: file.path,
          fileType: file.file_type,
          parentId: file.parent_id,
          isDirectory: file.is_directory,
          size: file.size,
          createdAt: file.created_at ? new Date(file.created_at) : undefined
        }))
      );
  }

  getFileContent(id: number): Observable<Blob> {
    return this.http.get(`${this.apiUrl}/${id}/content`, { 
      responseType: 'blob' 
    });
  }

  getFileType(filename: string): FileType {
    const ext = filename.split('.').pop()?.toLowerCase();
    
    switch (ext) {
      case 'pdf':
        return FileType.PDF;
      case 'mp4':
      case 'avi':
      case 'mkv':
      case 'mov':
      case 'webm':
        return FileType.VIDEO;
      case 'mp3':
      case 'wav':
      case 'ogg':
      case 'm4a':
        return FileType.AUDIO;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
        return FileType.IMAGE;
      case 'txt':
      case 'md':
      case 'log':
        return FileType.TEXT;
      case 'epub':
        return FileType.EPUB;
      default:
        return FileType.UNKNOWN;
    }
  }

  getFileIcon(fileType: FileType): string {
    switch (fileType) {
      case FileType.PDF:
        return 'picture_as_pdf';
      case FileType.VIDEO:
        return 'video_library';
      case FileType.AUDIO:
        return 'audio_file';
      case FileType.IMAGE:
        return 'image';
      case FileType.TEXT:
        return 'description';
      case FileType.EPUB:
        return 'menu_book';
      case FileType.FOLDER:
        return 'folder';
      default:
        return 'insert_drive_file';
    }
  }
}
