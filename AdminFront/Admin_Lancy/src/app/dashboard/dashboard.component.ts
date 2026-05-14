// ==========================
// dashboard.component.ts
// ==========================

import {
  Component,
  OnInit,
  ViewChild,
  ElementRef
} from '@angular/core';

import { Chart, registerables } from 'chart.js';

import { AdminService } from '../services/admin.service';

Chart.register(...registerables);

@Component({
  selector: 'app-dashboard',
  templateUrl: './dashboard.component.html',
  styleUrls: ['./dashboard.component.css']
})

export class DashboardComponent implements OnInit {
isDarkMode = false;
private projectChartInstance?: Chart;
private userChartInstance?: Chart;
toggleDarkMode() {

  this.isDarkMode = !this.isDarkMode;

  if (this.isDarkMode) {

    document.body.classList.add('dark-theme');

  } else {

    document.body.classList.remove('dark-theme');

  }
}

  @ViewChild('projectsChart')
  projectsChart!: ElementRef;

  @ViewChild('usersChart')
  usersChart!: ElementRef;

  stats: any = {

    users: {
      total: 0,
      clients: 0,
      freelancers: 0
    },

    projects: {
      open: 0,
      inProgress: 0,
      completed: 0
    },

    escrow: {
      total: 0
    }

  };

  constructor(
    private adminService: AdminService
  ) {}

  ngOnInit(): void {

    this.adminService.getStats()
      .subscribe({

        next: (data) => {

          console.log(data);

          this.stats = data;

          setTimeout(() => {

            this.loadProjectsChart();
            this.loadUsersChart();

          }, 100);

        },

        error: (err) => {
          console.log(err);
        }

      });
  }

  // ================= BAR CHART =================
 // Ajoute ces propriétés en haut de ta classe
;

// Modifie tes méthodes comme ceci :

loadProjectsChart() {
  if (this.projectChartInstance) this.projectChartInstance.destroy();

  const textColor = this.isDarkMode ? '#e3e3e3' : '#2d3748';

  this.projectChartInstance = new Chart(this.projectsChart.nativeElement, {
    type: 'bar',
    data: {
      labels: ['Ouverts', 'En cours', 'Terminés'],
      datasets: [{
        label: 'Projets',
        data: [
          this.stats.projects.open,
          this.stats.projects.inProgress,
          this.stats.projects.completed
        ],
        backgroundColor: ['#00AEEF', '#8E2DE2', '#4cd3e6'],
        borderRadius: 8
      }]
    },
    options: {
      responsive: true,
      plugins: {
        legend: { display: false }
      },
      scales: {
        y: {
          ticks: { color: textColor },
          grid: { color: this.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)' }
        },
        x: {
          ticks: { color: textColor }
        }
      }
    }
  });
}

loadUsersChart() {
  if (this.userChartInstance) this.userChartInstance.destroy();

  this.userChartInstance = new Chart(this.usersChart.nativeElement, {
    type: 'doughnut',
    data: {
      labels: ['Clients', 'Freelancers'],
      datasets: [{
        data: [this.stats.users.clients, this.stats.users.freelancers],
        backgroundColor: ['#00AEEF', '#8E2DE2'],
        hoverOffset: 10,
        borderWidth: this.isDarkMode ? 2 : 0,
        borderColor: '#232629'
      }]
    },
    options: {
      responsive: true,
      cutout: '70%', // Look plus moderne "Soft UI"
      plugins: {
        legend: {
          position: 'bottom',
          labels: { color: this.isDarkMode ? '#e3e3e3' : '#2d3748', usePointStyle: true }
        }
      }
    }
  });
}
}