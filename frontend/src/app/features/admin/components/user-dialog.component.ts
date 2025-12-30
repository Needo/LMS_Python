import { Component, Inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MAT_DIALOG_DATA, MatDialogRef, MatDialogModule } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatCheckboxModule } from '@angular/material/checkbox';
import { MatSnackBar } from '@angular/material/snack-bar';
import { UserService, User, UserCreate, UserUpdate } from '../../../core/services/user.service';

@Component({
  selector: 'app-user-dialog',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    MatDialogModule,
    MatFormFieldModule,
    MatInputModule,
    MatButtonModule,
    MatCheckboxModule
  ],
  template: `
    <h2 mat-dialog-title>{{ data.mode === 'create' ? 'Create User' : 'Edit User' }}</h2>
    <mat-dialog-content>
      <mat-form-field appearance="outline" class="full-width">
        <mat-label>Username</mat-label>
        <input matInput [(ngModel)]="username" required>
      </mat-form-field>

      <mat-form-field appearance="outline" class="full-width">
        <mat-label>Email</mat-label>
        <input matInput type="email" [(ngModel)]="email">
      </mat-form-field>

      <mat-form-field appearance="outline" class="full-width">
        <mat-label>Password</mat-label>
        <input matInput type="password" [(ngModel)]="password" 
               [required]="data.mode === 'create'"
               [placeholder]="data.mode === 'edit' ? 'Leave blank to keep current' : ''">
      </mat-form-field>

      <mat-checkbox [(ngModel)]="isAdmin">Administrator</mat-checkbox>
    </mat-dialog-content>
    <mat-dialog-actions align="end">
      <button mat-button (click)="cancel()">Cancel</button>
      <button mat-raised-button color="primary" (click)="save()" [disabled]="isSaving()">
        {{ isSaving() ? 'Saving...' : 'Save' }}
      </button>
    </mat-dialog-actions>
  `,
  styles: [`
    h2[mat-dialog-title] {
      margin-bottom: 24px;
    }

    mat-dialog-content {
      display: flex;
      flex-direction: column;
      gap: 16px;
      min-width: 400px;
      min-height: 320px;
      padding: 24px 20px 20px 20px;
      overflow-y: auto;
    }

    .full-width {
      width: 100%;
    }

    mat-dialog-actions {
      padding: 16px 24px;
      margin: 0;
    }
  `]
})
export class UserDialogComponent {
  username = '';
  email = '';
  password = '';
  isAdmin = false;
  isSaving = signal(false);

  constructor(
    public dialogRef: MatDialogRef<UserDialogComponent>,
    @Inject(MAT_DIALOG_DATA) public data: { mode: 'create' | 'edit', user?: User },
    private userService: UserService,
    private snackBar: MatSnackBar
  ) {
    if (data.mode === 'edit' && data.user) {
      this.username = data.user.username;
      this.email = data.user.email || '';
      this.isAdmin = data.user.isAdmin;
    }
  }

  save(): void {
    if (!this.username) {
      this.snackBar.open('Username is required', 'Close', { duration: 3000 });
      return;
    }

    if (this.data.mode === 'create' && !this.password) {
      this.snackBar.open('Password is required', 'Close', { duration: 3000 });
      return;
    }

    this.isSaving.set(true);

    if (this.data.mode === 'create') {
      const userData: UserCreate = {
        username: this.username,
        email: this.email || undefined,
        password: this.password,
        isAdmin: this.isAdmin
      };

      this.userService.createUser(userData).subscribe({
        next: () => {
          this.snackBar.open('User created successfully', 'Close', { duration: 3000 });
          this.dialogRef.close(true);
        },
        error: (error) => {
          console.error('Error creating user:', error);
          this.snackBar.open(error.error?.detail || 'Failed to create user', 'Close', { duration: 3000 });
          this.isSaving.set(false);
        }
      });
    } else {
      const userData: UserUpdate = {
        username: this.username,
        email: this.email || undefined,
        isAdmin: this.isAdmin
      };

      if (this.password) {
        userData.password = this.password;
      }

      this.userService.updateUser(this.data.user!.id, userData).subscribe({
        next: () => {
          this.snackBar.open('User updated successfully', 'Close', { duration: 3000 });
          this.dialogRef.close(true);
        },
        error: (error) => {
          console.error('Error updating user:', error);
          this.snackBar.open(error.error?.detail || 'Failed to update user', 'Close', { duration: 3000 });
          this.isSaving.set(false);
        }
      });
    }
  }

  cancel(): void {
    this.dialogRef.close(false);
  }
}
