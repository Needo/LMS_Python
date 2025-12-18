import { Injectable, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, tap } from 'rxjs';
import { environment } from '../../../environments/environment';
import { Course } from '../models/user.model';

@Injectable({
  providedIn: 'root'
})
export class CourseService {
  private apiUrl = `${environment.apiUrl}/courses`;
  private coursesSignal = signal<Course[]>([]);

  courses = this.coursesSignal.asReadonly();

  constructor(private http: HttpClient) {}

  getCoursesByCategory(categoryId: number): Observable<Course[]> {
    return this.http.get<Course[]>(`${this.apiUrl}/category/${categoryId}`)
      .pipe(
        tap(courses => this.coursesSignal.set(courses))
      );
  }

  getCourseById(id: number): Observable<Course> {
    return this.http.get<Course>(`${this.apiUrl}/${id}`);
  }

  getAllCourses(): Observable<Course[]> {
    return this.http.get<Course[]>(this.apiUrl)
      .pipe(
        tap(courses => this.coursesSignal.set(courses))
      );
  }
}
