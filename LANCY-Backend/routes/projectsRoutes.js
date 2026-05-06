const express = require("express");
const router = express.Router();
const multer = require("multer");
const Project = require("../models/project");
const User = require("../models/User");
const Proposal = require("../models/proposal");
const { requireAuth, optionalAuth } = require("../middleware/authMiddleware");

const projectController = require("../controllers/projectController");
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, "uploads/");
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + "-" + file.originalname);
  }
});

const upload = multer({ storage });
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
router.put("/:id/deliver", requireAuth, upload.single("file"), async (req, res) => {
  try {
    const io = req.app.get("socketio");

    const projectId = req.params.id;
    const project = await Project.findById(projectId);

    if (!project) {
      return res.status(404).json({ message: "Projet non trouvé" });
    }

    project.status = "delivered";
    project.delivery = {
      file: req.file ? req.file.filename : null,
      link: req.body.link || null,
      message: req.body.message || "",
    };

    await project.save();

    // 🔥 notif client
    io.to(project.owner.toString()).emit("notification", {
      title: "Travail livré 📦",
      message: "Le freelancer a livré votre projet",
      projectId: project._id
    });

    res.json({ success: true, project });

  } catch (err) {
    console.error("❌ Deliver error:", err);
    res.status(500).json({ error: err.message });
  }
});
module.exports = router;