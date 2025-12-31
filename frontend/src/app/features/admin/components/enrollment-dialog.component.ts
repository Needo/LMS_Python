import { Component, Inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MAT_DIALOG_DATA, MatDialogRef, MatDialogModule } from '@angular/material/dialog';
import { MatTableModule } from '@angular/material/table';
import { MatCheckboxModule } from '@angular/material/checkbox';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatSnackBar } from '@angular/material/snack-bar';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { UserService, User, UserEnrollment } from '../../../core/services/user.service';
import { CourseService } from '../../../core/services/course.service';

interface Course {
  id: number;
  name: string;
  categoryId: number;
}

@Component({
  selector: 'app-enrollment-dialog',
  standalone: true,
  imports: [
    CommonModule,
    MatDialogModule,
    MatTableModule,
    MatCheckboxModule,
    MatButtonModule,
    MatIconModule,
    MatProgressSpinnerModule
  ],
  template: `
    <h2 mat-dialog-title>Manage Course Enrollments - {{ data.user.username }}</h2>
    <mat-dialog-content>
      @if (isLoading()) {
        <div class="loading"><mat-spinner diameter="40"></mat-spinner></div>
      } @else {
        <div class="courses-table">
          <table mat-table [dataSource]="allCoursesWithStatus()" class="full-width">
            
            <!-- Checkbox Column -->
            <ng-container matColumnDef="enrolled">
              <th mat-header-cell *matHeaderCellDef>Enrolled</th>
              <td mat-cell *matCellDef="let course">
                <mat-checkbox 
                  [checked]="course.enrolled"
                  (change)="toggleEnrollment(course, $event.checked)"
                  color="primary">
                </mat-checkbox>
              </td>
            </ng-container>

            <!-- Course Name Column -->
            <ng-container matColumnDef="name">
              <th mat-header-cell *matHeaderCellDef>Course Name</th>
              <td mat-cell *matCellDef="let course" class="course-name">
                <mat-icon class="course-icon">school</mat-icon>
                <span [title]="course.name">{{ course.name }}</span>
              </td>
            </ng-container>

            <tr mat-header-row *matHeaderRowDef="displayedColumns"></tr>
            <tr mat-row *matRowDef="let row; columns: displayedColumns;"></tr>
          </table>
        </div>
      }
    </mat-dialog-content>
    <mat-dialog-actions align="end">
      <button mat-button (click)="close()">Close</button>
    </mat-dialog-actions>
  `,
  styles: [`
    mat-dialog-content {
      min-width: 700px;
      max-width: 900px;
      max-height: 600px;
      padding: 20px;
      overflow-y: auto;
    }

    .courses-table {
      width: 100%;
      overflow-x: auto;
    }

    .full-width {
      width: 100%;
    }

    th.mat-header-cell {
      font-size: 14px;
      font-weight: 600;
      color: rgba(0,0,0,0.87);
      background: #f5f5f5;
    }

    td.mat-cell {
      padding: 12px 16px;
    }

    .course-name {
      display: flex;
      align-items: center;
      gap: 8px;
    }

    .course-name span {
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
      max-width: 550px;
    }

    .course-icon {
      color: #1976d2;
      font-size: 20px;
      width: 20px;
      height: 20px;
      flex-shrink: 0;
    }

    .loading {
      display: flex;
      justify-content: center;
      padding: 40px;
    }

    mat-checkbox {
      display: flex;
      justify-content: center;
    }

    tr.mat-row:hover {
      background: #f5f5f5;
    }
  `]
})
export class EnrollmentDialogComponent implements OnInit {
  enrollments = signal<UserEnrollment[]>([]);
  allCourses = signal<Course[]>([]);
  isLoading = signal(true);
  displayedColumns = ['enrolled', 'name'];

  constructor(
    public dialogRef: MatDialogRef<EnrollmentDialogComponent>,
    @Inject(MAT_DIALOG_DATA) public data: { user: User },
    private userService: UserService,
    private courseService: CourseService,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit(): void {
    this.loadData();
  }

  // Compute list of all courses with enrollment status
  allCoursesWithStatus(): Array<Course & { enrolled: boolean }> {
    const enrolledIds = new Set(this.enrollments().map(e => e.course_id));
    return this.allCourses().map(course => ({
      ...course,
      enrolled: enrolledIds.has(course.id)
    }));
  }

  loadData(): void {
    this.isLoading.set(true);

    // Load enrollments
    this.userService.getUserEnrollments(this.data.user.id).subscribe({
      next: (enrollments) => {
        this.enrollments.set(enrollments);
        this.loadCourses();
      },
      error: (error) => {
        console.error('Error loading enrollments:', error);
        this.snackBar.open('Failed to load enrollments', 'Close', { duration: 3000 });
        this.isLoading.set(false);
      }
    });
  }

  loadCourses(): void {
    // Load all courses
    this.courseService.getCourses().subscribe({
      next: (courses) => {
        this.allCourses.set(courses);
        this.isLoading.set(false);
      },
      error: (error) => {
        console.error('Error loading courses:', error);
        this.snackBar.open('Failed to load courses', 'Close', { duration: 3000 });
        this.isLoading.set(false);
      }
    });
  }

  toggleEnrollment(course: Course & { enrolled: boolean }, checked: boolean): void {
    if (checked) {
      // Enroll
      this.userService.enrollUserInCourse(this.data.user.id, course.id).subscribe({
        next: () => {
          this.snackBar.open(`Enrolled in ${course.name}`, 'Close', { duration: 2000 });
          this.loadData();
        },
        error: (error) => {
          console.error('Error enrolling:', error);
          this.snackBar.open(error.error?.detail || 'Failed to enroll', 'Close', { duration: 3000 });
          this.loadData(); // Reload to reset checkbox
        }
      });
    } else {
      // Unenroll
      this.userService.unenrollUserFromCourse(this.data.user.id, course.id).subscribe({
        next: () => {
          this.snackBar.open(`Unenrolled from ${course.name}`, 'Close', { duration: 2000 });
          this.loadData();
        },
        error: (error) => {
          console.error('Error unenrolling:', error);
          this.snackBar.open('Failed to unenroll', 'Close', { duration: 3000 });
          this.loadData(); // Reload to reset checkbox
        }
      });
    }
  }

  close(): void {
    this.dialogRef.close(true);
  }
}
