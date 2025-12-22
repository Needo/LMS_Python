import { HttpInterceptorFn, HttpErrorResponse } from '@angular/common/http';
import { inject } from '@angular/core';
import { Router } from '@angular/router';
import { catchError, switchMap, throwError } from 'rxjs';
import { AuthService } from '../services/auth.service';

let isRefreshing = false;

export const tokenRefreshInterceptor: HttpInterceptorFn = (req, next) => {
  const authService = inject(AuthService);
  const router = inject(Router);

  return next(req).pipe(
    catchError((error: HttpErrorResponse) => {
      // If 401 and not already refreshing and not a login/refresh request
      if (
        error.status === 401 &&
        !isRefreshing &&
        !req.url.includes('/auth/login') &&
        !req.url.includes('/auth/refresh')
      ) {
        isRefreshing = true;

        // Try to refresh token
        return authService.refreshToken().pipe(
          switchMap(() => {
            isRefreshing = false;
            // Retry the original request with new token
            const newReq = req.clone({
              setHeaders: {
                Authorization: `Bearer ${authService.getToken()}`
              }
            });
            return next(newReq);
          }),
          catchError((refreshError) => {
            isRefreshing = false;
            // Refresh failed, logout and redirect
            authService.logout();
            router.navigate(['/auth/login'], {
              queryParams: { returnUrl: router.url, sessionExpired: true }
            });
            return throwError(() => refreshError);
          })
        );
      }

      return throwError(() => error);
    })
  );
};
