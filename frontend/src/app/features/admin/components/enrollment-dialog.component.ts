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
                <div class="checkbox-container">
                  <mat-checkbox 
                    [checked]="course.enrolled"
                    (change)="toggleEnrollment(course, $event.checked)"
                    color="primary">
                  </mat-checkbox>
                </div>
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
      min-width: 800px;
      width: 85vw;
      max-width: 1200px;
      max-height: 70vh;
      padding: 20px;
      overflow-y: auto;
    }

    .courses-table {
      width: 100%;
    }

    table {
      width: 100%;
      border-collapse: collapse;
    }

    th.mat-mdc-header-cell {
      font-size: 14px;
      font-weight: 600;
      color: rgba(0,0,0,0.87);
      background: #f5f5f5;
      padding: 16px !important;
      vertical-align: middle !important;
      height: 56px !important;
      line-height: 56px;
    }

    th.mat-mdc-header-cell:first-child {
      width: 120px;
      min-width: 120px;
      max-width: 120px;
      text-align: center;
    }

    td.mat-mdc-cell {
      padding: 0 16px !important;
      vertical-align: middle !important;
      height: 56px !important;
      box-sizing: border-box;
    }

    td.mat-mdc-cell:first-child {
      width: 120px;
      min-width: 120px;
      max-width: 120px;
      text-align: center;
      padding: 0 !important;
    }

    .checkbox-container {
      display: flex;
      align-items: center;
      justify-content: center;
      height: 100%;
      width: 100%;
    }

    .course-name {
      display: flex;
      align-items: center;
      gap: 12px;
      min-width: 0;
      height: 100%;
    }

    .course-name span {
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
      flex: 1;
      min-width: 0;
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
      display: flex !important;
      align-items: center !important;
      justify-content: center !important;
    }

    ::ng-deep .mat-mdc-checkbox {
      display: flex !important;
      align-items: center !important;
      justify-content: center !important;
    }

    ::ng-deep .mat-mdc-checkbox .mdc-checkbox {
      padding: 0 !important;
      margin: 0 !important;
      display: flex !important;
      align-items: center !important;
      justify-content: center !important;
    }

    ::ng-deep .mat-mdc-checkbox .mdc-form-field {
      vertical-align: middle !important;
      display: flex !important;
      align-items: center !important;
      padding: 0 !important;
      margin: 0 !important;
    }

    ::ng-deep .mat-mdc-checkbox label {
      padding: 0 !important;
      margin: 0 !important;
      display: flex !important;
      align-items: center !important;
    }

    ::ng-deep .mat-mdc-checkbox .mdc-checkbox__background {
      top: 50% !important;
      transform: translateY(-50%) !important;
    }

    tr.mat-mdc-row {
      height: 56px !important;
    }

    tr.mat-mdc-header-row {
      height: 56px !important;
    }

    tr.mat-mdc-row td {
      border-bottom: 1px solid rgba(0,0,0,0.12);
    }

    tr.mat-mdc-row:hover {
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
        next: (enrollment) => {
          this.snackBar.open(`Enrolled in ${course.name}`, 'Close', { duration: 2000 });
          // Update local state without full reload
          const currentEnrollments = this.enrollments();
          this.enrollments.set([...currentEnrollments, {
            id: enrollment.id || Date.now(),
            course_id: course.id,
            course_name: course.name,
            enrolled_at: new Date().toISOString()
          }]);
        },
        error: (error) => {
          console.error('Error enrolling:', error);
          this.snackBar.open(error.error?.detail || 'Failed to enroll', 'Close', { duration: 3000 });
        }
      });
    } else {
      // Unenroll
      this.userService.unenrollUserFromCourse(this.data.user.id, course.id).subscribe({
        next: () => {
          this.snackBar.open(`Unenrolled from ${course.name}`, 'Close', { duration: 2000 });
          // Update local state without full reload
          const currentEnrollments = this.enrollments();
          this.enrollments.set(currentEnrollments.filter(e => e.course_id !== course.id));
        },
        error: (error) => {
          console.error('Error unenrolling:', error);
          this.snackBar.open('Failed to unenroll', 'Close', { duration: 3000 });
        }
      });
    }
  }

  close(): void {
    this.dialogRef.close(true);
  }
}
