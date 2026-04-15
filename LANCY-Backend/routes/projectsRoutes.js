const express = require("express");
const router = express.Router();
const Project = require("../models/project");
const User = require("../models/User");
const { requireAuth } = require("../middleware/authMiddleware");

// ✅ La route doit être "/add" et non "/api/projects/add"
router.post("/add", requireAuth, async (req, res) => {
  try {
    // 1. Nettoyage immédiat des données
    const title = req.body.title;
    const description = req.body.description;
    const budget = Number(req.body.budget);
    const clientEmail = req.body.clientEmail ? req.body.clientEmail.trim().toLowerCase() : null;

    console.log("--- TENTATIVE D'AJOUT ---");
    console.log("Email reçu de Flutter :", `"${clientEmail}"`); // Les guillemets montrent les espaces cachés

    if (!clientEmail) {
      return res.status(400).json({ message: "Email manquant" });
    }

    // 2. Recherche insensible à la casse
    const client = await User.findOne({ 
      email: { $regex: new RegExp("^" + clientEmail + "$", "i") } 
    });

    if (!client) {
      console.log("ERREUR: Aucun utilisateur trouvé pour", clientEmail);
      return res.status(404).json({ message: "User not found" });
    }

    // 3. Création avec l'ID trouvé
    const newProject = new Project({
      title,
      description,
      budget,
      clientId: client._id,
      status: "open",
    });

    await newProject.save();
    console.log("PROJET CRÉÉ AVEC SUCCÈS ✅");
    res.status(201).json({ message: "Projet ajouté ✅", project: newProject });

  } catch (error) {
    console.error("ERREUR CRITIQUE :", error.message);
    res.status(500).json({ message: "Erreur serveur", error: error.message });
  }
});
module.exports = router;