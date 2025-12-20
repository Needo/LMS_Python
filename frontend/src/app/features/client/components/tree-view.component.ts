import { Component, OnInit, signal, Output, EventEmitter, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatTreeModule, MatTreeNestedDataSource } from '@angular/material/tree';
import { NestedTreeControl } from '@angular/cdk/tree';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonModule } from '@angular/material/button';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { CategoryService } from '../../../core/services/category.service';
import { CourseService } from '../../../core/services/course.service';
import { FileService } from '../../../core/services/file.service';
import { Category } from '../../../core/models/category.model';
import { Course } from '../../../core/models/course.model';
import { FileNode, FileType } from '../../../core/models/file.model';

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
    private fileService: FileService,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.loadTree();
  }

  // Check if node has children (for expansion arrow)
  hasChild = (_: number, node: TreeNode) => node.isExpandable;
  
  // Check if node is a leaf (actual file, not folder)
  isLeafNode = (_: number, node: TreeNode) => !node.isExpandable;

  // CRITICAL: TrackBy function to maintain node identity
  trackByNode = (index: number, node: TreeNode) => `${node.type}-${node.id}`;

  loadTree(): void {
    this.isLoading.set(true);
    
    this.categoryService.getCategories().subscribe({
      next: (categories) => {
        const treeData: TreeNode[] = categories.map(category => ({
          id: category.id,
          name: category.name,
          type: 'category',
          isExpandable: true,
          children: [] // Always empty array, not undefined
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

  // Called when toggle button is clicked
  loadChildrenIfNeeded(node: TreeNode): void {
    const wasExpanded = this.treeControl.isExpanded(node);
    console.log('loadChildrenIfNeeded:', node.name, 'wasExpanded:', wasExpanded);
    
    // If clicking to expand AND no children loaded yet
    if (wasExpanded && (!node.children || node.children.length === 0)) {
      console.log('Loading children for:', node.name, node.type);
      
      if (node.type === 'category') {
        this.loadCoursesForCategory(node);
      } else if (node.type === 'course') {
        this.loadFilesForCourse(node);
      }
    }
  }

  loadCoursesForCategory(categoryNode: TreeNode): void {
    console.log('Loading courses for category:', categoryNode.id);
    
    this.courseService.getCoursesByCategory(categoryNode.id).subscribe({
      next: (courses) => {
        console.log('Courses loaded:', courses.length);
        
        const newChildren: TreeNode[] = courses.map(course => ({
          id: course.id,
          name: course.name,
          type: 'course',
          isExpandable: true,
          children: []
        }));

        // Mutate the existing node
        categoryNode.children = newChildren;
        
        console.log('Category node now has', categoryNode.children.length, 'children');
        
        // Collapse then expand to force re-render
        this.treeControl.collapse(categoryNode);
        this.treeControl.expand(categoryNode);
        
        console.log('Node re-expanded, is expanded?', this.treeControl.isExpanded(categoryNode));
      },
      error: (error) => {
        console.error('Error loading courses:', error);
      }
    });
  }

  loadFilesForCourse(courseNode: TreeNode): void {
    console.log('Loading files for course:', courseNode.id);
    
    this.fileService.getFilesByCourse(courseNode.id).subscribe({
      next: (files) => {
        console.log('Files loaded:', files.length);
        
        const newChildren = this.buildFileTree(files);
        console.log('Built tree with', newChildren.length, 'root nodes');
        
        // Mutate the existing node
        courseNode.children = newChildren;
        
        console.log('Course node now has', courseNode.children.length, 'children');
        
        // Collapse then expand to force re-render
        this.treeControl.collapse(courseNode);
        this.treeControl.expand(courseNode);
        
        console.log('Node re-expanded, is expanded?', this.treeControl.isExpanded(courseNode));
      },
      error: (error) => {
        console.error('Error loading files:', error);
      }
    });
  }

  buildFileTree(files: FileNode[]): TreeNode[] {
    console.log('Building file tree from', files.length, 'files');
    
    const fileMap = new Map<number, TreeNode>();
    const rootNodes: TreeNode[] = [];

    // First pass: Create all tree nodes
    files.forEach(file => {
      const treeNode: TreeNode = {
        id: file.id,
        name: file.name,
        type: file.isDirectory ? 'folder' : 'file',
        fileType: file.isDirectory ? undefined : this.fileService.getFileType(file.name),
        fileData: file.isDirectory ? undefined : file,
        isExpandable: file.isDirectory,
        children: file.isDirectory ? [] : undefined
      };
      
      fileMap.set(file.id, treeNode);
    });

    // Second pass: Build parent-child relationships
    files.forEach(file => {
      const treeNode = fileMap.get(file.id)!;
      
      if (file.parentId === null) {
        // Root level file/folder
        rootNodes.push(treeNode);
      } else {
        // Child file/folder
        const parentNode = fileMap.get(file.parentId);
        if (parentNode?.children) {
          parentNode.children.push(treeNode);
        } else {
          console.warn('Parent not found for:', file.name, 'parent_id:', file.parentId);
          // Add to root as fallback
          rootNodes.push(treeNode);
        }
      }
    });

    console.log('File tree built:', rootNodes.length, 'root nodes');
    return rootNodes;
  }

  onNodeClick(node: TreeNode): void {
    // Only handle file clicks (not folders)
    if (node.type === 'file' && node.fileData) {
      console.log('File clicked:', node.name);
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
