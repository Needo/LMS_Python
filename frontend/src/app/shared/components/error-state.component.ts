import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatCardModule } from '@angular/material/card';

@Component({
  selector: 'app-error-state',
  standalone: true,
  imports: [CommonModule, MatButtonModule, MatIconModule, MatCardModule],
  template: `
    <div class="error-state" [class.full-page]="fullPage" role="alert" aria-live="assertive">
      <mat-card class="error-card">
        <mat-card-content>
          <div class="error-icon">
            <mat-icon [color]="severity === 'error' ? 'warn' : 'primary'">
              {{ getIcon() }}
            </mat-icon>
          </div>
          
          <h2 class="error-title">{{ title }}</h2>
          
          <p class="error-message">{{ message }}</p>
          
          <div class="error-actions">
            <button 
              mat-raised-button 
              color="primary" 
              *ngIf="showRetry"
              (click)="onRetry()"
              [attr.aria-label]="'Retry ' + title">
              <mat-icon>refresh</mat-icon>
              Try Again
            </button>
            
            <button 
              mat-button 
              *ngIf="showGoBack"
              (click)="onGoBack()"
              aria-label="Go back">
              <mat-icon>arrow_back</mat-icon>
              Go Back
            </button>
          </div>
          
          <details class="error-details" *ngIf="details">
            <summary>Technical Details</summary>
            <pre>{{ details }}</pre>
          </details>
        </mat-card-content>
      </mat-card>
    </div>
  `,
  styles: [`
    .error-state {
      display: flex;
      justify-content: center;
      align-items: center;
      padding: 24px;
      min-height: 300px;
    }

    .error-state.full-page {
      min-height: 100vh;
      background: #f5f5f5;
    }

    .error-card {
      max-width: 600px;
      width: 100%;
      text-align: center;
    }

    .error-icon {
      margin: 24px auto;
    }

    .error-icon mat-icon {
      font-size: 64px;
      width: 64px;
      height: 64px;
    }

    .error-title {
      margin: 16px 0;
      font-size: 24px;
      font-weight: 500;
      color: rgba(0, 0, 0, 0.87);
    }

    .error-message {
      margin: 16px 0;
      font-size: 16px;
      color: rgba(0, 0, 0, 0.6);
      line-height: 1.5;
    }

    .error-actions {
      margin: 24px 0;
      display: flex;
      gap: 12px;
      justify-content: center;
    }

    .error-details {
      margin-top: 24px;
      text-align: left;
      border-top: 1px solid #e0e0e0;
      padding-top: 16px;
    }

    .error-details summary {
      cursor: pointer;
      color: rgba(0, 0, 0, 0.6);
      font-size: 14px;
      user-select: none;
    }

    .error-details summary:hover {
      color: rgba(0, 0, 0, 0.87);
    }

    .error-details pre {
      margin-top: 12px;
      padding: 12px;
      background: #f5f5f5;
      border-radius: 4px;
      overflow-x: auto;
      font-size: 12px;
      color: #d32f2f;
    }

    /* Responsive */
    @media (max-width: 600px) {
      .error-state {
        padding: 16px;
      }

      .error-icon mat-icon {
        font-size: 48px;
        width: 48px;
        height: 48px;
      }

      .error-title {
        font-size: 20px;
      }

      .error-actions {
        flex-direction: column;
      }

      .error-actions button {
        width: 100%;
      }
    }
  `]
})
export class ErrorStateComponent {
  @Input() title = 'Something went wrong';
  @Input() message = 'An unexpected error occurred. Please try again.';
  @Input() severity: 'error' | 'warning' | 'info' = 'error';
  @Input() details?: string;
  @Input() showRetry = true;
  @Input() showGoBack = false;
  @Input() fullPage = false;
  @Input() onRetryFn?: () => void;
  @Input() onGoBackFn?: () => void;

  getIcon(): string {
    switch (this.severity) {
      case 'error':
        return 'error_outline';
      case 'warning':
        return 'warning';
      case 'info':
        return 'info';
      default:
        return 'error_outline';
    }
  }

  onRetry(): void {
    if (this.onRetryFn) {
      this.onRetryFn();
    } else {
      window.location.reload();
    }
  }

  onGoBack(): void {
    if (this.onGoBackFn) {
      this.onGoBackFn();
    } else {
      window.history.back();
    }
  }
}
