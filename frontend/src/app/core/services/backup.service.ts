import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface Backup {
  id: number;
  filename: string;
  file_size: number;
  backup_type: string;
  created_by: string;
  created_at: Date;
  status: string;
  notes?: string;
}

export interface BackupListResponse {
  backups: Backup[];
  total: number;
}

export interface BackupStatus {
  is_locked: boolean;
  operation_type?: string;
  locked_by?: string;
  locked_at?: Date;
}

@Injectable({
  providedIn: 'root'
})
export class BackupService {
  private apiUrl = `${environment.apiUrl}/admin/backup`;

  constructor(private http: HttpClient) {}

  createBackup(notes?: string): Observable<Backup> {
    return this.http.post<Backup>(`${this.apiUrl}/create`, { notes });
  }

  listBackups(): Observable<BackupListResponse> {
    return this.http.get<BackupListResponse>(`${this.apiUrl}/list`);
  }

  downloadBackup(backupId: number): Observable<Blob> {
    return this.http.get(`${this.apiUrl}/download/${backupId}`, {
      responseType: 'blob'
    });
  }

  restoreBackup(backupId: number, confirm: boolean): Observable<any> {
    return this.http.post(`${this.apiUrl}/restore/${backupId}`, { 
      backup_id: backupId,
      confirm 
    });
  }

  deleteBackup(backupId: number): Observable<any> {
    return this.http.delete(`${this.apiUrl}/${backupId}`);
  }

  getStatus(): Observable<BackupStatus> {
    return this.http.get<BackupStatus>(`${this.apiUrl}/status`);
  }
}
