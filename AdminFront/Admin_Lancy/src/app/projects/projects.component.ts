import { Component, OnInit } from '@angular/core';
import { AdminService } from '../services/admin.service';

@Component({
  selector: 'app-projects',
  templateUrl: './projects.component.html',
  styleUrls: ['./projects.component.css']
})
export class ProjectsComponent implements OnInit {
  projects: any[] = [];

  constructor(private adminService: AdminService) {}

  ngOnInit(): void {
  this.adminService.getProjects().subscribe({
    next: (data) => {
      this.projects = data;
      console.log("Projets reçus :", data);
    },
    error: (err) => console.error("Erreur de chargement projets", err)
  });
}
  deleteProject(id: string): void {
    if (confirm('Voulez-vous vraiment supprimer ce projet ?')) {
      this.adminService.deleteProject(id).subscribe({
        next: () => {
          // Supprime le projet de la liste localement pour mettre à jour l'affichage
          this.projects = this.projects.filter(p => p._id !== id);
          console.log('Projet supprimé avec succès');
        },
        error: (err) => {
          console.error('Erreur lors de la suppression', err);
        }
      });
    }
  }
}
