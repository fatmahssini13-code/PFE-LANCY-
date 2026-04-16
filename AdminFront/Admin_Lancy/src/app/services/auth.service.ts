import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http'; // Import indispensable
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class AuthService {

  // L'URL de ton backend Node.js avec le préfixe /auth
  private apiUrl = 'http://192.168.100.13:5001/auth';

  constructor(private http: HttpClient) { }

  // Méthode pour la connexion Admin (Dashboard)
  adminLogin(data: any): Observable<any> {
    // Cette ligne appelle : http://192.168.100.13:5001/auth/admin-login
    return this.http.post(`${this.apiUrl}/admin-login`, data);
  }

  // Méthode pour le login classique (si besoin sur le web)
  login(data: any): Observable<any> {
    return this.http.post(`${this.apiUrl}/login`, data);
  }
}