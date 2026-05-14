import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { LoginComponent } from './modules/auth/login/login.component';
import { DashboardComponent } from './dashboard/dashboard.component';
import { UsersComponent } from './users/users.component';
import { ProjectsComponent } from './projects/projects.component';
import { EscrowManagementComponent } from './escrow-management/escrow-management.component';
import { DisputesComponent } from './disputes/disputes.component';

const routes: Routes = [
  { path: 'login', component: LoginComponent },
  
  // Ajoute cette ligne 👇
  { path: 'dashboard', component: DashboardComponent }, 
  { path: 'users', component: UsersComponent },
    { path: 'projects', component: ProjectsComponent },
    {path:'escrow',component:EscrowManagementComponent},
  { path: 'disputes', component: DisputesComponent },//Redirection par défaut si besoin
 { path: '', redirectTo: '/login', pathMatch: 'full' }
]

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule { }
