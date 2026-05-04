const stripe = require("../config/stripe");
const Project = require("../models/project");

// 🟢 CREATE PAYMENT INTENT
exports.createPaymentIntent = async (req, res) => {
try {
    const { projectId } = req.body;
    const project = await Project.findById(projectId);

    if (!project) return res.status(404).json({ message: "Projet non trouvé" });

    // Vérification de sécurité pour éviter le crash .toString()
    const freelancerId = project.acceptedFreelancer ? project.acceptedFreelancer.toString() : "aucun";

    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(project.budget * 100), // Force un nombre entier
      currency: "usd",
      metadata: {
        projectId: project._id.toString(),
        freelancerId: freelancerId,
      },
      automatic_payment_methods: { enabled: true },
    });

    res.json({ clientSecret: paymentIntent.client_secret });
}catch (error) {
    console.log("------ ❌ L'ERREUR EST ICI ------");
  console.error(error); 
  console.log("---------------------------------");
    res.status(500).json({ error: error.message });
  }
};
exports.releasePayment = async (req, res) => {
  try {
    const { projectId } = req.body;
    const project = await Project.findById(projectId);

    if (!project || !project.stripeAccountId) {
        return res.status(400).json({ message: "Freelancer non connecté à Stripe" });
    }

    const transfer = await stripe.transfers.create({
      amount: Math.round(project.budget * 100), // Sécurité arrondi
      currency: "usd",
      destination: project.stripeAccountId,
    });

    project.escrowStatus = "released";
    project.status = "completed";
    await project.save();

    res.json({ message: "Paiement transféré ✅", transfer });
  } catch (err) { // <--- Changé 'error' en 'err'
    console.error(err); 
    res.status(500).json({ error: err.message });
  }
};