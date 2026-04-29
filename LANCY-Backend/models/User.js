const mongoose = require("mongoose");

const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, unique: true, required: true },
  password: { type: String, required: true },
  
  // Rôles bien définis
  role: {
    type: String,
    enum: ["client", "freelancer"],
    required: true
  },

  // --- CHAMPS SPÉCIFIQUES FREELANCER ---
  speciality: { type: String }, // ex: "Designer UI/UX"
  // On transforme skills en tableau [String] pour faciliter l'affichage des "Chips" en Flutter/Angular
  skills: [String], 
  bio: { type: String },
  hourlyRate: { type: Number }, // Tarif horaire
  
  // --- CHAMPS SPÉCIFIQUES CLIENT ---
  companyName: { type: String }, // Nom de l'entreprise ou "Particulier"
  location: { type: String },

  // --- PARAMÈTRES COMMUNS ---
  avatar: { type: String, default: "" }, // URL de la photo
  phoneNumber: { type: String },
  isVerified: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.models.User || mongoose.model("User", userSchema);