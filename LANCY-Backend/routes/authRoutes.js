const express = require("express");
const router = express.Router();
const authController = require("../controllers/authController");

// --- ROUTES D'AUTHENTIFICATION ---

// Inscription (Register) : Crée l'utilisateur (isVerified: false) et envoie l'OTP
router.post("/register", authController.register);

// Connexion (Login) : Utilise bcrypt.compare et vérifie si isVerified est true
router.post("/login", authController.login);

// Mot de passe oublié : Envoie un OTP pour réinitialisation
router.post("/forgot-password", authController.forgotPassword);

// Vérification de l'OTP : Valide le code pour l'inscription ou le reset
router.post("/verify-otp", authController.verifyOTP);

// Réinitialisation : Change le mot de passe une fois l'OTP validé
router.post("/reset-password", authController.resetPassword);

// --- ROUTES SPÉCIFIQUES ---

// Connexion unique pour l'interface Web de l'Administrateur
router.post("/admin-login", authController.adminLogin);

module.exports = router;