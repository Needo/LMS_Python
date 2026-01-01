import { Injectable, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, tap, map, switchMap } from 'rxjs';
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
        map(enrollments => {
          // Get unique course IDs from enrollments
          const courseIds = enrollments.map(e => e.course_id);
          return courseIds;
        }),
        // Then fetch all courses and filter by enrolled IDs
        switchMap(courseIds => 
          this.getCourses().pipe(
            map(allCourses => allCourses.filter(course => courseIds.includes(course.id)))
          )
        )
      );
  }
}
