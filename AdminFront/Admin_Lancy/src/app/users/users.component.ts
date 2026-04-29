import { Component, OnInit } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { AdminService } from '../services/admin.service';
@Component({
  selector: 'app-users',
  templateUrl: './users.component.html',
  styleUrls: ['./users.component.css']
})
export class UsersComponent implements OnInit {

  users: any[] = [];
 

  constructor(private http: HttpClient , private adminService: AdminService) {}

  ngOnInit(): void {
    this.getUsers();
  }

  getUsers() {
    this.http.get<any[]>('http://localhost:5001/api/admin/users')
      .subscribe(data => {
        this.users = data;
      });
  }
deleteUser(id: string) {
    if (confirm('Voulez-vous vraiment supprimer cet utilisateur ?')) {
      // Si 'adminService' n'est pas dans le constructor, cette ligne provoque l'erreur
      this.adminService.deleteUser(id).subscribe({
        next: () => {
          this.users = this.users.filter(u => u._id !== id);
          alert('Utilisateur supprimé');
        },
        error: (err: any) => console.error(err)
      });
    }
  }
}
