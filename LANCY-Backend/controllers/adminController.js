const Project = require("../models/Project");
const User = require("../models/User");

// ─── 1. STATS ────────────────────────────────────────────────────────────────
exports.getStats = async (req, res) => {
  try {
    const totalUsers    = await User.countDocuments();
    const clients       = await User.countDocuments({ role: "client" });
    const freelancers   = await User.countDocuments({ role: "freelancer" });

    const open          = await Project.countDocuments({ status: "open" });
    const inProgress    = await Project.countDocuments({ status: "in_progress" });
    const completed     = await Project.countDocuments({ status: "completed" });

    const escrowProjects = await Project.find({ paymentStatus: "escrow_locked" });
    const escrowTotal    = escrowProjects.reduce((sum, p) => sum + (p.budget || 0), 0);

    res.json({
      users:    { total: totalUsers, clients, freelancers },
      projects: { open, inProgress, completed },
      escrow:   { total: escrowTotal },
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// ─── 2. TOUS LES UTILISATEURS ─────────────────────────────────────────────────
exports.getAllUsers = async (req, res) => {
  try {
    const users = await User.find().select("-password").sort({ createdAt: -1 });
    res.json(users);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// ─── 3. SUPPRIMER UN UTILISATEUR ─────────────────────────────────────────────
exports.deleteUser = async (req, res) => {
  try {
    const user = await User.findByIdAndDelete(req.params.id);
    if (!user) return res.status(404).json({ message: "Utilisateur non trouvé" });
    res.json({ message: "Utilisateur supprimé ✅" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// ─── 4. BLOQUER / DÉBLOQUER UN UTILISATEUR ───────────────────────────────────
exports.toggleBlock = async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ message: "Utilisateur non trouvé" });

    user.isBlocked = !user.isBlocked;
    await user.save();

    res.json({
      message: user.isBlocked ? "Utilisateur bloqué 🚫" : "Utilisateur débloqué ✅",
      isBlocked: user.isBlocked,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// ─── 5. TOUS LES PROJETS (ADMIN) ─────────────────────────────────────────────
exports.getAllProjects = async (req, res) => {
  try {
    const projects = await Project.find()
      .populate("owner", "name email avatar")
      .sort({ createdAt: -1 });
    res.json(projects);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// ─── 6. PROJETS EN ESCROW ────────────────────────────────────────────────────
exports.getEscrowProjects = async (req, res) => {
  try {
    const projects = await Project.find({ paymentStatus: "escrow_locked" })
      .populate("owner", "name email")
      .populate({
        path: "selectedProposal",
        populate: { path: "freelancer", select: "name email" },
      });
    res.json(projects);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// ─── 7. LIBÉRER LES FONDS ────────────────────────────────────────────────────
exports.releaseFunds = async (req, res) => {
  try {
    const { projectId } = req.body;
    const project = await Project.findById(projectId).populate("selectedProposal");

    if (!project || project.paymentStatus !== "escrow_locked") {
      return res.status(400).json({ message: "Projet non éligible au paiement" });
    }

    project.paymentStatus = "released";
    project.status        = "completed";
    await project.save();

    if (project.selectedProposal?.freelancer) {
      await User.findByIdAndUpdate(project.selectedProposal.freelancer, {
        $inc: { balance: project.budget },
      });
    }

    res.json({ message: "Fonds libérés avec succès ✅" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// ─── 8. REMBOURSER LE CLIENT ─────────────────────────────────────────────────
exports.refundClient = async (req, res) => {
  try {
    // Supporte projectId depuis req.body OU req.params.id
    const projectId = req.body.projectId || req.params.id;
    const project   = await Project.findById(projectId);

    if (!project || project.paymentStatus !== "escrow_locked") {
      return res.status(400).json({ message: "Impossible de rembourser" });
    }

    project.paymentStatus = "refunded";
    project.status        = "cancelled";
    await project.save();

    res.json({ message: "Client remboursé avec succès 💸" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// ─── 9. LITIGES ──────────────────────────────────────────────────────────────
exports.getDisputes = async (req, res) => {
  try {
    const disputes = await Project.find({ status: "disputed" })
      .populate("owner", "name email")
      .populate("acceptedFreelancer", "name email")
      .sort({ createdAt: -1 });
    res.json(disputes);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// ─── 10. RÉSOUDRE UN LITIGE ──────────────────────────────────────────────────
exports.resolveDispute = async (req, res) => {
  try {
    const { decision, note } = req.body; // 'freelancer' | 'client'
    const project = await Project.findById(req.params.id).populate("selectedProposal");

    if (!project) return res.status(404).json({ message: "Projet non trouvé" });

    if (decision === "freelancer") {
      project.paymentStatus = "released";
      project.status        = "completed";

      if (project.selectedProposal?.freelancer) {
        await User.findByIdAndUpdate(project.selectedProposal.freelancer, {
          $inc: { balance: project.budget },
        });
      }
    } else if (decision === "client") {
      project.paymentStatus = "refunded";
      project.status        = "cancelled";
    } else {
      return res.status(400).json({ message: "Décision invalide" });
    }

    if (note) project.disputeResolutionNote = note;
    await project.save();

    res.json({ message: `Litige résolu en faveur du ${decision} ✅`, project });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};