import { Component, OnInit } from '@angular/core';
import { AdminService, Project } from '../services/admin.service';

@Component({
  selector: 'app-projects',
  templateUrl: './projects.component.html',
  styleUrls: ['./projects.component.css'],
})
export class ProjectsComponent implements OnInit {

  projects: Project[] = [];
  loading = true;
  error   = '';

  constructor(private adminService: AdminService) {}

  ngOnInit(): void {
    this.adminService.getProjects().subscribe({
      next:  (data) => { this.projects = data; this.loading = false; },
      error: (err)  => { this.error = err.message; this.loading = false; },
    });
  }

  ownerName(p: Project): string  { return (p.owner as any)?.name  || 'Inconnu'; }
  ownerEmail(p: Project): string { return (p.owner as any)?.email || ''; }

  deleteProject(id: string) {
    if (!confirm('Supprimer ce projet ?')) return;

    this.adminService.deleteProject(id).subscribe({
      next:  () => { this.projects = this.projects.filter(p => p._id !== id); },
      error: (err) => alert('Erreur : ' + err.message),
    });
  }
}