import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface User {
  id: number;
  username: string;
  email?: string;
  isAdmin: boolean;
  created_at: string;
  enrollment_count?: number;
}

export interface UserCreate {
  username: string;
  email?: string;
  password: string;
  isAdmin?: boolean;
}

export interface UserUpdate {
  username?: string;
  email?: string;
  password?: string;
  isAdmin?: boolean;
}

export interface UserEnrollment {
  id: number;
  course_id: number;
  course_name: string;
  enrolled_at: string;
}

@Injectable({
  providedIn: 'root'
})
export class UserService {
  private apiUrl = `${environment.apiUrl}/users`;

  constructor(private http: HttpClient) {}

  getUsers(): Observable<User[]> {
    return this.http.get<User[]>(this.apiUrl);
  }

  getUser(id: number): Observable<User> {
    return this.http.get<User>(`${this.apiUrl}/${id}`);
  }

  createUser(user: UserCreate): Observable<User> {
    return this.http.post<User>(this.apiUrl, user);
  }

  updateUser(id: number, user: UserUpdate): Observable<User> {
    return this.http.put<User>(`${this.apiUrl}/${id}`, user);
  }

  deleteUser(id: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/${id}`);
  }

  getUserEnrollments(userId: number): Observable<UserEnrollment[]> {
    return this.http.get<UserEnrollment[]>(`${this.apiUrl}/${userId}/enrollments`);
  }

  enrollUserInCourse(userId: number, courseId: number): Observable<UserEnrollment> {
    return this.http.post<UserEnrollment>(`${this.apiUrl}/${userId}/enrollments/${courseId}`, {});
  }

  unenrollUserFromCourse(userId: number, courseId: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/${userId}/enrollments/${courseId}`);
  }
}
