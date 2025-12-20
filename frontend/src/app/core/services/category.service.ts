import { Injectable, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, tap, map } from 'rxjs';
import { environment } from '../../../environments/environment';
import { Category } from '../models/category.model';

@Injectable({
  providedIn: 'root'
})
export class CategoryService {
  private apiUrl = `${environment.apiUrl}/categories`;
  private categoriesSignal = signal<Category[]>([]);

  categories = this.categoriesSignal.asReadonly();

  constructor(private http: HttpClient) {}

  getCategories(): Observable<Category[]> {
    return this.http.get<any[]>(this.apiUrl)
      .pipe(
        map(categories => categories.map(cat => ({
          id: cat.id,
          name: cat.name,
          path: cat.path,
          createdAt: cat.created_at
        }))),
        tap(categories => this.categoriesSignal.set(categories))
      );
  }

  getCategoryById(id: number): Observable<Category> {
    return this.http.get<any>(`${this.apiUrl}/${id}`)
      .pipe(
        map(cat => ({
          id: cat.id,
          name: cat.name,
          path: cat.path,
          createdAt: cat.created_at
        }))
      );
  }
}
