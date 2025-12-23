export interface ScanRequest {
  rootPath: string;
}

export enum ScanStatus {
  PENDING = 'pending',
  RUNNING = 'running',
  COMPLETED = 'completed',
  FAILED = 'failed',
  PARTIAL = 'partial'
}

export interface ScanResult {
  success: boolean;
  message: string;
  categoriesFound: number;
  coursesFound: number;
  filesAdded: number;
  filesRemoved: number;
  filesUpdated: number;
  errorsCount?: number;
  scanId?: number;
  status?: ScanStatus;
}

export interface ScanError {
  id: number;
  file_path: string;
  error_type: string;
  error_message: string;
  created_at: string;
}

export interface ScanHistory {
  id: number;
  started_by_id: number;
  started_at: string;
  completed_at: string | null;
  status: ScanStatus;
  root_path: string;
  categories_found: number;
  courses_found: number;
  files_added: number;
  files_updated: number;
  files_removed: number;
  errors_count: number;
  message: string | null;
  error_message: string | null;
  errors: ScanError[];
}
