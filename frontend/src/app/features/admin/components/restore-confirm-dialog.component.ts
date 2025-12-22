import { Component, Inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MatDialogModule, MatDialogRef, MAT_DIALOG_DATA } from '@angular/material/dialog';
import { MatButtonModule } from '@angular/material/button';
import { MatCheckboxModule } from '@angular/material/checkbox';
import { Backup } from '../../../core/services/backup.service';

@Component({
  selector: 'app-restore-confirm-dialog',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    MatDialogModule,
    MatButtonModule,
    MatCheckboxModule
  ],
  template: `
    <h2 mat-dialog-title class="warning-title">⚠️ Restore Database</h2>
    <mat-dialog-content>
      <p class="warning-text">
        <strong>WARNING: This is a destructive operation!</strong>
      </p>
      <p>Restoring this backup will:</p>
      <ul>
        <li>Delete ALL current data in the database</li>
        <li>Replace it with data from: <strong>{{ data.backup.filename }}</strong></li>
        <li>Disconnect all active users</li>
        <li>Require everyone to log in again</li>
      </ul>
      <p class="final-warning">This action <strong>CANNOT BE UNDONE</strong>.</p>
      
      <mat-checkbox [(ngModel)]="confirmed" class="confirm-checkbox">
        I understand this will delete all current data
      </mat-checkbox>
    </mat-dialog-content>
    <mat-dialog-actions align="end">
      <button mat-button (click)="onCancel()">Cancel</button>
      <button mat-raised-button 
              color="warn" 
              [disabled]="!confirmed"
              (click)="onConfirm()">
        Restore Database
      </button>
    </mat-dialog-actions>
  `,
  styles: [`
    .warning-title {
      color: #f44336;
    }
    
    .warning-text {
      color: #f44336;
      font-size: 16px;
      font-weight: 500;
      margin-bottom: 16px;
    }
    
    ul {
      margin: 16px 0;
      padding-left: 24px;
    }
    
    li {
      margin: 8px 0;
    }
    
    .final-warning {
      color: #f44336;
      font-weight: 500;
      margin: 16px 0;
    }
    
    .confirm-checkbox {
      margin: 16px 0;
    }
    
    mat-dialog-content {
      min-width: 400px;
    }
  `]
})
export class RestoreConfirmDialogComponent {
  confirmed = false;
  
  constructor(
    public dialogRef: MatDialogRef<RestoreConfirmDialogComponent>,
    @Inject(MAT_DIALOG_DATA) public data: { backup: Backup }
  ) {}
  
  onCancel(): void {
    this.dialogRef.close(false);
  }
  
  onConfirm(): void {
    this.dialogRef.close(true);
  }
}
