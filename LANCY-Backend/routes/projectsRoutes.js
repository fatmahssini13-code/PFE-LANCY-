const express = require("express");
const router = express.Router();

const Project = require("../models/project");
const User = require("../models/User");
const Proposal = require("../models/proposal");
const { requireAuth, optionalAuth } = require("../middleware/authMiddleware");

const projectController = require("../controllers/projectController");

// =======================
// LIST ALL PROJECTS (freelancer missions / marketplace)
// =======================
router.get("/", optionalAuth, projectController.getProjects);

// =======================
// ADD PROJECT
// =======================
router.post("/add", requireAuth, async (req, res) => {
  try {
    const { title, description, budget, clientEmail } = req.body;

    const client = await User.findOne({ email: clientEmail });

    if (!client) {
      return res.status(404).json({ message: "Utilisateur non trouvé" });
    }

    const newProject = new Project({
      title,
      description,
      budget,
      owner: client._id,
      status: "open",
    });

    await newProject.save();

    res.status(201).json({
      message: "Projet ajouté",
      project: newProject,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});


// =======================
// MY PROJECTS
// =======================
router.get("/my", requireAuth, async (req, res) => {
  try {
    const projects = await Project.find({ owner: req.user._id })
      .populate("acceptedFreelancer", "name email")
      .populate("owner", "name email")
      .sort({ createdAt: -1 });
    res.json(projects);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});


// =======================
// DELIVER PROJECT
// =======================
router.put("/:id/deliver", requireAuth, projectController.deliverProject);
router.get("/:id", optionalAuth, async (req, res) => {
  try {
    const project = await Project.findById(req.params.id)
      .populate("owner", "name email") // Récupère le nom du client
      .populate("acceptedFreelancer", "name email"); // Récupère le nom du freelancer

    if (!project) {
      return res.status(404).json({ message: "Projet non trouvé" });
    }

    res.json(project);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
router.put("/approve/:id", requireAuth, projectController.approveAndReleaseFunds);
module.exports = router;