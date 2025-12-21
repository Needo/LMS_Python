import { HttpInterceptorFn, HttpErrorResponse } from '@angular/common/http';
import { inject } from '@angular/core';
import { Router } from '@angular/router';
import { catchError, throwError } from 'rxjs';
import { AuthService } from '../services/auth.service';

export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const authService = inject(AuthService);
  const router = inject(Router);
  const token = authService.getToken();

  if (token) {
    const cloned = req.clone({
      headers: req.headers.set('Authorization', `Bearer ${token}`)
    });
    
    return next(cloned).pipe(
      catchError((error: HttpErrorResponse) => {
        // Handle 401 Unauthorized (session timeout or invalid token)
        if (error.status === 401) {
          console.log('Session expired. Redirecting to login...');
          authService.logout();
          router.navigate(['/auth/login'], {
            queryParams: { returnUrl: router.url, sessionExpired: 'true' }
          });
        }
        return throwError(() => error);
      })
    );
  }

  return next(req);
};

