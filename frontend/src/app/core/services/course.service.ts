import { Injectable, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, tap, map } from 'rxjs';
import { environment } from '../../../environments/environment';
import { Course } from '../models/course.model';

@Injectable({
  providedIn: 'root'
})
export class CourseService {
  private apiUrl = `${environment.apiUrl}/courses`;
  private coursesSignal = signal<Course[]>([]);

  courses = this.coursesSignal.asReadonly();

  constructor(private http: HttpClient) {}

  getCourses(): Observable<Course[]> {
    return this.http.get<any[]>(this.apiUrl)
      .pipe(
        map(courses => courses.map(course => ({
          id: course.id,
          categoryId: course.category_id,
          name: course.name,
          description: course.description,
          path: course.path,
          createdAt: course.created_at
        }))),
        tap(courses => this.coursesSignal.set(courses))
      );
  }

  getCoursesByCategory(categoryId: number): Observable<Course[]> {
    return this.http.get<any[]>(`${this.apiUrl}/category/${categoryId}`)
      .pipe(
        map(courses => courses.map(course => ({
          id: course.id,
          categoryId: course.category_id,
          name: course.name,
          description: course.description,
          path: course.path,
          createdAt: course.created_at
        })))
      );
  }

  getCourseById(id: number): Observable<Course> {
    return this.http.get<any>(`${this.apiUrl}/${id}`)
      .pipe(
        map(course => ({
          id: course.id,
          categoryId: course.category_id,
          name: course.name,
          description: course.description,
          path: course.path,
          createdAt: course.created_at
        }))
      );
  }

  getEnrolledCourses(userId: number): Observable<Course[]> {
    return this.http.get<any[]>(`${environment.apiUrl}/enrollments/user/${userId}`)
      .pipe(
        map(enrollments => enrollments.map(enrollment => ({
          id: enrollment.course.id,
          categoryId: enrollment.course.category_id,
          name: enrollment.course.name,
          description: enrollment.course.description,
          path: enrollment.course.path,
          createdAt: enrollment.course.created_at
        })))
      );
  }
}
