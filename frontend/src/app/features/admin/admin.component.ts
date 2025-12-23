import { Component, signal, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { MatToolbarModule } from '@angular/material/toolbar';
import { MatButtonModule } from '@angular/material/button';
import { MatCardModule } from '@angular/material/card';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';
import { MatIconModule } from '@angular/material/icon';
import { MatDialog, MatDialogModule } from '@angular/material/dialog';
import { MatBadgeModule } from '@angular/material/badge';
import { AuthService } from '../../core/services/auth.service';
import { ScannerService, ScanStatusResponse } from '../../core/services/scanner.service';
import { BackupService, Backup, BackupStatus } from '../../core/services/backup.service';
import { ConfigService } from '../../core/services/config.service';
import { ScanResult, ScanStatus } from '../../core/models/scan.model';
import { RestoreConfirmDialogComponent } from './components/restore-confirm-dialog.component';
import { FileSizePipe } from '../../shared/pipes/file-size.pipe';

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
    MatProgressBarModule,
    MatSnackBarModule,
    MatIconModule,
    MatDialogModule,
    MatBadgeModule,
    FileSizePipe
  ],
  templateUrl: './admin.component.html',
  styleUrls: ['./admin.component.scss']
})
export class AdminComponent implements OnInit, OnDestroy {
  rootPath = signal<string>('');
  isScanning = signal(false);
  scanResult = signal<ScanResult | null>(null);
  scanStatus = signal<ScanStatusResponse | null>(null);
  currentUser: any;
  
  private statusPollInterval: any;
  readonly ScanStatus = ScanStatus;

  // Backup-related signals
  backups = signal<Backup[]>([]);
  isBackupInProgress = signal(false);
  isRestoreInProgress = signal(false);
  backupStatus = signal<BackupStatus | null>(null);
  
  // Path validation signals
  isValidatingPath = signal(false);
  pathValidation = signal<any>(null);

  constructor(
    private authService: AuthService,
    private scannerService: ScannerService,
    private backupService: BackupService,
    private configService: ConfigService,
    private router: Router,
    private snackBar: MatSnackBar,
    private dialog: MatDialog
  ) {}

  ngOnInit(): void {
    this.currentUser = this.authService.currentUser;
    this.loadRootPath();
    this.loadBackups();
    this.checkBackupStatus();
    this.loadConfig();
    this.loadScanStatus();
    
    // Start polling scan status
    this.startStatusPolling();
  }
  
  ngOnDestroy(): void {
    // Stop polling when component is destroyed
    if (this.statusPollInterval) {
      clearInterval(this.statusPollInterval);
    }
  }

  loadConfig(): void {
    this.configService.loadConfig().subscribe({
      next: () => {
        console.log('Configuration loaded');
      },
      error: (error) => {
        console.error('Error loading config:', error);
      }
    });
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

    // Validate path first
    this.isValidatingPath.set(true);
    this.configService.validateRootPath(path).subscribe({
      next: (validation) => {
        this.isValidatingPath.set(false);
        this.pathValidation.set(validation);

        if (!validation.valid) {
          this.snackBar.open(
            `Invalid path: ${validation.error}`,
            'Close',
            { duration: 5000 }
          );
          return;
        }

        // Path is valid, proceed to save
        this.scannerService.setRootPath(validation.path || path).subscribe({
          next: () => {
            this.snackBar.open('Root path saved successfully', 'Close', { duration: 3000 });
            this.rootPath.set(validation.path || path);
          },
          error: (error) => {
            this.snackBar.open('Error saving root path', 'Close', { duration: 3000 });
            console.error('Error:', error);
          }
        });
      },
      error: (error) => {
        this.isValidatingPath.set(false);
        this.snackBar.open('Error validating path', 'Close', { duration: 3000 });
        console.error('Validation error:', error);
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
          if (result.status === ScanStatus.PARTIAL) {
            this.snackBar.open(`Scan completed with ${result.errorsCount} errors`, 'Close', { duration: 5000 });
          } else {
            this.snackBar.open('Scan completed successfully!', 'Close', { duration: 3000 });
          }
        } else {
          this.snackBar.open('Scan failed', 'Close', { duration: 3000 });
        }
        
        // Reload scan status
        this.loadScanStatus();
      },
      error: (error) => {
        this.isScanning.set(false);
        this.snackBar.open('Error during scan', 'Close', { duration: 3000 });
        console.error('Scan error:', error);
      }
    });
  }
  
  loadScanStatus(): void {
    this.scannerService.getScanStatus().subscribe({
      next: (status) => {
        this.scanStatus.set(status);
        this.isScanning.set(status.is_scanning);
      },
      error: (error) => {
        console.error('Error loading scan status:', error);
      }
    });
  }
  
  startStatusPolling(): void {
    // Poll every 5 seconds if scan is running
    this.statusPollInterval = setInterval(() => {
      if (this.isScanning()) {
        this.loadScanStatus();
      }
    }, 5000);
  }

  navigateToClient(): void {
    this.router.navigate(['/client']);
  }

  logout(): void {
    this.authService.logout();
    this.router.navigate(['/auth/login']);
  }

  // Backup/Restore Methods
  loadBackups(): void {
    this.backupService.listBackups().subscribe({
      next: (response) => this.backups.set(response.backups),
      error: (error) => {
        console.error('Error loading backups:', error);
        this.snackBar.open('Error loading backups', 'Close', { duration: 3000 });
      }
    });
  }

  createBackup(): void {
    this.isBackupInProgress.set(true);
    this.backupService.createBackup().subscribe({
      next: (backup) => {
        this.isBackupInProgress.set(false);
        this.snackBar.open('Backup created successfully!', 'Close', { duration: 3000 });
        this.loadBackups();
      },
      error: (error) => {
        this.isBackupInProgress.set(false);
        this.snackBar.open('Error creating backup', 'Close', { duration: 3000 });
        console.error('Backup error:', error);
      }
    });
  }

  downloadBackup(backup: Backup): void {
    this.backupService.downloadBackup(backup.id).subscribe({
      next: (blob) => {
        const url = window.URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = backup.filename;
        link.click();
        window.URL.revokeObjectURL(url);
        this.snackBar.open('Backup downloaded', 'Close', { duration: 3000 });
      },
      error: (error) => {
        this.snackBar.open('Error downloading backup', 'Close', { duration: 3000 });
        console.error('Download error:', error);
      }
    });
  }

  restoreBackup(backup: Backup): void {
    const dialogRef = this.dialog.open(RestoreConfirmDialogComponent, {
      width: '500px',
      data: { backup }
    });

    dialogRef.afterClosed().subscribe(confirmed => {
      if (confirmed) {
        this.isRestoreInProgress.set(true);
        this.backupService.restoreBackup(backup.id, true).subscribe({
          next: () => {
            this.isRestoreInProgress.set(false);
            this.snackBar.open('Database restored successfully! Please log in again.', 'Close', { duration: 5000 });
            // Logout and redirect to login
            setTimeout(() => {
              this.authService.logout();
              this.router.navigate(['/auth/login']);
            }, 2000);
          },
          error: (error) => {
            this.isRestoreInProgress.set(false);
            this.snackBar.open('Error restoring database', 'Close', { duration: 3000 });
            console.error('Restore error:', error);
          }
        });
      }
    });
  }

  deleteBackup(backup: Backup): void {
    if (confirm(`Are you sure you want to delete backup: ${backup.filename}?`)) {
      this.backupService.deleteBackup(backup.id).subscribe({
        next: () => {
          this.snackBar.open('Backup deleted', 'Close', { duration: 3000 });
          this.loadBackups();
        },
        error: (error) => {
          this.snackBar.open('Error deleting backup', 'Close', { duration: 3000 });
          console.error('Delete error:', error);
        }
      });
    }
  }

  checkBackupStatus(): void {
    this.backupService.getStatus().subscribe({
      next: (status) => {
        this.backupStatus.set(status);
        if (status.is_locked) {
          // Poll again in 5 seconds if locked
          setTimeout(() => this.checkBackupStatus(), 5000);
        }
      },
      error: (error) => {
        console.error('Error checking backup status:', error);
      }
    });
  }
}
