import { Component, OnInit } from '@angular/core';
import { AdminService } from '../services/admin.service';
import { HttpClient } from '@angular/common/http';

@Component({
  selector: 'app-escrow-management',
  templateUrl: './escrow-management.component.html',
  styleUrls: ['./escrow-management.component.css']
})
export class EscrowManagementComponent implements OnInit {
  projects: any[] = [];
  loading: boolean = false; // Ajouté pour corriger l'erreur HTML
  error: string | null = null; // Ajouté pour corriger l'erreur HTML

  constructor(private adminService: AdminService, private http: HttpClient) {}

  ngOnInit(): void {
    this.loadProjects();
  }

  loadProjects() {
    this.loading = true;
    this.error = null;
    this.adminService.getEscrowProjects().subscribe({
      next: (data) => {
        console.log("ESCROW DATA:",data);
        this.projects = data as any[];
        this.loading = false;
      },
      error: (err) => {
        this.error = "Impossible de charger les projets.";
        this.loading = false;
        console.error(err);
      }
    });
  }

  // Fonctions pour extraire les noms (Ajoutées pour corriger les erreurs HTML)
  ownerName(project: any): string {
    return project.owner?.name || 'Client inconnu';
  }

  freelancerName(project: any): string {
    return project.selectedProposal?.freelancer?.name || 'Non assigné';
  }

onRelease(projectId: string) {
  if (!confirm("Release funds to freelancer?")) return;

  this.http.post(`http://localhost:5001/api/escrow/release-funds`, {
    projectId
  }).subscribe({
    next: () => this.loadProjects(),
    error: (err) => console.log(err)
  });
}
getStatusClass(status: string) {
  switch (status) {
    case 'held': return 'badge bg-warning text-dark';
    case 'released': return 'badge bg-success';
    case 'refunded': return 'badge bg-danger';
    default: return 'badge bg-secondary';
  }
}
onRefund(projectId: string) {
  if (!confirm("Refund client?")) return;

  this.http.post("http://localhost:5001/api/escrow/refund-client", {
    projectId
  }).subscribe({
    next: () => this.loadProjects(),
    error: (err) => console.log(err)
  });
}

}