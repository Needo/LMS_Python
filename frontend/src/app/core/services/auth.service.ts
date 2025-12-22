import { Injectable, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, tap, map } from 'rxjs';
import { environment } from '../../../environments/environment';
import { User, LoginRequest, LoginResponse, RegisterRequest } from '../models/user.model';

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private apiUrl = `${environment.apiUrl}/auth`;
  private currentUserSignal = signal<User | null>(null);
  private isAuthenticatedSignal = signal<boolean>(false);

  currentUser = this.currentUserSignal.asReadonly();
  isAuthenticated = this.isAuthenticatedSignal.asReadonly();

  constructor(private http: HttpClient) {
    this.loadUserFromStorage();
  }

  login(credentials: LoginRequest): Observable<LoginResponse> {
    return this.http.post<any>(`${this.apiUrl}/login`, credentials)
      .pipe(
        map(response => {
          // Convert snake_case to camelCase
          const user: User = {
            id: response.user.id,
            username: response.user.username,
            email: response.user.email,
            isAdmin: response.user.is_admin,
            createdAt: response.user.created_at
          };
          return {
            access_token: response.access_token,
            refresh_token: response.refresh_token, // NEW
            token_type: response.token_type,
            user: user
          };
        }),
        tap(response => {
          this.setSession(response);
        })
      );
  }

  register(data: RegisterRequest): Observable<User> {
    return this.http.post<any>(`${this.apiUrl}/register`, data)
      .pipe(
        map(response => ({
          id: response.id,
          username: response.username,
          email: response.email,
          isAdmin: response.is_admin,
          createdAt: response.created_at
        }))
      );
  }

  logout(): void {
    const refreshToken = localStorage.getItem('refresh_token');
    
    // Call logout endpoint to revoke refresh token
    if (refreshToken) {
      this.http.post(`${this.apiUrl}/logout`, { refresh_token: refreshToken })
        .subscribe();
    }
    
    // Clear local storage
    localStorage.removeItem('access_token');
    localStorage.removeItem('refresh_token');
    localStorage.removeItem('current_user');
    this.currentUserSignal.set(null);
    this.isAuthenticatedSignal.set(false);
  }
  
  refreshToken(): Observable<{access_token: string; token_type: string}> {
    const refreshToken = localStorage.getItem('refresh_token');
    
    if (!refreshToken) {
      throw new Error('No refresh token available');
    }
    
    return this.http.post<{access_token: string; token_type: string}>(
      `${this.apiUrl}/refresh`,
      { refresh_token: refreshToken }
    ).pipe(
      tap(response => {
        localStorage.setItem('access_token', response.access_token);
      })
    );
  }

  getToken(): string | null {
    return localStorage.getItem('access_token');
  }

  private setSession(authResult: LoginResponse): void {
    localStorage.setItem('access_token', authResult.access_token);
    if (authResult.refresh_token) {
      localStorage.setItem('refresh_token', authResult.refresh_token);
    }
    localStorage.setItem('current_user', JSON.stringify(authResult.user));
    this.currentUserSignal.set(authResult.user);
    this.isAuthenticatedSignal.set(true);
  }

  private loadUserFromStorage(): void {
    const token = localStorage.getItem('access_token');
    const userStr = localStorage.getItem('current_user');
    
    if (token && userStr) {
      try {
        const user = JSON.parse(userStr);
        this.currentUserSignal.set(user);
        this.isAuthenticatedSignal.set(true);
      } catch (e) {
        this.logout();
      }
    }
  }
}
