const express = require("express");
const router = express.Router();

const Project = require("../models/project");
const User = require("../models/User");
const Proposal = require("../models/proposal");
const { requireAuth } = require("../middleware/authMiddleware");

// ✅ IMPORT لازم يكون في الأعلى
const {
  deliverProject
} = require("../controllers/projectController");


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
    const projects = await Project.find({ owner: req.user._id });
    res.json(projects);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});


// =======================
// DELIVER PROJECT
// =======================
router.put("/:id/deliver", requireAuth, deliverProject);

module.exports = router;