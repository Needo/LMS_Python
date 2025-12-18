# Script 7: Generate Client Components (Part 1 - Main Client & Tree View)
# This script generates the client panel with tree view

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Generating Client Components (Part 1)..." -ForegroundColor Cyan
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

Write-Host "`n1. Creating Client Component (Main)..." -ForegroundColor Yellow

$clientComponentTs = @'
import { Component, signal, OnInit, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { MatToolbarModule } from '@angular/material/toolbar';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { AuthService } from '../../../core/services/auth.service';
import { CategoryService } from '../../../core/services/category.service';
import { CourseService } from '../../../core/services/course.service';
import { FileService } from '../../../core/services/file.service';
import { ProgressService } from '../../../core/services/progress.service';
import { FileNode } from '../../../core/models/file.model';
import { TreeViewComponent } from './components/tree-view.component';
import { FileViewerComponent } from './components/file-viewer.component';

@Component({
  selector: 'app-client',
  standalone: true,
  imports: [
    CommonModule,
    MatToolbarModule,
    MatButtonModule,
    MatIconModule,
    MatProgressSpinnerModule,
    TreeViewComponent,
    FileViewerComponent
  ],
  templateUrl: './client.component.html',
  styleUrls: ['./client.component.scss']
})
export class ClientComponent implements OnInit {
  currentUser = this.authService.currentUser;
  selectedFile = signal<FileNode | null>(null);
  isLoading = signal(false);
  
  leftPanelWidth = signal(300);
  isResizing = signal(false);

  constructor(
    private authService: AuthService,
    private categoryService: CategoryService,
    private courseService: CourseService,
    private fileService: FileService,
    private progressService: ProgressService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadLastViewed();
  }

  loadLastViewed(): void {
    const user = this.currentUser();
    if (user) {
      this.progressService.getLastViewed(user.id).subscribe({
        next: (lastViewed) => {
          if (lastViewed && lastViewed.fileId) {
            this.fileService.getFileById(lastViewed.fileId).subscribe({
              next: (file) => {
                this.selectedFile.set(file);
              },
              error: (error) => {
                console.error('Error loading last viewed file:', error);
              }
            });
          }
        },
        error: (error) => {
          console.error('Error loading last viewed:', error);
        }
      });
    }
  }

  onFileSelected(file: FileNode): void {
    this.selectedFile.set(file);
    
    const user = this.currentUser();
    if (user && file.courseId) {
      this.progressService.setLastViewed(user.id, file.courseId, file.id).subscribe({
        error: (error) => {
          console.error('Error saving last viewed:', error);
        }
      });
    }
  }

  onMouseDown(event: MouseEvent): void {
    this.isResizing.set(true);
    event.preventDefault();
  }

  onMouseMove(event: MouseEvent): void {
    if (this.isResizing()) {
      const newWidth = event.clientX;
      if (newWidth >= 200 && newWidth <= 600) {
        this.leftPanelWidth.set(newWidth);
      }
    }
  }

  onMouseUp(): void {
    this.isResizing.set(false);
  }

  navigateToAdmin(): void {
    this.router.navigate(['/admin']);
  }

  logout(): void {
    this.authService.logout();
    this.router.navigate(['/auth/login']);
  }
}
'@

$clientComponentHtml = @'
<div class="full-height" 
     (mousemove)="onMouseMove($event)" 
     (mouseup)="onMouseUp()">
  <mat-toolbar class="app-toolbar">
    <span>Learning Management System</span>
    <span class="toolbar-spacer"></span>
    <span class="user-info">{{ currentUser()?.username }}</span>
    @if (currentUser()?.isAdmin) {
      <button mat-button (click)="navigateToAdmin()">
        <mat-icon>admin_panel_settings</mat-icon>
        Admin Panel
      </button>
    }
    <button mat-button (click)="logout()">
      <mat-icon>logout</mat-icon>
      Logout
    </button>
  </mat-toolbar>

  <div class="content-container">
    <div class="left-panel panel" [style.width.px]="leftPanelWidth()">
      <app-tree-view 
        (fileSelected)="onFileSelected($event)">
      </app-tree-view>
    </div>

    <div class="resizer" 
         (mousedown)="onMouseDown($event)"
         [class.resizing]="isResizing()">
    </div>

    <div class="right-panel panel">
      @if (selectedFile()) {
        <app-file-viewer [file]="selectedFile()!"></app-file-viewer>
      } @else {
        <div class="empty-state">
          <mat-icon>folder_open</mat-icon>
          <p>Select a file from the tree to view</p>
        </div>
      }
    </div>
  </div>
</div>
'@

$clientComponentScss = @'
.left-panel {
  min-width: 200px;
  max-width: 600px;
  background-color: #fafafa;
  border-right: 1px solid #e0e0e0;
}

.right-panel {
  flex: 1;
  background-color: white;
}

.resizer {
  transition: background-color 0.2s;
}

.resizer.resizing {
  background-color: #1976d2 !important;
}

.empty-state {
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  height: 100%;
  color: #999;
}

.empty-state mat-icon {
  font-size: 64px;
  width: 64px;
  height: 64px;
  margin-bottom: 16px;
}

.empty-state p {
  font-size: 16px;
}

.user-info {
  margin-right: 16px;
  font-weight: 500;
}
'@

Create-File -Path (Join-Path $appPath "features\client\client.component.ts") -Content $clientComponentTs
Create-File -Path (Join-Path $appPath "features\client\client.component.html") -Content $clientComponentHtml
Create-File -Path (Join-Path $appPath "features\client\client.component.scss") -Content $clientComponentScss

Write-Host "`n2. Creating Tree View Component..." -ForegroundColor Yellow

$treeViewComponentTs = @'
import { Component, OnInit, signal, Output, EventEmitter, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatTreeModule, MatTreeNestedDataSource } from '@angular/material/tree';
import { NestedTreeControl } from '@angular/cdk/tree';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonModule } from '@angular/material/button';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { CategoryService } from '../../../../core/services/category.service';
import { CourseService } from '../../../../core/services/course.service';
import { FileService } from '../../../../core/services/file.service';
import { Category } from '../../../../core/models/category.model';
import { Course } from '../../../../core/models/course.model';
import { FileNode, FileType } from '../../../../core/models/file.model';

interface TreeNode {
  id: number;
  name: string;
  type: 'category' | 'course' | 'file' | 'folder';
  fileType?: FileType;
  children?: TreeNode[];
  fileData?: FileNode;
  isExpandable: boolean;
}

@Component({
  selector: 'app-tree-view',
  standalone: true,
  imports: [
    CommonModule,
    MatTreeModule,
    MatIconModule,
    MatButtonModule,
    MatProgressSpinnerModule
  ],
  templateUrl: './tree-view.component.html',
  styleUrls: ['./tree-view.component.scss']
})
export class TreeViewComponent implements OnInit {
  @Output() fileSelected = new EventEmitter<FileNode>();

  treeControl = new NestedTreeControl<TreeNode>(node => node.children);
  dataSource = new MatTreeNestedDataSource<TreeNode>();
  
  isLoading = signal(false);
  selectedNodeId = signal<number | null>(null);

  constructor(
    private categoryService: CategoryService,
    private courseService: CourseService,
    private fileService: FileService
  ) {}

  ngOnInit(): void {
    this.loadTree();
  }

  loadTree(): void {
    this.isLoading.set(true);
    
    this.categoryService.getCategories().subscribe({
      next: (categories) => {
        const treeData: TreeNode[] = categories.map(category => ({
          id: category.id,
          name: category.name,
          type: 'category',
          isExpandable: true,
          children: []
        }));
        
        this.dataSource.data = treeData;
        this.isLoading.set(false);
      },
      error: (error) => {
        console.error('Error loading categories:', error);
        this.isLoading.set(false);
      }
    });
  }

  hasChild = (_: number, node: TreeNode) => node.isExpandable;

  toggleNode(node: TreeNode): void {
    if (node.type === 'category' && (!node.children || node.children.length === 0)) {
      this.loadCoursesForCategory(node);
    } else if (node.type === 'course' && (!node.children || node.children.length === 0)) {
      this.loadFilesForCourse(node);
    }
    
    this.treeControl.toggle(node);
  }

  loadCoursesForCategory(categoryNode: TreeNode): void {
    this.courseService.getCoursesByCategory(categoryNode.id).subscribe({
      next: (courses) => {
        categoryNode.children = courses.map(course => ({
          id: course.id,
          name: course.name,
          type: 'course',
          isExpandable: true,
          children: []
        }));
        
        this.dataSource.data = [...this.dataSource.data];
      },
      error: (error) => {
        console.error('Error loading courses:', error);
      }
    });
  }

  loadFilesForCourse(courseNode: TreeNode): void {
    this.fileService.getFilesByCourse(courseNode.id).subscribe({
      next: (files) => {
        courseNode.children = this.buildFileTree(files);
        this.dataSource.data = [...this.dataSource.data];
      },
      error: (error) => {
        console.error('Error loading files:', error);
      }
    });
  }

  buildFileTree(files: FileNode[]): TreeNode[] {
    const fileMap = new Map<number, TreeNode>();
    const rootNodes: TreeNode[] = [];

    files.forEach(file => {
      const treeNode: TreeNode = {
        id: file.id,
        name: file.name,
        type: file.isDirectory ? 'folder' : 'file',
        fileType: this.fileService.getFileType(file.name),
        fileData: file,
        isExpandable: file.isDirectory,
        children: file.isDirectory ? [] : undefined
      };
      
      fileMap.set(file.id, treeNode);
    });

    files.forEach(file => {
      const treeNode = fileMap.get(file.id);
      if (treeNode) {
        if (file.parentId === null) {
          rootNodes.push(treeNode);
        } else {
          const parentNode = fileMap.get(file.parentId);
          if (parentNode && parentNode.children) {
            parentNode.children.push(treeNode);
          }
        }
      }
    });

    return rootNodes;
  }

  onNodeClick(node: TreeNode): void {
    if (node.type === 'file' && node.fileData) {
      this.selectedNodeId.set(node.id);
      this.fileSelected.emit(node.fileData);
    }
  }

  getNodeIcon(node: TreeNode): string {
    if (node.type === 'category') {
      return 'category';
    } else if (node.type === 'course') {
      return 'school';
    } else if (node.type === 'folder') {
      return this.treeControl.isExpanded(node) ? 'folder_open' : 'folder';
    } else if (node.fileType) {
      return this.fileService.getFileIcon(node.fileType);
    }
    return 'insert_drive_file';
  }

  getNodeClass(node: TreeNode): string {
    const classes: string[] = [];
    
    if (node.type === 'file') {
      classes.push('file-node');
      if (this.selectedNodeId() === node.id) {
        classes.push('selected');
      }
    }
    
    if (node.fileType) {
      classes.push(`icon-${node.fileType}`);
    }
    
    return classes.join(' ');
  }
}
'@

$treeViewComponentHtml = @'
<div class="tree-container">
  @if (isLoading()) {
    <div class="loading-spinner">
      <mat-spinner diameter="40"></mat-spinner>
    </div>
  } @else {
    <mat-tree [dataSource]="dataSource" [treeControl]="treeControl" class="tree">
      <mat-tree-node *matTreeNodeDef="let node" 
                     matTreeNodeToggle
                     [class]="getNodeClass(node)"
                     (click)="onNodeClick(node)">
        <button mat-icon-button disabled></button>
        <mat-icon [class]="getNodeClass(node)">{{ getNodeIcon(node) }}</mat-icon>
        <span class="node-label">{{ node.name }}</span>
      </mat-tree-node>

      <mat-nested-tree-node *matTreeNodeDef="let node; when: hasChild">
        <div class="mat-tree-node" [class]="getNodeClass(node)">
          <button mat-icon-button 
                  matTreeNodeToggle
                  [attr.aria-label]="'Toggle ' + node.name"
                  (click)="toggleNode(node)">
            <mat-icon class="mat-icon-rtl-mirror">
              {{ treeControl.isExpanded(node) ? 'expand_more' : 'chevron_right' }}
            </mat-icon>
          </button>
          <mat-icon [class]="getNodeClass(node)">{{ getNodeIcon(node) }}</mat-icon>
          <span class="node-label">{{ node.name }}</span>
        </div>
        
        @if (treeControl.isExpanded(node)) {
          <div class="nested-nodes" [class.tree-invisible]="!treeControl.isExpanded(node)">
            <ng-container matTreeNodeOutlet></ng-container>
          </div>
        }
      </mat-nested-tree-node>
    </mat-tree>
  }
</div>
'@

$treeViewComponentScss = @'
.tree {
  padding: 8px;
}

.mat-tree-node {
  display: flex;
  align-items: center;
  padding: 4px 0;
  cursor: pointer;
  transition: background-color 0.2s;
}

.mat-tree-node:hover {
  background-color: #f5f5f5;
}

.file-node.selected {
  background-color: #e3f2fd !important;
  font-weight: 500;
}

.node-label {
  margin-left: 8px;
  user-select: none;
}

.nested-nodes {
  padding-left: 24px;
}

.tree-invisible {
  display: none;
}

mat-icon {
  font-size: 20px;
  width: 20px;
  height: 20px;
  vertical-align: middle;
}
'@

Create-File -Path (Join-Path $appPath "features\client\components\tree-view.component.ts") -Content $treeViewComponentTs
Create-File -Path (Join-Path $appPath "features\client\components\tree-view.component.html") -Content $treeViewComponentHtml
Create-File -Path (Join-Path $appPath "features\client\components\tree-view.component.scss") -Content $treeViewComponentScss

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "Client Components (Part 1) Generated!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "`nNext step: Run 8-generate-file-viewer.ps1" -ForegroundColor Yellow
