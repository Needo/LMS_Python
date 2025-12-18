# Script 5: Generate Frontend Components (Part 1 - Auth & Guards)
# This script generates authentication components and guards

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Generating Auth Components & Guards..." -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

$rootPath = "C:\Users\munawar\Documents\Python_LMS_V2"
$frontendPath = Join-Path $rootPath "frontend"
$appPath = Join-Path $frontendPath "src\app"

# Function to create file with content
function Create-File {
    param (
        [string]$Path,
        [string]$Content
    )
    $directory = Split-Path $Path -Parent
    if (-not (Test-Path $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    Set-Content -Path $Path -Value $Content -Encoding UTF8
    Write-Host "Created: $Path" -ForegroundColor Green
}

Write-Host "`n1. Creating Auth Guard..." -ForegroundColor Yellow

$authGuardContent = @'
import { inject } from '@angular/core';
import { Router, type CanActivateFn } from '@angular/router';
import { AuthService } from '../services/auth.service';

export const authGuard: CanActivateFn = (route, state) => {
  const authService = inject(AuthService);
  const router = inject(Router);

  if (authService.isAuthenticated()) {
    return true;
  }

  router.navigate(['/auth/login']);
  return false;
};
'@

Create-File -Path (Join-Path $appPath "core\guards\auth.guard.ts") -Content $authGuardContent

Write-Host "`n2. Creating Admin Guard..." -ForegroundColor Yellow

$adminGuardContent = @'
import { inject } from '@angular/core';
import { Router, type CanActivateFn } from '@angular/router';
import { AuthService } from '../services/auth.service';

export const adminGuard: CanActivateFn = (route, state) => {
  const authService = inject(AuthService);
  const router = inject(Router);

  const user = authService.currentUser();
  
  if (user && user.isAdmin) {
    return true;
  }

  router.navigate(['/client']);
  return false;
};
'@

Create-File -Path (Join-Path $appPath "core\guards\admin.guard.ts") -Content $adminGuardContent

Write-Host "`n3. Creating Auth Interceptor..." -ForegroundColor Yellow

$authInterceptorContent = @'
import { HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { AuthService } from '../services/auth.service';

export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const authService = inject(AuthService);
  const token = authService.getToken();

  if (token) {
    const cloned = req.clone({
      headers: req.headers.set('Authorization', `Bearer ${token}`)
    });
    return next(cloned);
  }

  return next(req);
};
'@

Create-File -Path (Join-Path $appPath "core\interceptors\auth.interceptor.ts") -Content $authInterceptorContent

Write-Host "`n4. Creating Login Component..." -ForegroundColor Yellow

$loginComponentTs = @'
import { Component, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { MatCardModule } from '@angular/material/card';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { AuthService } from '../../../core/services';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    RouterModule,
    MatCardModule,
    MatFormFieldModule,
    MatInputModule,
    MatButtonModule,
    MatProgressSpinnerModule
  ],
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.scss']
})
export class LoginComponent {
  loginForm: FormGroup;
  isLoading = signal(false);
  errorMessage = signal<string | null>(null);

  constructor(
    private fb: FormBuilder,
    private authService: AuthService,
    private router: Router
  ) {
    this.loginForm = this.fb.group({
      username: ['', Validators.required],
      password: ['', Validators.required]
    });
  }

  onSubmit(): void {
    if (this.loginForm.valid) {
      this.isLoading.set(true);
      this.errorMessage.set(null);

      this.authService.login(this.loginForm.value).subscribe({
        next: (response) => {
          this.isLoading.set(false);
          if (response.user.isAdmin) {
            this.router.navigate(['/admin']);
          } else {
            this.router.navigate(['/client']);
          }
        },
        error: (error) => {
          this.isLoading.set(false);
          this.errorMessage.set(error.error?.message || 'Login failed');
        }
      });
    }
  }
}
'@

$loginComponentHtml = @'
<div class="form-container">
  <mat-card>
    <mat-card-header>
      <mat-card-title>Login to LMS</mat-card-title>
    </mat-card-header>
    <mat-card-content>
      <form [formGroup]="loginForm" (ngSubmit)="onSubmit()">
        <mat-form-field class="form-field">
          <mat-label>Username</mat-label>
          <input matInput formControlName="username" required>
        </mat-form-field>

        <mat-form-field class="form-field">
          <mat-label>Password</mat-label>
          <input matInput type="password" formControlName="password" required>
        </mat-form-field>

        @if (errorMessage()) {
          <div class="error-message">{{ errorMessage() }}</div>
        }

        <div class="action-buttons">
          <button mat-raised-button color="primary" type="submit" [disabled]="isLoading()">
            @if (isLoading()) {
              <mat-spinner diameter="20"></mat-spinner>
            } @else {
              Login
            }
          </button>
          <a mat-button routerLink="/auth/register">Register</a>
        </div>
      </form>
    </mat-card-content>
  </mat-card>
</div>
'@

$loginComponentScss = @'
.error-message {
  color: #f44336;
  margin: 16px 0;
  font-size: 14px;
}
'@

Create-File -Path (Join-Path $appPath "features\auth\login.component.ts") -Content $loginComponentTs
Create-File -Path (Join-Path $appPath "features\auth\login.component.html") -Content $loginComponentHtml
Create-File -Path (Join-Path $appPath "features\auth\login.component.scss") -Content $loginComponentScss

Write-Host "`n5. Creating Register Component..." -ForegroundColor Yellow

$registerComponentTs = @'
import { Component, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { MatCardModule } from '@angular/material/card';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { AuthService } from '../../../core/services';

@Component({
  selector: 'app-register',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    RouterModule,
    MatCardModule,
    MatFormFieldModule,
    MatInputModule,
    MatButtonModule,
    MatProgressSpinnerModule
  ],
  templateUrl: './register.component.html',
  styleUrls: ['./register.component.scss']
})
export class RegisterComponent {
  registerForm: FormGroup;
  isLoading = signal(false);
  errorMessage = signal<string | null>(null);
  successMessage = signal<string | null>(null);

  constructor(
    private fb: FormBuilder,
    private authService: AuthService,
    private router: Router
  ) {
    this.registerForm = this.fb.group({
      username: ['', Validators.required],
      email: ['', [Validators.required, Validators.email]],
      password: ['', [Validators.required, Validators.minLength(6)]]
    });
  }

  onSubmit(): void {
    if (this.registerForm.valid) {
      this.isLoading.set(true);
      this.errorMessage.set(null);

      this.authService.register(this.registerForm.value).subscribe({
        next: () => {
          this.isLoading.set(false);
          this.successMessage.set('Registration successful! Redirecting to login...');
          setTimeout(() => {
            this.router.navigate(['/auth/login']);
          }, 2000);
        },
        error: (error) => {
          this.isLoading.set(false);
          this.errorMessage.set(error.error?.message || 'Registration failed');
        }
      });
    }
  }
}
'@

$registerComponentHtml = @'
<div class="form-container">
  <mat-card>
    <mat-card-header>
      <mat-card-title>Register for LMS</mat-card-title>
    </mat-card-header>
    <mat-card-content>
      <form [formGroup]="registerForm" (ngSubmit)="onSubmit()">
        <mat-form-field class="form-field">
          <mat-label>Username</mat-label>
          <input matInput formControlName="username" required>
        </mat-form-field>

        <mat-form-field class="form-field">
          <mat-label>Email</mat-label>
          <input matInput type="email" formControlName="email" required>
        </mat-form-field>

        <mat-form-field class="form-field">
          <mat-label>Password</mat-label>
          <input matInput type="password" formControlName="password" required>
        </mat-form-field>

        @if (errorMessage()) {
          <div class="error-message">{{ errorMessage() }}</div>
        }

        @if (successMessage()) {
          <div class="success-message">{{ successMessage() }}</div>
        }

        <div class="action-buttons">
          <button mat-raised-button color="primary" type="submit" [disabled]="isLoading()">
            @if (isLoading()) {
              <mat-spinner diameter="20"></mat-spinner>
            } @else {
              Register
            }
          </button>
          <a mat-button routerLink="/auth/login">Back to Login</a>
        </div>
      </form>
    </mat-card-content>
  </mat-card>
</div>
'@

$registerComponentScss = @'
.error-message {
  color: #f44336;
  margin: 16px 0;
  font-size: 14px;
}

.success-message {
  color: #4caf50;
  margin: 16px 0;
  font-size: 14px;
}
'@

Create-File -Path (Join-Path $appPath "features\auth\register.component.ts") -Content $registerComponentTs
Create-File -Path (Join-Path $appPath "features\auth\register.component.html") -Content $registerComponentHtml
Create-File -Path (Join-Path $appPath "features\auth\register.component.scss") -Content $registerComponentScss

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "Auth Components & Guards Generated!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "`nNext step: Run 6-generate-admin-components.ps1" -ForegroundColor Yellow
