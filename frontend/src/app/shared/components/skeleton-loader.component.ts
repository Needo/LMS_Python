import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-skeleton-loader',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="skeleton-loader" [class]="type" [attr.aria-label]="'Loading ' + type">
      <div class="skeleton-item" *ngIf="type === 'text'"></div>
      <div class="skeleton-item" *ngIf="type === 'title'"></div>
      <div class="skeleton-card" *ngIf="type === 'card'">
        <div class="skeleton-image"></div>
        <div class="skeleton-content">
          <div class="skeleton-title"></div>
          <div class="skeleton-text"></div>
          <div class="skeleton-text"></div>
        </div>
      </div>
      <div class="skeleton-tree" *ngIf="type === 'tree'">
        <div class="skeleton-tree-item" *ngFor="let item of [1,2,3,4,5]">
          <div class="skeleton-icon"></div>
          <div class="skeleton-text"></div>
        </div>
      </div>
      <div class="skeleton-list" *ngIf="type === 'list'">
        <div class="skeleton-list-item" *ngFor="let item of [1,2,3]">
          <div class="skeleton-avatar"></div>
          <div class="skeleton-content">
            <div class="skeleton-text"></div>
            <div class="skeleton-text short"></div>
          </div>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .skeleton-loader {
      animation: pulse 1.5s ease-in-out infinite;
    }

    @keyframes pulse {
      0%, 100% {
        opacity: 1;
      }
      50% {
        opacity: 0.5;
      }
    }

    .skeleton-item,
    .skeleton-title,
    .skeleton-text,
    .skeleton-image,
    .skeleton-icon,
    .skeleton-avatar {
      background: linear-gradient(90deg, #f0f0f0 25%, #e0e0e0 50%, #f0f0f0 75%);
      background-size: 200% 100%;
      animation: shimmer 1.5s infinite;
      border-radius: 4px;
    }

    @keyframes shimmer {
      0% {
        background-position: 200% 0;
      }
      100% {
        background-position: -200% 0;
      }
    }

    /* Text skeleton */
    .skeleton-item {
      height: 16px;
      margin: 8px 0;
    }

    /* Title skeleton */
    .skeleton-title {
      height: 24px;
      width: 60%;
      margin: 12px 0;
    }

    /* Card skeleton */
    .skeleton-card {
      border: 1px solid #e0e0e0;
      border-radius: 8px;
      padding: 16px;
      margin: 16px 0;
    }

    .skeleton-image {
      height: 200px;
      margin-bottom: 16px;
    }

    .skeleton-card .skeleton-title {
      height: 20px;
      width: 70%;
      margin-bottom: 12px;
    }

    .skeleton-card .skeleton-text {
      height: 14px;
      margin: 8px 0;
    }

    .skeleton-card .skeleton-text:last-child {
      width: 80%;
    }

    /* Tree skeleton */
    .skeleton-tree-item {
      display: flex;
      align-items: center;
      margin: 8px 0;
      padding: 8px;
    }

    .skeleton-icon {
      width: 24px;
      height: 24px;
      margin-right: 12px;
      flex-shrink: 0;
    }

    .skeleton-tree-item .skeleton-text {
      height: 16px;
      flex: 1;
    }

    /* List skeleton */
    .skeleton-list-item {
      display: flex;
      align-items: center;
      padding: 16px;
      border-bottom: 1px solid #e0e0e0;
    }

    .skeleton-avatar {
      width: 48px;
      height: 48px;
      border-radius: 50%;
      margin-right: 16px;
      flex-shrink: 0;
    }

    .skeleton-list-item .skeleton-content {
      flex: 1;
    }

    .skeleton-list-item .skeleton-text {
      height: 14px;
      margin: 4px 0;
    }

    .skeleton-list-item .skeleton-text.short {
      width: 60%;
    }
  `]
})
export class SkeletonLoaderComponent {
  @Input() type: 'text' | 'title' | 'card' | 'tree' | 'list' = 'text';
}
