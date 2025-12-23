import { Component, OnInit, signal, Output, EventEmitter, effect } from '@angular/core';
import { CommonModule } from '@angular/common';
import { CdkTreeModule } from '@angular/cdk/tree';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonModule } from '@angular/material/button';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { BehaviorSubject } from 'rxjs';
import { CategoryService } from '../../../core/services/category.service';
import { CourseService } from '../../../core/services/course.service';
import { FileService } from '../../../core/services/file.service';
import { FileNode, FileType } from '../../../core/models/file.model';
import { TreeStateService } from '../../../core/services/tree-state.service';

// TreeNode with BehaviorSubject for children (required for Angular 18+)
class TreeNode {
  // CRITICAL: children must be Observable for Angular Material tree
  children = new BehaviorSubject<TreeNode[]>([]);
  loading = signal(false);
  
  constructor(
    public id: number,
    public name: string,
    public type: 'category' | 'course' | 'file' | 'folder',
    public isExpandable: boolean,
    public fileType?: FileType,
    public fileData?: FileNode
  ) {}
}

@Component({
  selector: 'app-tree-view',
  standalone: true,
  imports: [
    CommonModule,
    CdkTreeModule,
    MatIconModule,
    MatButtonModule,
    MatProgressSpinnerModule
  ],
  templateUrl: './tree-view.component.html',
  styleUrls: ['./tree-view.component.scss']
})
export class TreeViewComponent implements OnInit {
  @Output() fileSelected = new EventEmitter<FileNode>();

  // No more TreeControl! Use childrenAccessor instead
  childrenAccessor = (node: TreeNode) => node.children.asObservable();
  
  // Root nodes as BehaviorSubject
  rootNodes = new BehaviorSubject<TreeNode[]>([]);
  
  isLoading = signal(false);
  selectedNodeId = signal<number | null>(null);

  constructor(
    private categoryService: CategoryService,
    private courseService: CourseService,
    private fileService: FileService,
    private treeState: TreeStateService
  ) {
    // Watch for refresh requests
    effect(() => {
      if (this.treeState.needsRefresh()) {
        this.refreshTree();
      }
    });
  }

  ngOnInit(): void {
    this.loadTree();
  }

  // Check if node has children (for expansion arrow)
  hasChild = (_: number, node: TreeNode) => node.isExpandable;

  // TrackBy function
  trackByNode = (index: number, node: TreeNode) => `${node.type}-${node.id}`;

  loadTree(): void {
    this.isLoading.set(true);
    
    this.categoryService.getCategories().subscribe({
      next: (categories) => {
        const treeData: TreeNode[] = categories.map(category => 
          new TreeNode(
            category.id,
            category.name,
            'category',
            true
          )
        );
        
        this.rootNodes.next(treeData);
        this.isLoading.set(false);
        
        // Restore expansion state after a short delay
        setTimeout(() => this.restoreExpansionState(), 100);
      },
      error: (error) => {
        console.error('Error loading categories:', error);
        this.isLoading.set(false);
      }
    });
  }

  // Handle expansion events from the tree
  handleNodeExpansion(isExpanding: boolean, node: TreeNode): void {
    // Update state service
    if (node.type !== 'file') {
      this.treeState.setExpanded(node.type, node.id, isExpanding);
    }
    
    if (isExpanding) {
      this.expandNode(node);
    }
  }

  private expandNode(node: TreeNode): void {
    // Check if already loading
    if (this.treeState.isLoading(node.type, node.id)) {
      return;
    }
    
    // Check if children already loaded
    if (this.treeState.areChildrenLoaded(node.type, node.id)) {
      return;
    }
    
    // Only load children if not already loaded
    if (node.children.value.length === 0 && !node.loading()) {
      if (node.type === 'category') {
        this.loadCoursesForCategory(node);
      } else if (node.type === 'course') {
        this.loadFilesForCourse(node);
      }
    }
  }

  private loadCoursesForCategory(categoryNode: TreeNode): void {
    categoryNode.loading.set(true);
    this.treeState.setLoading('category', categoryNode.id, true);
    
    this.courseService.getCoursesByCategory(categoryNode.id).subscribe({
      next: (courses) => {
        const childNodes: TreeNode[] = courses.map(course => 
          new TreeNode(
            course.id,
            course.name,
            'course',
            true
          )
        );

        // Update the BehaviorSubject - this triggers the tree to re-render
        categoryNode.children.next(childNodes);
        categoryNode.loading.set(false);
        this.treeState.setLoading('category', categoryNode.id, false);
        this.treeState.setChildrenLoaded('category', categoryNode.id);
      },
      error: (error) => {
        console.error('Error loading courses:', error);
        categoryNode.loading.set(false);
        this.treeState.setLoading('category', categoryNode.id, false);
      }
    });
  }

  private loadFilesForCourse(courseNode: TreeNode): void {
    courseNode.loading.set(true);
    this.treeState.setLoading('course', courseNode.id, true);
    
    this.fileService.getFilesByCourse(courseNode.id).subscribe({
      next: (files) => {
        const childNodes = this.buildFileTree(files);
        
        // Update the BehaviorSubject
        courseNode.children.next(childNodes);
        courseNode.loading.set(false);
        this.treeState.setLoading('course', courseNode.id, false);
        this.treeState.setChildrenLoaded('course', courseNode.id);
      },
      error: (error) => {
        console.error('Error loading files:', error);
        courseNode.loading.set(false);
        this.treeState.setLoading('course', courseNode.id, false);
      }
    });
  }

  private buildFileTree(files: FileNode[]): TreeNode[] {
    const fileMap = new Map<number, TreeNode>();
    const rootNodes: TreeNode[] = [];

    // First pass: Create all tree nodes
    files.forEach(file => {
      const treeNode = new TreeNode(
        file.id,
        file.name,
        file.isDirectory ? 'folder' : 'file',
        file.isDirectory,
        file.isDirectory ? undefined : this.fileService.getFileType(file.name),
        file.isDirectory ? undefined : file
      );
      
      fileMap.set(file.id, treeNode);
    });

    // Second pass: Build parent-child relationships
    files.forEach(file => {
      const treeNode = fileMap.get(file.id)!;
      
      if (file.parentId === null) {
        rootNodes.push(treeNode);
      } else {
        const parentNode = fileMap.get(file.parentId);
        if (parentNode) {
          // Add to parent's children BehaviorSubject
          const currentChildren = parentNode.children.value;
          parentNode.children.next([...currentChildren, treeNode]);
        } else {
          console.warn('Parent not found for:', file.name, 'parent_id:', file.parentId);
          rootNodes.push(treeNode);
        }
      }
    });

    return rootNodes;
  }

  onNodeClick(node: TreeNode): void {
    // Only handle file clicks (not folders)
    if (node.type === 'file' && node.fileData) {
      this.selectedNodeId.set(node.id);
      
      // Update state service
      this.treeState.selectNode({
        id: node.id,
        type: 'file',
        name: node.name
      });
      
      this.fileSelected.emit(node.fileData);
    }
  }

  getNodeIcon(node: TreeNode): string {
    if (node.type === 'category') {
      return 'category';
    } else if (node.type === 'course') {
      return 'school';
    } else if (node.type === 'folder') {
      return 'folder';
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
    
    // Add file type specific class
    if (node.fileType) {
      classes.push(`icon-${node.fileType}`);
    }
    
    // Add folder class for folders
    if (node.type === 'folder') {
      classes.push('icon-folder');
    }
    
    return classes.join(' ');
  }
  
  private refreshTree(): void {
    // Save current selection
    const currentSelection = this.selectedNodeId();
    
    // Clear children loaded flags
    this.treeState.clearChildrenLoadedFlags();
    
    // Reload tree
    this.loadTree();
    
    // Restore selection if still valid
    if (currentSelection) {
      this.selectedNodeId.set(currentSelection);
    }
    
    // Mark refresh as handled
    this.treeState.refreshHandled();
  }
  
  private restoreExpansionState(): void {
    // Get expanded node keys from state
    const expandedKeys = this.treeState.getExpandedNodeKeys();
    
    // For each expanded key, find the node and expand it
    expandedKeys.forEach(key => {
      const [type, idStr] = key.split('-');
      const id = parseInt(idStr);
      
      // Find node in tree and expand
      const node = this.findNodeById(type, id);
      if (node) {
        this.expandNode(node);
      }
    });
  }
  
  private findNodeById(type: string, id: number): TreeNode | null {
    // Search in root nodes
    const searchInNodes = (nodes: TreeNode[]): TreeNode | null => {
      for (const node of nodes) {
        if (node.type === type && node.id === id) {
          return node;
        }
        
        // Search in children
        const children = node.children.value;
        if (children.length > 0) {
          const found = searchInNodes(children);
          if (found) return found;
        }
      }
      return null;
    };
    
    return searchInNodes(this.rootNodes.value);
  }
}
