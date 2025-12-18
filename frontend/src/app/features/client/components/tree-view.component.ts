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
