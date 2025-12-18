export interface ScanRequest {
  rootPath: string;
}

export interface ScanResult {
  success: boolean;
  message: string;
  categoriesFound: number;
  coursesFound: number;
  filesAdded: number;
  filesRemoved: number;
  filesUpdated: number;
}
