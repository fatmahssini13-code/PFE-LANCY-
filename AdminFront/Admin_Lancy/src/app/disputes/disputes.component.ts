import { Component, OnInit } from '@angular/core';
import { AdminService } from '../services/admin.service';

@Component({
  selector: 'app-disputes',
  templateUrl: './disputes.component.html',
  styleUrls: ['./disputes.component.css']
})

export class DisputesComponent implements OnInit {

  disputes: any[] = [];

  loading = false;

  selectedDecision = '';

  note = '';

  constructor(
    private adminService: AdminService
  ) {}

  ngOnInit(): void {
    this.loadDisputes();
  }

  // ─────────────────────────────
  // LOAD DISPUTES
  // ─────────────────────────────

  loadDisputes() {

    this.loading = true;

    this.adminService.getDisputes()
      .subscribe({

        next: (data: any) => {

          console.log(data);

          this.disputes = data;

          this.loading = false;
        },

        error: (err) => {

          console.log(err);

          this.loading = false;
        }
      });
  }

  // ─────────────────────────────
  // RESOLVE DISPUTE
  // ─────────────────────────────

  resolveDispute(
    projectId: string,
    decision: string
  ) {

    const body = {

      decision: decision,

      note: this.note
    };

    this.adminService
      .resolveDispute(projectId, body)

      .subscribe({

        next: (res) => {

          alert("Litige résolu ✅");

          this.loadDisputes();
        },

        error: (err) => {

          console.log(err);

          alert("Erreur");
        }
      });
  }
}