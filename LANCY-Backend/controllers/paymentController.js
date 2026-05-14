const stripe = require("../config/stripe");
const Project = require("../models/project");
const User = require("../models/User"); 
// 🟢 CREATE PAYMENT INTENT
exports.createPaymentIntent = async (req, res) => {
  try {

    const { projectId } = req.body;

    const project = await Project.findById(projectId);

    if (!project) {
      return res.status(404).json({
        message: "Projet introuvable"
      });
    }

    const paymentIntent = await stripe.paymentIntents.create({
      amount: project.budget * 100,
      currency: "usd",

      // ✅ IMPORTANT
      metadata: {
        projectId: projectId
      }
    });

    res.json({
      clientSecret: paymentIntent.client_secret
    });

  } catch (err) {
    res.status(500).json({
      message: err.message
    });
  }
};
exports.releasePayment = async (req, res) => {
  try {
    const { projectId } = req.body;

    const project = await Project.findById(projectId)
      .populate("acceptedFreelancer");

    if (!project) {
      return res.status(404).json({ message: "Projet non trouvé" });
    }

    if (!project.acceptedFreelancer) {
      return res.status(400).json({ message: "Freelancer manquant" });
    }

    // ❌ prevent double payment
    if (project.escrowStatus === "released") {
      return res.status(400).json({
        message: "Paiement déjà libéré"
      });
    }

    const freelancerId = project.acceptedFreelancer._id;

    // 💸 wallet update
    await User.findByIdAndUpdate(
      freelancerId,
      { $inc: { walletBalance: project.budget } }
    );

    // 🔓 update project
    project.escrowStatus = "released";
    project.status = "completed";
    project.paymentStatus = "released";

    await project.save();

    // 🔔 socket notification
    const io = req.app.get("socketio");

    if (io) {
      io.to(freelancerId.toString()).emit("notification", {
        title: "Paiement reçu 💸",
        message: "Escrow libéré par le client",
        projectId: project._id,
      });
    }

    return res.json({
      message: "Paiement libéré avec succès",
      project,
    });

  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: err.message });
  }
};