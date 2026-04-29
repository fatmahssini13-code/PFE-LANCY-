
const Project = require("../models/Project");
const User = require("../models/User");

// 1. Récupérer tous les projets dont l'argent est bloqué (pour le site Admin)
exports.getEscrowProjects = async (req, res) => {
  try {
    const projects = await Project.find({ paymentStatus: "escrow_locked" })
      .populate("owner", "name email")
      .populate({
        path: "selectedProposal",
        populate: { path: "freelancer", select: "name email" }
      });
    res.status(200).json(projects);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// 2. Libérer les fonds (L'argent va du "coffre" Lancy vers le Freelancer)
exports.releaseFunds = async (req, res) => {
  try {
    const { projectId } = req.body;
    const project = await Project.findById(projectId).populate("selectedProposal");

    if (!project || project.paymentStatus !== "escrow_locked") {
      return res.status(400).json({ message: "Projet non éligible au paiement" });
    }

    // On change le statut
    project.paymentStatus = "released";
    project.status = "completed";
    await project.save();

    // Optionnel : Créditer le solde du freelancer dans la DB
    const freelancerId = project.selectedProposal.freelancer;
    await User.findByIdAndUpdate(freelancerId, { $inc: { balance: project.budget } });

    res.status(200).json({ message: "Fonds libérés avec succès ✅" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// 3. Rembourser le client (L'argent retourne au Client)
exports.refundClient = async (req, res) => {
  try {
    const { projectId } = req.body;
    const project = await Project.findById(projectId);

    if (!project || project.paymentStatus !== "escrow_locked") {
      return res.status(400).json({ message: "Impossible de rembourser" });
    }

    project.paymentStatus = "refunded";
    project.status = "cancelled";
    await project.save();

    res.status(200).json({ message: "Client remboursé avec succès 💸" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};