const User = require("../models/User");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const OTP = require("../models/OTP");
const emailService = require("../services/emailServices");

// --- UTILITAIRES ---

// Fonction pour créer le Token JWT
function signToken(userId) {
  return jwt.sign({ id: userId }, process.env.JWT_SECRET, { expiresIn: "7d" });
}

// Générateur d'OTP (6 chiffres)
function generateOTP() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

// --- LOGIQUE D'AUTHENTIFICATION ---

// 1. INSCRIPTION (REGISTER)
exports.register = async (req, res) => {
  try {
    const { name, email, password, role, skills, bio } = req.body;

    if (!name || !email || !password || !role) {
      return res.status(400).json({ message: "Champs obligatoires manquants" });
    }

    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ message: "Cet email est déjà utilisé" });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    // Créer l'utilisateur (isVerified: false par défaut)
    const user = await User.create({
      name,
      email,
      password: hashedPassword,
      role,
      skills,
      bio,
      isVerified: false 
    });

    // Générer et envoyer l'OTP immédiatement
    const otpCode = generateOTP();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    await OTP.create({ email, code: otpCode, expiresAt, verified: false });
    await emailService.sendOTPEmail(email, otpCode);

    return res.status(201).json({
      message: "Utilisateur créé. Vérifiez votre email pour le code OTP ✨",
      email: email
    });
  } catch (error) {
    return res.status(500).json({ message: "Erreur serveur", error: error.message });
  }
};

// 2. CONNEXION (LOGIN)
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email });

    if (!user) return res.status(401).json({ message: "Identifiants invalides" });

    // Bloquer la connexion si l'email n'est pas vérifié
    if (!user.isVerified) {
      return res.status(403).json({ message: "Veuillez vérifier votre compte par email" });
    }

    const ok = await bcrypt.compare(password, user.password);
    if (!ok) return res.status(401).json({ message: "Identifiants invalides" });

    const token = signToken(user._id);
    return res.json({
      message: "Connexion réussie",
      token,
      user: { id: user._id, name: user.name, email: user.email, role: user.role }
    });
  } catch (err) {
    return res.status(500).json({ message: "Erreur serveur", error: String(err) });
  }
};

// 3. VÉRIFICATION OTP (VERIFY OTP)
exports.verifyOTP = async (req, res) => {
  try {
    const { email, code, isFromRegister } = req.body;
    
    const otpRecord = await OTP.findOne({
      email,
      code,
      verified: false,
      expiresAt: { $gt: new Date() },
    });

    if (!otpRecord) {
      return res.status(400).json({ message: "Code invalide ou expiré" });
    }

    // Marquer l'OTP comme utilisé/vérifié
    otpRecord.verified = true;
    await otpRecord.save();

    // Si c'est pour une inscription, on active le compte
    if (isFromRegister === true) {
      await User.findOneAndUpdate({ email }, { isVerified: true });
      await OTP.deleteOne({ _id: otpRecord._id });
      return res.json({ message: "Compte activé avec succès ! 🎉" });
    }

    return res.json({ message: "Code vérifié avec succès" });
  } catch (err) {
    return res.status(500).json({ message: "Erreur serveur" });
  }
};

// 4. MOT DE PASSE OUBLIÉ (FORGOT PASSWORD)
exports.forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ message: "Email requis" });

    const user = await User.findOne({ email });
    if (!user) {
      return res.json({ message: "Si l'email existe, un code a été envoyé" });
    }

    const otpCode = generateOTP();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000);

    await OTP.deleteMany({ email });
    await OTP.create({ email, code: otpCode, expiresAt, verified: false });

    await emailService.sendOTPEmail(email, otpCode);
    return res.json({ message: "Code OTP envoyé par email" });
  } catch (err) {
    return res.status(500).json({ message: "Erreur serveur", error: String(err) });
  }
};

// 5. RÉINITIALISATION (RESET PASSWORD)
exports.resetPassword = async (req, res) => {
  try {
    const { email, code, newPassword, confirmPassword } = req.body;

    if (newPassword !== confirmPassword) {
      return res.status(400).json({ message: "Les mots de passe ne correspondent pas" });
    }

    const otpRecord = await OTP.findOne({
      email,
      code,
      verified: true,
      expiresAt: { $gt: new Date() },
    });

    if (!otpRecord) {
      return res.status(400).json({ message: "Session expirée ou code non vérifié" });
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);
    await User.findOneAndUpdate({ email }, { password: hashedPassword });

    await OTP.deleteOne({ _id: otpRecord._id });

    return res.json({ message: "Mot de passe réinitialisé avec succès ! ✅" });
  } catch (err) {
    return res.status(500).json({ message: "Erreur serveur" });
  }
 
};
// Ajoute ceci à la fin de ton fichier authController.js
exports.adminLogin = async (req, res) => {
  try {
    const emailRecu = req.body.email ? req.body.email.trim().toLowerCase() : "";
    const passRecu = req.body.password;

    const ADMIN_EMAIL = "fatmahssini3@gmail.com";
    const ADMIN_PASS = "123456";

    console.log(`Tentative Login Admin: [${emailRecu}]`);

    if (emailRecu === ADMIN_EMAIL && passRecu === ADMIN_PASS) {
      const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
      const expiresAt = new Date(Date.now() + 5 * 60 * 1000);

      // Enregistrement de l'OTP
      const OTP = require("../models/OTP");
      await OTP.findOneAndUpdate(
        { email: ADMIN_EMAIL },
        { code: otpCode, expiresAt, verified: false },
        { upsert: true }
      );

      // Envoi de l'email
      const emailService = require("../services/emailServices");
      await emailService.sendOTPEmail(ADMIN_EMAIL, otpCode);

      return res.json({ message: "OTP envoyé", step: 2 });
    }

    return res.status(401).json({ message: "Identifiants Admin incorrects" });
  } catch (err) {
    console.error("Erreur AdminLogin:", err);
    return res.status(500).json({ message: "Erreur serveur", error: err.message });
  }
};