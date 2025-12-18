# Script 9: Generate App Configuration and Routing
# This script generates app config, routing, and main component

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Generating App Configuration..." -ForegroundColor Cyan
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

Write-Host "`n1. Creating App Routes..." -ForegroundColor Yellow

$appRoutesContent = @'
import { Routes } from '@angular/router';
import { authGuard } from './core/guards/auth.guard';
import { adminGuard } from './core/guards/admin.guard';

export const routes: Routes = [
  {
    path: '',
    redirectTo: '/auth/login',
    pathMatch: 'full'
  },
  {
    path: 'auth/login',
    loadComponent: () => import('./features/auth/login.component').then(m => m.LoginComponent)
  },
  {
    path: 'auth/register',
    loadComponent: () => import('./features/auth/register.component').then(m => m.RegisterComponent)
  },
  {
    path: 'client',
    loadComponent: () => import('./features/client/client.component').then(m => m.ClientComponent),
    canActivate: [authGuard]
  },
  {
    path: 'admin',
    loadComponent: () => import('./features/admin/admin.component').then(m => m.AdminComponent),
    canActivate: [authGuard, adminGuard]
  },
  {
    path: '**',
    redirectTo: '/auth/login'
  }
];
'@

Create-File -Path (Join-Path $appPath "app.routes.ts") -Content $appRoutesContent

Write-Host "`n2. Creating App Config..." -ForegroundColor Yellow

$appConfigContent = @'
import { ApplicationConfig, provideZoneChangeDetection } from '@angular/core';
import { provideRouter } from '@angular/router';
import { provideHttpClient, withInterceptors } from '@angular/common/http';
import { provideAnimationsAsync } from '@angular/platform-browser/animations/async';
import { routes } from './app.routes';
import { authInterceptor } from './core/interceptors/auth.interceptor';

export const appConfig: ApplicationConfig = {
  providers: [
    provideZoneChangeDetection({ eventCoalescing: true }),
    provideRouter(routes),
    provideHttpClient(
      withInterceptors([authInterceptor])
    ),
    provideAnimationsAsync()
  ]
};
'@

Create-File -Path (Join-Path $appPath "app.config.ts") -Content $appConfigContent

Write-Host "`n3. Creating App Component..." -ForegroundColor Yellow

$appComponentTs = @'
import { Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet],
  template: '<router-outlet></router-outlet>',
  styles: []
})
export class AppComponent {
  title = 'Learning Management System';
}
'@

Create-File -Path (Join-Path $appPath "app.component.ts") -Content $appComponentTs

Write-Host "`n4. Creating Main.ts..." -ForegroundColor Yellow

$mainTsContent = @'
import { bootstrapApplication } from '@angular/platform-browser';
import { appConfig } from './app/app.config';
import { AppComponent } from './app/app.component';

bootstrapApplication(AppComponent, appConfig)
  .catch((err) => console.error(err));
'@

Create-File -Path (Join-Path $frontendPath "src\main.ts") -Content $mainTsContent

Write-Host "`n5. Creating Index.html..." -ForegroundColor Yellow

$indexHtmlContent = @'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Learning Management System</title>
  <base href="/">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="icon" type="image/x-icon" href="favicon.ico">
  <link rel="preconnect" href="https://fonts.gstatic.com">
  <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@300;400;500&display=swap" rel="stylesheet">
  <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
</head>
<body>
  <app-root></app-root>
</body>
</html>
'@

Create-File -Path (Join-Path $frontendPath "src\index.html") -Content $indexHtmlContent

Write-Host "`n6. Updating angular.json for styles..." -ForegroundColor Yellow

$angularJsonPath = Join-Path $frontendPath "angular.json"
if (Test-Path $angularJsonPath) {
    Write-Host "Note: angular.json exists. Please manually add these styles to the styles array:" -ForegroundColor Yellow
    Write-Host '  "src/styles/styles.scss"' -ForegroundColor Cyan
} else {
    Write-Host "angular.json will be created when you run 2-setup-frontend.ps1" -ForegroundColor Yellow
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "App Configuration Generated!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "`nNext step: Run 10-generate-backend.ps1" -ForegroundColor Yellow
