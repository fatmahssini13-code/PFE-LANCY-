const express = require("express");
const router  = express.Router();

const adminController   = require("../controllers/adminController");
const { requireAuth, isAdmin } = require("../middleware/authMiddleware");

// Applique auth + rôle admin sur toutes les routes de ce fichier
// router.use(requireAuth, isAdmin);   // ← Décommente en prod

// ─── STATS ────────────────────────────────────────────────────────────────────
// GET /api/admin/stats
router.get("/stats", adminController.getStats);

// ─── UTILISATEURS ─────────────────────────────────────────────────────────────
// GET    /api/admin/users
// DELETE /api/admin/users/:id
// PUT    /api/admin/users/:id/toggle-block
router.get("/users",                   adminController.getAllUsers);
router.delete("/users/:id",            adminController.deleteUser);
router.put("/users/:id/toggle-block",  adminController.toggleBlock);

// ─── PROJETS ──────────────────────────────────────────────────────────────────
// GET /api/admin/projects
router.get("/projects", adminController.getAllProjects);

// ─── ESCROW ───────────────────────────────────────────────────────────────────
// GET  /api/admin/escrow-projects
// POST /api/admin/release-funds      { projectId }
// POST /api/admin/refund/:id
router.get("/escrow-projects",   adminController.getEscrowProjects);
router.post("/release-funds",    adminController.releaseFunds);
router.post("/refund/:id",       adminController.refundClient);

// ─── LITIGES ──────────────────────────────────────────────────────────────────
// GET /api/admin/disputes
// PUT /api/admin/disputes/:id/resolve   { decision, note }
router.get("/disputes",                  adminController.getDisputes);
router.put("/disputes/:id/resolve",      adminController.resolveDispute);
router.get('/escrow', async (req, res) => {
  try {
    const Project = require("../models/project");

    const projects = await Project.find({ escrowStatus: "locked" })
      .populate("owner", "name email")
      .populate("acceptedFreelancer", "name email");

    res.json(projects);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
module.exports = router;