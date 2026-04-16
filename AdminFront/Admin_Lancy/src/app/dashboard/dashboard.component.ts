import { Component, OnInit } from '@angular/core';
import { HttpClient } from '@angular/common/http';

@Component({
  selector: 'app-dashboard',
  templateUrl: './dashboard.component.html',
  styleUrls: ['./dashboard.component.css']
})
export class DashboardComponent implements OnInit {
  stats: any = { users: 0, freelancers: 0, clients: 0 };

  constructor(private http: HttpClient) {}

  ngOnInit(): void {
    // Appel de la route stats que nous avons créée dans Node.js
    this.http.get('http://localhost:5001/api/admin/stats').subscribe(data => {
      this.stats = data;
    });
  }
}