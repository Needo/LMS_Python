import { Injectable, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, tap } from 'rxjs';
import { environment } from '../../../environments/environment';
import { UserProgress, LastViewed, ProgressStatus } from '../models/progress.model';

@Injectable({
  providedIn: 'root'
})
export class ProgressService {
  private apiUrl = `${environment.apiUrl}/progress`;
  private currentProgressSignal = signal<UserProgress | null>(null);
  private lastViewedSignal = signal<LastViewed | null>(null);

  currentProgress = this.currentProgressSignal.asReadonly();
  lastViewed = this.lastViewedSignal.asReadonly();

  constructor(private http: HttpClient) {}

  getUserProgress(userId: number, fileId: number): Observable<UserProgress> {
    return this.http.get<UserProgress>(`${this.apiUrl}/user/${userId}/file/${fileId}`)
      .pipe(
        tap(progress => this.currentProgressSignal.set(progress))
      );
  }

  updateProgress(userId: number, fileId: number, status: ProgressStatus, lastPosition?: number): Observable<UserProgress> {
    return this.http.post<UserProgress>(`${this.apiUrl}`, {
      user_id: userId,
      file_id: fileId,
      status: status,
      last_position: lastPosition
    }).pipe(
      tap(progress => this.currentProgressSignal.set(progress))
    );
  }

  getLastViewed(userId: number): Observable<LastViewed> {
    return this.http.get<LastViewed>(`${this.apiUrl}/user/${userId}/last-viewed`)
      .pipe(
        tap(lastViewed => this.lastViewedSignal.set(lastViewed))
      );
  }

  setLastViewed(userId: number, courseId: number, fileId: number): Observable<LastViewed> {
    return this.http.post<LastViewed>(`${this.apiUrl}/last-viewed`, {
      user_id: userId,
      course_id: courseId,
      file_id: fileId
    }).pipe(
      tap(lastViewed => this.lastViewedSignal.set(lastViewed))
    );
  }

  getAllUserProgress(userId: number): Observable<UserProgress[]> {
    return this.http.get<UserProgress[]>(`${this.apiUrl}/user/${userId}`);
  }
}
