export interface UserProgress {
  id: number;
  userId: number;
  fileId: number;
  status: ProgressStatus;
  lastPosition?: number;
  completedAt?: Date;
  updatedAt?: Date;
}

export enum ProgressStatus {
  NOT_STARTED = 'not_started',
  IN_PROGRESS = 'in_progress',
  COMPLETED = 'completed'
}

export interface LastViewed {
  userId: number;
  courseId: number;
  fileId: number;
  timestamp: Date;
}
