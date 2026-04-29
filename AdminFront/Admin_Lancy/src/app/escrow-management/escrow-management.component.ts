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

  constructor(private adminService: AdminService , private http: HttpClient) {}

  ngOnInit(): void {
    this.loadProjects();
  }

  loadProjects() {
    this.adminService.getEscrowProjects().subscribe(data => {
      this.projects = data;
    });
  }

onRelease(projectId: string) {
  if(confirm("Confirmer le paiement au freelancer ?")) {
    // On envoie le projectId dans le body {} comme attendu par ton contrôleur
    this.http.post(`http://localhost:5001/api/admin/release-funds`, { projectId }).subscribe({
      next: () => {
        alert("Fonds libérés avec succès ! ✅");
        this.loadProjects(); 
      },
      error: (err) => alert("Erreur lors de la libération")
    });
  }
}

onRefund(projectId: string) {
  if(confirm("Rembourser le client ?")) {
    this.http.post(`http://localhost:5001/api/admin/escrow/refund/${projectId}`, {}).subscribe({
      next: () => {
        alert("Client remboursé !");
        this.loadProjects();
      },
      error: (err) => console.error(err)
    });
  }
}}