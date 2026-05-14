import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

export interface User {
  _id: string;
  name: string;
  email: string;
  role: 'client' | 'freelancer' | 'admin';
  isBlocked: boolean;
  balance?: number;
  createdAt?: string;
}

export interface Project {
  _id: string;
  title: string;
  description: string;
  budget: number;
  status: string;
  paymentStatus: string;
  owner: Partial<User> | string;
  acceptedFreelancer?: Partial<User> | string;
  selectedProposal?: any;
  disputeReason?: string;
  createdAt: string;
}

export interface Stats {
  users:    { total: number; clients: number; freelancers: number };
  projects: { open: number; inProgress: number; completed: number };
  escrow:   { total: number };
}

@Injectable({ providedIn: 'root' })
export class AdminService {

  // ⚠️ Une seule base URL – toutes les routes sont sous /api/admin
  private api = 'http://localhost:5001/api/admin';
private apiu = 'http://localhost:5001/api/admin/escrow';
  constructor(private http: HttpClient) {}

  private headers(): HttpHeaders {
    return new HttpHeaders({
      Authorization: `Bearer ${localStorage.getItem('adminToken') ?? ''}`,
    });
  }

  // ─── STATS ──────────────────────────────────────────────────────────────────
  getStats(): Observable<Stats> {
    return this.http.get<Stats>(`${this.api}/stats`, { headers: this.headers() });
  }

  // ─── USERS ──────────────────────────────────────────────────────────────────
  getUsers(): Observable<User[]> {
    return this.http.get<User[]>(`${this.api}/users`, { headers: this.headers() });
  }

  deleteUser(id: string): Observable<any> {
    return this.http.delete(`${this.api}/users/${id}`, { headers: this.headers() });
  }

  toggleBlock(id: string): Observable<any> {
    return this.http.put(`${this.api}/users/${id}/toggle-block`, {}, { headers: this.headers() });
  }

  // ─── PROJECTS ───────────────────────────────────────────────────────────────
  getProjects(): Observable<Project[]> {
    return this.http.get<Project[]>(`${this.api}/projects`, { headers: this.headers() });
  }

  deleteProject(id: string): Observable<any> {
    // ⚠️ Cette route doit exister dans projectRoutes, pas adminRoutes
    return this.http.delete(`http://localhost:5001/api/projects/${id}`, { headers: this.headers() });
  }

  // ─── ESCROW ─────────────────────────────────────────────────────────────────


getEscrowProjects() {
  return this.http.get(this.apiu);
}

releaseFunds(projectId: string) {
  return this.http.post(`${this.apiu}/release-funds`, { projectId });
}

refundClient(projectId: string) {
  return this.http.post(`${this.apiu}/refund-client`, { projectId });
}
  // ─── DISPUTES ───────────────────────────────────────────────────────────────
// ─────────────────────────────
// GET DISPUTES
// ─────────────────────────────

getDisputes() {

  return this.http.get(
    `${this.api}/disputes`
  );
}

// ─────────────────────────────
// RESOLVE DISPUTE
// ─────────────────────────────

resolveDispute(
  id: string,
  body: any
) {

  return this.http.put(

    `${this.api}/disputes/${id}/resolve`,

    body
  );
}
}