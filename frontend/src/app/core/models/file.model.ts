export interface FileNode {
  id: number;
  courseId: number;
  name: string;
  path: string;
  fileType: string;
  parentId: number | null;
  isDirectory: boolean;
  size?: number;
  createdAt?: Date;
  children?: FileNode[];
}

export enum FileType {
  PDF = 'pdf',
  VIDEO = 'video',
  AUDIO = 'audio',
  IMAGE = 'image',
  TEXT = 'text',
  EPUB = 'epub',
  FOLDER = 'folder',
  UNKNOWN = 'unknown'
}
