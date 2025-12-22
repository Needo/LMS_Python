import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, BehaviorSubject } from 'rxjs';
import { tap } from 'rxjs/operators';
import { environment } from '../../../environments/environment';

export interface AppConfig {
  max_file_size: number;
  allowed_extensions: string[];
  scan_depth: number;
  environment: string;
}

export interface RootPathValidationRequest {
  path: string;
}

export interface RootPathValidationResponse {
  valid: boolean;
  exists: boolean;
  readable: boolean;
  canonical: boolean;
  path?: string;
  error?: string;
}

@Injectable({
  providedIn: 'root'
})
export class ConfigService {
  private apiUrl = `${environment.apiUrl}/config`;
  private configSubject = new BehaviorSubject<AppConfig | null>(null);
  
  public config$ = this.configSubject.asObservable();

  constructor(private http: HttpClient) {}

  /**
   * Load public configuration from backend
   */
  loadConfig(): Observable<AppConfig> {
    return this.http.get<AppConfig>(`${this.apiUrl}/public`).pipe(
      tap(config => this.configSubject.next(config))
    );
  }

  /**
   * Get current config (synchronous)
   */
  getConfig(): AppConfig | null {
    return this.configSubject.value;
  }

  /**
   * Validate root folder path (admin only)
   */
  validateRootPath(path: string): Observable<RootPathValidationResponse> {
    return this.http.post<RootPathValidationResponse>(
      `${this.apiUrl}/validate-root-path`,
      { path }
    );
  }

  /**
   * Check if file size is within allowed limit
   */
  isFileSizeAllowed(sizeInBytes: number): boolean {
    const config = this.getConfig();
    if (!config) return false;
    return sizeInBytes <= config.max_file_size;
  }

  /**
   * Check if file extension is allowed
   */
  isExtensionAllowed(filename: string): boolean {
    const config = this.getConfig();
    if (!config) return false;
    
    const ext = this.getFileExtension(filename);
    return config.allowed_extensions.includes(ext);
  }

  /**
   * Get file extension from filename
   */
  private getFileExtension(filename: string): string {
    const parts = filename.split('.');
    if (parts.length < 2) return '';
    return '.' + parts[parts.length - 1].toLowerCase();
  }

  /**
   * Format file size for display
   */
  formatFileSize(bytes: number): string {
    if (bytes === 0) return '0 Bytes';
    
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    
    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
  }

  /**
   * Get max file size formatted
   */
  getMaxFileSizeFormatted(): string {
    const config = this.getConfig();
    if (!config) return 'Unknown';
    return this.formatFileSize(config.max_file_size);
  }

  /**
   * Get allowed extensions as comma-separated string
   */
  getAllowedExtensionsString(): string {
    const config = this.getConfig();
    if (!config) return '';
    return config.allowed_extensions.join(', ');
  }
}
