const Wallet = require("../models/Wallet");
const Transaction = require("../models/Transaction");

exports.releasePayment = async (req, res) => {
  const project = await Project.findById(req.params.id);

  const freelancerWallet = await Wallet.findOne({
    userId: project.freelancer
  });

  freelancerWallet.balance += project.escrowAmount;
  await freelancerWallet.save();

  await Transaction.create({
    from: "ESCROW",
    to: project.freelancer,
    amount: project.escrowAmount,
    type: "release"
  });

  project.status = "completed";
  project.escrowAmount = 0;

  await project.save();

  res.json({ message: "Paiement envoyé 💸" });
};