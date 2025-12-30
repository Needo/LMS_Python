import { Component, Inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MAT_DIALOG_DATA, MatDialogRef, MatDialogModule } from '@angular/material/dialog';
import { MatListModule } from '@angular/material/list';
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
    MatListModule,
    MatButtonModule,
    MatIconModule,
    MatProgressSpinnerModule
  ],
  template: `
    <h2 mat-dialog-title>Manage Enrollments - {{ data.user.username }}</h2>
    <mat-dialog-content>
      <div class="section">
        <h3>Enrolled Courses</h3>
        @if (isLoading()) {
          <div class="loading"><mat-spinner diameter="40"></mat-spinner></div>
        } @else if (enrollments().length === 0) {
          <p class="empty">No enrollments</p>
        } @else {
          <mat-list>
            @for (enrollment of enrollments(); track enrollment.id) {
              <mat-list-item>
                <mat-icon matListItemIcon>school</mat-icon>
                <span matListItemTitle>{{ enrollment.course_name }}</span>
                <button mat-icon-button color="warn" (click)="unenroll(enrollment)">
                  <mat-icon>delete</mat-icon>
                </button>
              </mat-list-item>
            }
          </mat-list>
        }
      </div>

      <div class="section">
        <h3>Available Courses</h3>
        @if (availableCourses().length === 0) {
          <p class="empty">All courses enrolled</p>
        } @else {
          <mat-list>
            @for (course of availableCourses(); track course.id) {
              <mat-list-item>
                <mat-icon matListItemIcon>add_circle</mat-icon>
                <span matListItemTitle>{{ course.name }}</span>
                <button mat-icon-button color="primary" (click)="enroll(course)">
                  <mat-icon>add</mat-icon>
                </button>
              </mat-list-item>
            }
          </mat-list>
        }
      </div>
    </mat-dialog-content>
    <mat-dialog-actions align="end">
      <button mat-button (click)="close()">Close</button>
    </mat-dialog-actions>
  `,
  styles: [`
    mat-dialog-content {
      min-width: 500px;
      max-height: 600px;
      padding: 20px;
    }

    .section {
      margin-bottom: 24px;
    }

    .section h3 {
      margin: 0 0 12px 0;
      font-size: 16px;
      font-weight: 500;
      color: rgba(0,0,0,0.87);
    }

    .empty {
      color: rgba(0,0,0,0.6);
      font-style: italic;
      margin: 12px 0;
    }

    .loading {
      display: flex;
      justify-content: center;
      padding: 20px;
    }

    mat-list-item {
      border-bottom: 1px solid #e0e0e0;
    }
  `]
})
export class EnrollmentDialogComponent implements OnInit {
  enrollments = signal<UserEnrollment[]>([]);
  allCourses = signal<Course[]>([]);
  isLoading = signal(true);

  availableCourses = signal<Course[]>([]);

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
        this.updateAvailableCourses();
        this.isLoading.set(false);
      },
      error: (error) => {
        console.error('Error loading courses:', error);
        this.snackBar.open('Failed to load courses', 'Close', { duration: 3000 });
        this.isLoading.set(false);
      }
    });
  }

  updateAvailableCourses(): void {
    const enrolledIds = this.enrollments().map(e => e.course_id);
    const available = this.allCourses().filter(c => !enrolledIds.includes(c.id));
    this.availableCourses.set(available);
  }

  enroll(course: Course): void {
    this.userService.enrollUserInCourse(this.data.user.id, course.id).subscribe({
      next: () => {
        this.snackBar.open(`Enrolled in ${course.name}`, 'Close', { duration: 3000 });
        this.loadData();
      },
      error: (error) => {
        console.error('Error enrolling:', error);
        this.snackBar.open(error.error?.detail || 'Failed to enroll', 'Close', { duration: 3000 });
      }
    });
  }

  unenroll(enrollment: UserEnrollment): void {
    if (confirm(`Remove enrollment from ${enrollment.course_name}?`)) {
      this.userService.unenrollUserFromCourse(this.data.user.id, enrollment.course_id).subscribe({
        next: () => {
          this.snackBar.open('Enrollment removed', 'Close', { duration: 3000 });
          this.loadData();
        },
        error: (error) => {
          console.error('Error unenrolling:', error);
          this.snackBar.open('Failed to remove enrollment', 'Close', { duration: 3000 });
        }
      });
    }
  }

  close(): void {
    this.dialogRef.close(true);
  }
}
