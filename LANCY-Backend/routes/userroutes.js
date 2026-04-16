const router = require("express").Router();
const User = require("../models/User");

// --- 1. RÉCUPÉRER LE PROFIL (Adaptation dynamique selon le rôle) ---
// Utilise l'email comme identifiant unique dans l'URL (ex: /profile/test@gmail.com)
// --- 1. RÉCUPÉRER LE PROFIL (Version Optimisée pour Lancy) ---
router.get("/profile/:email", async (req, res) => {
    try {
        const emailNorm = decodeURIComponent(req.params.email || "")
            .trim()
            .toLowerCase();
        if (!emailNorm) {
            return res.status(400).json({ message: "Email requis" });
        }
        const esc = emailNorm.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
        const user = await User.findOne({
            email: { $regex: new RegExp("^" + esc + "$", "i") },
        });
        if (!user) return res.status(404).json({ message: "Utilisateur non trouvé" });

        let userData = {
            id: user._id,
            name: user.name,
            displayName: user.name || user.email.split('@')[0], // Pour Flutter user.displayName
            email: user.email,
            role: user.role,
            avatar: user.avatar || `https://ui-avatars.com/api/?name=${user.name}`,
            createdAt: user.createdAt
        };

        if (user.role === "freelancer") {
            userData.speciality = user.speciality || "Freelancer";
            userData.skills = user.skills || [];
            userData.bio = user.bio || "Passionné par le digital.";
        } else if (user.role === "client") {
            userData.companyName = user.companyName || "Particulier";
            
            // OPTIONAL: Si tu as importé le modèle Project en haut du fichier,
            // tu peux récupérer les vrais projets ici :
            // const Project = require("../models/project");
            // userData.projects = await Project.find({ clientId: user._id });
        }

        res.status(200).json(userData);
    } catch (err) {
        res.status(500).json({ message: "Erreur serveur", error: err.message });
    }
});

// --- 2. MISE À JOUR DU PROFIL ---
// Utilise la méthode PUT pour modifier des données existantes
router.put("/update/:email", async (req, res) => {
    try {
        // 'req.body' contient les nouveaux champs saisis dans l'application mobile
        const updates = req.body;
        
        const updatedUser = await User.findOneAndUpdate(
            { email: req.params.email }, // Filtre : quel utilisateur modifier ?
            { $set: updates },           // Action : mettre à jour avec les nouvelles données
            { new: true }                // Option : renvoie l'utilisateur APRÈS modification
        );

        res.status(200).json({
            message: "Profil mis à jour avec succès ✅",
            user: updatedUser
        });
    } catch (err) {
        res.status(500).json({ message: "Erreur lors de la mise à jour", error: err });
    }
});

// --- 3. RÉCUPÉRER TOUS LES FREELANCERS ---
// Utile pour la page d'accueil ou la recherche côté Client
router.get("/all-freelancers", async (req, res) => {
    try {
        // Filtre MongoDB : prend seulement ceux qui ont le rôle "freelancer"
        // .select(...) : Limite les données renvoyées pour économiser de la bande passante
        const freelancers = await User.find({ role: "freelancer" })
                                      .select("name email speciality skills bio avatar");
        
        res.status(200).json(freelancers);
    } catch (err) {
        res.status(500).json({ message: "Erreur récupération freelancers", error: err });
    }
});

module.exports = router;