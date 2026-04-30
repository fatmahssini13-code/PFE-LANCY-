const Wallet = require("../models/Wallet");
const Transaction = require("../models/Transaction");
const Project = require("../models/project");

exports.releasePayment = async (req, res) => {
  try {
    const project = await Project.findById(req.params.id);

    if (!project || !project.acceptedFreelancer) {
      return res.status(400).json({ message: "Projet sans freelance assigné" });
    }

    const freelancerWallet = await Wallet.findOne({
      userId: project.acceptedFreelancer,
    });

    if (!freelancerWallet) {
      return res
        .status(400)
        .json({ message: "Portefeuille freelance introuvable" });
    }

    freelancerWallet.balance += project.escrowAmount ?? 0;
    await freelancerWallet.save();

    await Transaction.create({
      from: "ESCROW",
      to: project.acceptedFreelancer,
      amount: project.escrowAmount,
      type: "release",
    });

    project.status = "completed";
    project.escrowAmount = 0;

    await project.save();

    res.json({ message: "Paiement envoyé 💸" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
