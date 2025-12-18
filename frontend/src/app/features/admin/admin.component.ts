import { Component, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { MatToolbarModule } from '@angular/material/toolbar';
import { MatButtonModule } from '@angular/material/button';
import { MatCardModule } from '@angular/material/card';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';
import { MatIconModule } from '@angular/material/icon';
import { AuthService } from '../../../core/services/auth.service';
import { ScannerService } from '../../../core/services/scanner.service';
import { ScanResult } from '../../../core/models/scan.model';

@Component({
  selector: 'app-admin',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    MatToolbarModule,
    MatButtonModule,
    MatCardModule,
    MatFormFieldModule,
    MatInputModule,
    MatProgressSpinnerModule,
    MatSnackBarModule,
    MatIconModule
  ],
  templateUrl: './admin.component.html',
  styleUrls: ['./admin.component.scss']
})
export class AdminComponent implements OnInit {
  rootPath = signal<string>('');
  isScanning = signal(false);
  scanResult = signal<ScanResult | null>(null);
  currentUser = this.authService.currentUser;

  constructor(
    private authService: AuthService,
    private scannerService: ScannerService,
    private router: Router,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit(): void {
    this.loadRootPath();
  }

  loadRootPath(): void {
    this.scannerService.getRootPath().subscribe({
      next: (response) => {
        this.rootPath.set(response.rootPath || '');
      },
      error: (error) => {
        console.error('Error loading root path:', error);
      }
    });
  }

  saveRootPath(): void {
    const path = this.rootPath();
    if (!path) {
      this.snackBar.open('Please enter a valid path', 'Close', { duration: 3000 });
      return;
    }

    this.scannerService.setRootPath(path).subscribe({
      next: () => {
        this.snackBar.open('Root path saved successfully', 'Close', { duration: 3000 });
      },
      error: (error) => {
        this.snackBar.open('Error saving root path', 'Close', { duration: 3000 });
        console.error('Error:', error);
      }
    });
  }

  scanFolder(): void {
    const path = this.rootPath();
    if (!path) {
      this.snackBar.open('Please enter and save a root path first', 'Close', { duration: 3000 });
      return;
    }

    this.isScanning.set(true);
    this.scanResult.set(null);

    this.scannerService.scanRootFolder({ rootPath: path }).subscribe({
      next: (result) => {
        this.isScanning.set(false);
        this.scanResult.set(result);
        if (result.success) {
          this.snackBar.open('Scan completed successfully!', 'Close', { duration: 3000 });
        } else {
          this.snackBar.open('Scan completed with errors', 'Close', { duration: 3000 });
        }
      },
      error: (error) => {
        this.isScanning.set(false);
        this.snackBar.open('Error during scan', 'Close', { duration: 3000 });
        console.error('Scan error:', error);
      }
    });
  }

  navigateToClient(): void {
    this.router.navigate(['/client']);
  }

  logout(): void {
    this.authService.logout();
    this.router.navigate(['/auth/login']);
  }
}
