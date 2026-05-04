const Proposal = require("../models/proposal");
const Project = require("../models/project");
const Notification = require("../models/notification");
const Conversation = require("../models/conversation");
const Wallet = require("../models/Wallet");
const Transaction = require("../models/Transaction");

// =======================
// CREATE PROPOSAL
// =======================
const createProposal = async (req, res) => {
  try {
    const { projectId, price, deliveryTime, coverLetter } = req.body;

    const project = await Project.findById(projectId).populate("owner");

    if (!project)
      return res.status(404).json({ message: "Projet non trouvé" });

    const existing = await Proposal.findOne({
      project: projectId,
      freelancer: req.user._id,
    });

    if (existing)
      return res.status(400).json({ message: "Déjà envoyé" });

    const proposal = await Proposal.create({
      project: projectId,
      freelancer: req.user._id,
      price,
      deliveryTime,
      coverLetter,
      status: "pending",
    });

    // ✅ Notification → client
    const notif = await Notification.create({
      userId: project.owner._id,
      title: "Nouvelle proposition 💼",
      message: `${req.user.name} a envoyé une proposition pour : "${project.title}"`,
    });

    // ✅ "socketio" au lieu de "io"
    const io = req.app.get("socketio");
    if (io) {
      const roomId = project.owner._id.toString();
      console.log(`🚀 Notification envoyée à room : ${roomId}`);
      io.to(roomId).emit("notification", {
        title: notif.title,
        message: notif.message,
      });
    }

    res.status(201).json({ message: "Proposition envoyée", proposal });
  } catch (err) {
    console.log("❌ Erreur createProposal:", err.message);
    res.status(500).json({ message: err.message });
  }
};

// =======================
// GET PROPOSALS
// =======================
const getProjectProposals = async (req, res) => {
  try {
    const projectDoc = await Project.findById(req.params.id);
    if (!projectDoc) {
      return res.status(404).json({ message: "Projet introuvable" });
    }
    if (projectDoc.owner.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: "Non autorisé" });
    }

    const proposals = await Proposal.find({ project: req.params.id })
      .populate("freelancer", "name email avatar")
      .populate("project");

    res.json(proposals);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// =======================
// ACCEPT PROPOSAL (ESCROW)
// =======================
const acceptProposal = async (req, res) => {
  try {
    const proposal = await Proposal.findById(req.params.id)
      .populate("project")
      .populate("freelancer", "name email");

    if (!proposal || !proposal.project) {
      return res.status(404).json({ message: "Proposition introuvable" });
    }

    const projectRef = proposal.project;
    const ownerId =
      projectRef.owner?._id?.toString?.() ?? projectRef.owner?.toString();

    if (!ownerId || ownerId !== req.user._id.toString()) {
      return res.status(403).json({
        message: "Action réservée au client propriétaire",
      });
    }

    if (proposal.status !== "pending") {
      return res.status(400).json({ message: "Proposition déjà traitée" });
    }

    const clientId = projectRef.owner;
    const freelancerId = proposal.freelancer?._id ?? proposal.freelancer;

    // Wallet escrow
    let clientWallet = await Wallet.findOne({ userId: clientId });
    if (!clientWallet) {
      clientWallet = await Wallet.create({
        userId: clientId,
        balance: 1000,
      });
    }

    if (clientWallet.balance < proposal.price) {
      return res.status(400).json({ message: "Solde insuffisant ❌" });
    }

    clientWallet.balance -= proposal.price;
    await clientWallet.save();

    await Transaction.create({
      from: clientId,
      to: "ESCROW",
      amount: proposal.price,
      type: "escrow",
    });

    proposal.status = "accepted";
    await proposal.save();

    const projectDoc = await Project.findById(projectRef._id);
    if (!projectDoc) {
      return res.status(404).json({ message: "Projet introuvable" });
    }

    projectDoc.status = "in_progress";
    projectDoc.escrowAmount = proposal.price;
    projectDoc.acceptedFreelancer = freelancerId;
    projectDoc.selectedProposal = proposal._id;
    await projectDoc.save();

    // ✅ Notification → freelancer
    const clientName = req.user.name || "Le client";
    const notifData = {
      title: "Proposition acceptée ! 🎉",
      message: `${clientName} a accepté votre proposition`,
    };

    await Notification.create({
      userId: freelancerId,
      ...notifData,
    });

    // ✅ "socketio" au lieu de "io"
    const io = req.app.get("socketio");
    if (io) {
      const roomId = freelancerId.toString();
      console.log(`🚀 Notification acceptée → room : ${roomId}`);
      io.to(roomId).emit("notification", notifData);
    }

    res.json({ message: "Projet démarré 💰 escrow activé" });
  } catch (err) {
    console.log("❌ Erreur acceptProposal:", err.message);
    res.status(500).json({ message: err.message });
  }
};

// =======================
// REJECT
// =======================
const rejectProposal = async (req, res) => {
  try {
    const proposal = await Proposal.findById(req.params.id)
      .populate("project")
      .populate("freelancer", "name email");

    if (!proposal || !proposal.project) {
      return res.status(404).json({ message: "Proposition introuvable" });
    }

    const ownerId =
      proposal.project.owner?._id?.toString?.() ??
      proposal.project.owner?.toString();

    if (!ownerId || ownerId !== req.user._id.toString()) {
      return res.status(403).json({
        message: "Action réservée au client propriétaire",
      });
    }

    if (proposal.status !== "pending") {
      return res.status(400).json({ message: "Proposition déjà traitée" });
    }

    proposal.status = "rejected";
    await proposal.save();

    // ✅ Notification → freelancer
    const clientName = req.user.name || "Le client";
    const freelancerId =
      proposal.freelancer?._id ?? proposal.freelancer;

    const notifData = {
      title: "Proposition refusée",
      message: `${clientName} a refusé votre proposition`,
    };

    await Notification.create({
      userId: freelancerId,
      ...notifData,
    });

    // ✅ "socketio" au lieu de "io"
    const io = req.app.get("socketio");
    if (io) {
      const roomId = freelancerId.toString();
      console.log(`🚀 Notification refusée → room : ${roomId}`);
      io.to(roomId).emit("notification", notifData);
    }

    res.json({ message: "Proposition refusée", proposal });
  } catch (err) {
    console.log("❌ Erreur rejectProposal:", err.message);
    res.status(500).json({ message: err.message });
  }
};

// =======================
// EXPORT
// =======================
module.exports = {
  createProposal,
  getProjectProposals,
  acceptProposal,
  rejectProposal,
};