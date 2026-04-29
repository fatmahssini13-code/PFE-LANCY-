const Proposal = require("../models/proposal");
const Project = require("../models/project");
const Notification = require("../models/notification");
const Conversation = require("../models/conversation");

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

    const notif = await Notification.create({
      userId: project.owner._id,
      title: "Nouvelle proposition 💼",
      message: `${req.user.name} a envoyé une proposition`,
    });

    const io = req.app.get("io");
    if (io) io.to(project.owner._id.toString()).emit("notification", notif);

    res.status(201).json({ message: "Proposition envoyée", proposal });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// =======================
// GET PROPOSALS
// =======================
const getProjectProposals = async (req, res) => {
  try {
    const proposals = await Proposal.find({ project: req.params.id })
      .populate("freelancer", "name email")
      .populate("project");

    res.json(proposals);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// =======================
// ACCEPT PROPOSAL
// =======================
const acceptProposal = async (req, res) => {
  try {
    const proposal = await Proposal.findById(req.params.id);
    if (!proposal)
      return res.status(404).json({ message: "Proposal not found" });

    proposal.status = "accepted";
    await proposal.save();

    const project = await Project.findById(proposal.project);

    project.acceptedFreelancer = proposal.freelancer;
    project.status = "accepted";
    await project.save();

    // create conversation
    let conversation = await Conversation.findOne({
      project: project._id,
    });

    if (!conversation) {
      conversation = await Conversation.create({
        participants: [
          project.owner.toString(),
          proposal.freelancer.toString(),
        ],
        project: project._id,
      });
    }

    res.json({
      message: "Accepted",
      conversation,
      project,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// =======================
// REJECT
// =======================
const rejectProposal = async (req, res) => {
  try {
    const proposal = await Proposal.findByIdAndUpdate(
      req.params.id,
      { status: "rejected" },
      { new: true }
    );

    res.json({ message: "Refused", proposal });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// ✅ EXPORT FIXED (IMPORTANT)
module.exports = {
  createProposal,
  getProjectProposals,
  acceptProposal,
  rejectProposal,
};