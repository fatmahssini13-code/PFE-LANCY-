// admin.service.ts
import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

@Injectable({ providedIn: 'root' })
export class AdminService {
  // Utilisation de localhost pour le développement web
  private apiUrl = 'http://localhost:5001/api/admin/users';
private projectUrl = 'http://localhost:5001/api/projects';
  constructor(private http: HttpClient) {}

  // Méthode pour supprimer un utilisateur via son ID
  deleteUser(id: string): Observable<any> {
    return this.http.delete(`${this.apiUrl}/${id}`);
  }
  getProjects(): Observable<any[]> {
  return this.http.get<any[]>('http://localhost:5001/api/admin/projects');
}
deleteProject(id: string) {
  return this.http.delete(`http://localhost:5001/api/projects/${id}`);
}
getEscrowProjects() {
    return this.http.get<any[]>(`${this.apiUrl}/projects/escrow`);
  }

  // Action : Libérer les fonds au freelancer
  releaseFunds(projectId: string) {
    return this.http.post(`${this.apiUrl}/escrow/release`, { projectId });
  }

  // Action : Rembourser le client
  refundClient(projectId: string) {
    return this.http.post(`${this.apiUrl}/escrow/refund`, { projectId });
  }
}