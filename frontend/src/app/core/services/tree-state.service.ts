import { Injectable, signal, effect } from '@angular/core';

export interface TreeNodeState {
  id: number;
  type: 'category' | 'course' | 'folder';
  isExpanded: boolean;
  childrenLoaded: boolean;
}

export interface SelectedNode {
  id: number;
  type: 'category' | 'course' | 'file' | 'folder';
  name: string;
}

@Injectable({
  providedIn: 'root'
})
export class TreeStateService {
  // Expanded nodes: Map<"type-id", TreeNodeState>
  private expandedNodesMap = signal<Map<string, TreeNodeState>>(new Map());
  
  // Selected node
  private _selectedNode = signal<SelectedNode | null>(null);
  selectedNode = this._selectedNode.asReadonly();
  
  // Loading states per node
  private loadingNodes = signal<Set<string>>(new Set());
  
  // Track if tree needs refresh
  private _needsRefresh = signal(false);
  needsRefresh = this._needsRefresh.asReadonly();
  
  // Track pending node expansions (for search navigation)
  private _pendingExpansions = signal<{ categoryId: number; courseId?: number; folderId?: number } | null>(null);
  pendingExpansions = this._pendingExpansions.asReadonly();
  
  constructor() {
    // Load from sessionStorage on init
    this.loadFromStorage();
  }
  
  /**
   * Get unique key for node
   */
  private getNodeKey(type: string, id: number): string {
    return `${type}-${id}`;
  }
  
  /**
   * Check if node is expanded
   */
  isExpanded(type: string, id: number): boolean {
    const key = this.getNodeKey(type, id);
    return this.expandedNodesMap().get(key)?.isExpanded ?? false;
  }
  
  /**
   * Check if node's children are loaded
   */
  areChildrenLoaded(type: string, id: number): boolean {
    const key = this.getNodeKey(type, id);
    return this.expandedNodesMap().get(key)?.childrenLoaded ?? false;
  }
  
  /**
   * Set node expanded state
   */
  setExpanded(type: 'category' | 'course' | 'folder', id: number, expanded: boolean): void {
    const key = this.getNodeKey(type, id);
    const currentMap = new Map(this.expandedNodesMap());
    
    if (expanded) {
      const existing = currentMap.get(key);
      currentMap.set(key, {
        id,
        type,
        isExpanded: true,
        childrenLoaded: existing?.childrenLoaded ?? false
      });
    } else {
      const existing = currentMap.get(key);
      if (existing) {
        currentMap.set(key, { ...existing, isExpanded: false });
      }
    }
    
    this.expandedNodesMap.set(currentMap);
    this.saveToStorage();
  }
  
  /**
   * Mark node's children as loaded
   */
  setChildrenLoaded(type: 'category' | 'course' | 'folder', id: number): void {
    const key = this.getNodeKey(type, id);
    const currentMap = new Map(this.expandedNodesMap());
    const existing = currentMap.get(key);
    
    currentMap.set(key, {
      id,
      type,
      isExpanded: existing?.isExpanded ?? true,
      childrenLoaded: true
    });
    
    this.expandedNodesMap.set(currentMap);
  }
  
  /**
   * Check if node is currently loading
   */
  isLoading(type: string, id: number): boolean {
    const key = this.getNodeKey(type, id);
    return this.loadingNodes().has(key);
  }
  
  /**
   * Set loading state for node
   */
  setLoading(type: string, id: number, loading: boolean): void {
    const key = this.getNodeKey(type, id);
    const current = new Set(this.loadingNodes());
    
    if (loading) {
      current.add(key);
    } else {
      current.delete(key);
    }
    
    this.loadingNodes.set(current);
  }
  
  /**
   * Set selected node
   */
  selectNode(node: SelectedNode | null): void {
    this._selectedNode.set(node);
  }
  
  /**
   * Get selected node ID
   */
  getSelectedNodeId(): number | null {
    return this._selectedNode()?.id ?? null;
  }
  
  /**
   * Clear all expanded nodes (e.g., on logout)
   */
  clearExpansionState(): void {
    this.expandedNodesMap.set(new Map());
    this.saveToStorage();
  }
  
  /**
   * Request tree refresh (after scan completes)
   */
  requestRefresh(): void {
    this._needsRefresh.set(true);
  }
  
  /**
   * Mark refresh as handled
   */
  refreshHandled(): void {
    this._needsRefresh.set(false);
  }
  
  /**
   * Get all expanded node keys (for restoration after refresh)
   */
  getExpandedNodeKeys(): string[] {
    const map = this.expandedNodesMap();
    return Array.from(map.entries())
      .filter(([_, state]) => state.isExpanded)
      .map(([key, _]) => key);
  }
  
  /**
   * Clear children loaded flags (for refresh)
   */
  clearChildrenLoadedFlags(): void {
    const currentMap = new Map(this.expandedNodesMap());
    
    currentMap.forEach((state, key) => {
      currentMap.set(key, { ...state, childrenLoaded: false });
    });
    
    this.expandedNodesMap.set(currentMap);
  }
  
  /**
   * Save to sessionStorage (persists across navigation, cleared on tab close)
   */
  private saveToStorage(): void {
    try {
      const map = this.expandedNodesMap();
      const data = Array.from(map.entries());
      sessionStorage.setItem('tree-expanded-nodes', JSON.stringify(data));
    } catch (error) {
      console.error('Failed to save tree state:', error);
    }
  }
  
  /**
   * Load from sessionStorage
   */
  private loadFromStorage(): void {
    try {
      const data = sessionStorage.getItem('tree-expanded-nodes');
      if (data) {
        const entries: [string, TreeNodeState][] = JSON.parse(data);
        this.expandedNodesMap.set(new Map(entries));
      }
    } catch (error) {
      console.error('Failed to load tree state:', error);
    }
  }
  
  /**
   * Expand path to node (for search navigation)
   */
  expandToNode(categoryId: number, courseId?: number, folderId?: number): void {
    // Set pending expansions
    this._pendingExpansions.set({ categoryId, courseId, folderId });
    
    // Also set expanded state
    this.setExpanded('category', categoryId, true);
    if (courseId) {
      this.setExpanded('course', courseId, true);
    }
    if (folderId) {
      this.setExpanded('folder', folderId, true);
    }
  }
  
  /**
   * Clear pending expansions
   */
  clearPendingExpansions(): void {
    this._pendingExpansions.set(null);
  }
}
