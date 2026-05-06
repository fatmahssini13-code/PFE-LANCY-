import { HttpClient } from '@angular/common/http';
import { Component } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { Router } from '@angular/router';



// Dans ta classe :

@Component({
  selector: 'app-login',
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.css']
})
export class LoginComponent {

  loginForm: FormGroup;
  step: number = 1; // 1 = Login, 2 = OTP
  otpValue: string = '';
  
  // On définit l'URL de base pour ne pas la répéter (utilise ton IP actuelle .15)
private apiUrl = "http://192.168.100.13:5001";
//private apiUrl ="http://10.152.12.126:5001"
  constructor(
    private fb: FormBuilder,
    private http: HttpClient, 
    private router: Router
  ) {
    this.loginForm = this.fb.group({
      email: ['', [Validators.required, Validators.email]],
      password: ['', Validators.required]
    });
  }

  // ... reste du code ...

  // ÉTAPE 1 : Connexion Admin
  onSubmit() {
    if (this.loginForm.valid) {
      // AJOUT DE /auth ICI 👇
      this.http.post(`${this.apiUrl}/api/auth/admin-login`, this.loginForm.value)
        .subscribe({
          next: (res: any) => {
            this.step = 2; 
            alert('Identifiants validés. Code OTP envoyé par email ! 📧');
          },
          error: (err: any) => {
            alert('Email ou mot de passe incorrect ❌');
          }
        });
    }
  }
verifyAdminOTP() {
  const data = {
    email: this.loginForm.value.email,
    code: this.otpValue
  };

  this.http.post(`${this.apiUrl}/api/auth/verify-otp`, data)
    .subscribe({
      next: (res: any) => {
        localStorage.setItem('adminToken', res.token);
        this.router.navigate(['/dashboard']);
      },
      error: () => {
        alert("Code OTP incorrect ou expiré ❌");
      }
    });
}}