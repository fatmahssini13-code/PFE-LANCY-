const express = require("express");
const router = express.Router();
const Project = require("../models/project");
const User = require("../models/User");
const Proposal = require("../models/proposal");
const { requireAuth } = require("../middleware/authMiddleware");


// ✅ 1. Ajouter un projet (CLIENT)
router.post("/add", requireAuth, async (req, res) => {
  try {
    const { title, description, budget, clientEmail } = req.body;

    if (!clientEmail) {
      return res.status(400).json({ message: "Email manquant" });
    }

    const client = await User.findOne({
      email: { $regex: new RegExp("^" + clientEmail.trim() + "$", "i") },
    });

    if (!client) {
      return res.status(404).json({ message: "Utilisateur non trouvé" });
    }

    const newProject = new Project({
      title,
      description,
      budget: Number(budget),
      owner: client._id,
      status: "open",
    });

    await newProject.save();

    res.status(201).json({
      message: "Projet ajouté ✅",
      project: newProject,
    });
  } catch (error) {
    console.error("🔥 Erreur:", error.message);
    res.status(500).json({ message: "Erreur serveur" });
  }
});


// ✅ 2. Mes projets (CLIENT)
router.get("/my", requireAuth, async (req, res) => {
  try {
    const projects = await Project.find({
      owner: req.user._id, 
    })
      .sort({ createdAt: -1 })
      .lean();

    res.status(200).json(projects);
  } catch (error) {
    res.status(500).json({ message: "Erreur serveur" });
  }
});


// ✅ 3. Tous les projets (FREELANCER)
router.get("/", async (req, res) => {
  try {
    const projects = await Project.find()
      .populate("owner", "name email") 
      .sort({ createdAt: -1 })
      .lean();

    // ✅ Ajouter nombre de propositions
    const projectsWithCount = await Promise.all(
      projects.map(async (project) => {
        const proposalCount = await Proposal.countDocuments({
          project: project._id,
          status: "pending",
        });

        return { ...project, proposalCount };
      })
    );

    res.status(200).json(projectsWithCount);
  } catch (error) {
    console.error("❌ Erreur:", error.message);
    res.status(500).json({ message: "Erreur serveur" });
  }
});


// ✅ 4. Modifier projet
router.put("/update/:id", requireAuth, async (req, res) => {
  try {
    const project = await Project.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true }
    );

    res.status(200).json(project);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


// ✅ 5. Supprimer projet
router.delete("/delete/:id", requireAuth, async (req, res) => {
  try {
    await Project.findByIdAndDelete(req.params.id);
    res.status(200).json({ message: "Projet supprimé ✅" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;