# Script 3: Generate All Frontend Files
# This script generates all Angular components, services, and configuration files

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Generating Frontend Files..." -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

$rootPath = "C:\Users\munawar\Documents\Python_LMS_V2"
$frontendPath = Join-Path $rootPath "frontend"
$srcPath = Join-Path $frontendPath "src"
$appPath = Join-Path $srcPath "app"

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

Write-Host "`n1. Creating global styles..." -ForegroundColor Yellow

# Global styles
$stylesContent = @'
/* Global Styles - Shared across all components */
@import '@angular/material/prebuilt-themes/indigo-pink.css';

* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

html, body {
  height: 100%;
  font-family: Roboto, "Helvetica Neue", sans-serif;
}

body {
  margin: 0;
}

/* Layout Styles */
.full-height {
  height: 100vh;
  display: flex;
  flex-direction: column;
}

.content-container {
  flex: 1;
  display: flex;
  overflow: hidden;
}

/* Panel Styles */
.panel {
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.panel-content {
  flex: 1;
  overflow: auto;
  padding: 16px;
}

/* Toolbar Styles */
.app-toolbar {
  background-color: #1976d2;
  color: white;
}

.toolbar-spacer {
  flex: 1 1 auto;
}

/* Tree View Styles */
.tree-container {
  height: 100%;
  overflow: auto;
}

.mat-tree-node {
  min-height: 40px;
  padding: 4px 8px;
}

.tree-icon {
  margin-right: 8px;
  vertical-align: middle;
}

/* Viewer Styles */
.viewer-container {
  height: 100%;
  display: flex;
  flex-direction: column;
}

.viewer-content {
  flex: 1;
  overflow: auto;
  background-color: #fafafa;
  padding: 16px;
}

.video-player,
.audio-player,
.pdf-viewer,
.epub-viewer {
  width: 100%;
  height: 100%;
}

.text-viewer {
  white-space: pre-wrap;
  font-family: 'Courier New', monospace;
  line-height: 1.6;
}

/* Resizer Styles */
.resizer {
  width: 5px;
  cursor: col-resize;
  background-color: #e0e0e0;
  flex-shrink: 0;
}

.resizer:hover {
  background-color: #1976d2;
}

/* Form Styles */
.form-container {
  max-width: 400px;
  margin: 50px auto;
  padding: 24px;
}

.form-field {
  width: 100%;
  margin-bottom: 16px;
}

/* Button Styles */
.action-buttons {
  display: flex;
  gap: 8px;
  margin-top: 16px;
}

/* Card Styles */
.mat-mdc-card {
  margin: 16px;
}

/* Loading Styles */
.loading-spinner {
  display: flex;
  justify-content: center;
  align-items: center;
  height: 100%;
}

/* Utility Classes */
.text-center {
  text-align: center;
}

.mt-16 {
  margin-top: 16px;
}

.mb-16 {
  margin-bottom: 16px;
}

.p-16 {
  padding: 16px;
}

/* File Type Icons Colors */
.icon-pdf {
  color: #d32f2f;
}

.icon-video {
  color: #7b1fa2;
}

.icon-audio {
  color: #0288d1;
}

.icon-image {
  color: #388e3c;
}

.icon-text {
  color: #f57c00;
}

.icon-epub {
  color: #5d4037;
}

.icon-folder {
  color: #fbc02d;
}

/* Scrollbar Styles */
::-webkit-scrollbar {
  width: 8px;
  height: 8px;
}

::-webkit-scrollbar-track {
  background: #f1f1f1;
}

::-webkit-scrollbar-thumb {
  background: #888;
  border-radius: 4px;
}

::-webkit-scrollbar-thumb:hover {
  background: #555;
}
'@

Create-File -Path (Join-Path $srcPath "styles\styles.scss") -Content $stylesContent

Write-Host "`n2. Creating environment files..." -ForegroundColor Yellow

# Environment files
$envDevContent = @'
export const environment = {
  production: false,
  apiUrl: 'http://localhost:8000/api'
};
'@

$envProdContent = @'
export const environment = {
  production: true,
  apiUrl: 'http://localhost:8000/api'
};
'@

Create-File -Path (Join-Path $srcPath "environments\environment.development.ts") -Content $envDevContent
Create-File -Path (Join-Path $srcPath "environments\environment.ts") -Content $envProdContent

Write-Host "`n3. Creating models..." -ForegroundColor Yellow

# Models
$userModelContent = @'
export interface User {
  id: number;
  username: string;
  email: string;
  isAdmin: boolean;
  createdAt?: Date;
}

export interface LoginRequest {
  username: string;
  password: string;
}

export interface LoginResponse {
  access_token: string;
  token_type: string;
  user: User;
}

export interface RegisterRequest {
  username: string;
  email: string;
  password: string;
}
'@

$categoryModelContent = @'
export interface Category {
  id: number;
  name: string;
  path: string;
  createdAt?: Date;
}
'@

$courseModelContent = @'
export interface Course {
  id: number;
  categoryId: number;
  name: string;
  path: string;
  createdAt?: Date;
}
'@

$fileModelContent = @'
export interface FileNode {
  id: number;
  courseId: number;
  name: string;
  path: string;
  fileType: string;
  parentId: number | null;
  isDirectory: boolean;
  size?: number;
  createdAt?: Date;
  children?: FileNode[];
}

export enum FileType {
  PDF = 'pdf',
  VIDEO = 'video',
  AUDIO = 'audio',
  IMAGE = 'image',
  TEXT = 'text',
  EPUB = 'epub',
  FOLDER = 'folder',
  UNKNOWN = 'unknown'
}
'@

$progressModelContent = @'
export interface UserProgress {
  id: number;
  userId: number;
  fileId: number;
  status: ProgressStatus;
  lastPosition?: number;
  completedAt?: Date;
  updatedAt?: Date;
}

export enum ProgressStatus {
  NOT_STARTED = 'not_started',
  IN_PROGRESS = 'in_progress',
  COMPLETED = 'completed'
}

export interface LastViewed {
  userId: number;
  courseId: number;
  fileId: number;
  timestamp: Date;
}
'@

$scanModelContent = @'
export interface ScanRequest {
  rootPath: string;
}

export interface ScanResult {
  success: boolean;
  message: string;
  categoriesFound: number;
  coursesFound: number;
  filesAdded: number;
  filesRemoved: number;
  filesUpdated: number;
}
'@

Create-File -Path (Join-Path $appPath "core\models\user.model.ts") -Content $userModelContent
Create-File -Path (Join-Path $appPath "core\models\category.model.ts") -Content $categoryModelContent
Create-File -Path (Join-Path $appPath "core\models\course.model.ts") -Content $courseModelContent
Create-File -Path (Join-Path $appPath "core\models\file.model.ts") -Content $fileModelContent
Create-File -Path (Join-Path $appPath "core\models\progress.model.ts") -Content $progressModelContent
Create-File -Path (Join-Path $appPath "core\models\scan.model.ts") -Content $scanModelContent

Write-Host "`n4. Creating index file for models..." -ForegroundColor Yellow

$modelsIndexContent = @'
export * from './user.model';
export * from './category.model';
export * from './course.model';
export * from './file.model';
export * from './progress.model';
export * from './scan.model';
'@

Create-File -Path (Join-Path $appPath "core\models\index.ts") -Content $modelsIndexContent

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "Part 1 completed: Models and Styles" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "`nNext step: Run 4-generate-frontend-services.ps1" -ForegroundColor Yellow
