// admin.service.ts
import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

@Injectable({ providedIn: 'root' })
export class AdminService {
  // Utilisation de localhost pour le développement web
  private apiUrl = 'http://localhost:5000/api/admin/users';

  constructor(private http: HttpClient) {}

  // Méthode pour supprimer un utilisateur via son ID
  deleteUser(id: string): Observable<any> {
    return this.http.delete(`${this.apiUrl}/${id}`);
  }
}