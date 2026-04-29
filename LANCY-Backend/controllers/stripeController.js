const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const Project = require('../models/Project');

exports.processPayment = async (req, res) => {
  try {
    const { projectId } = req.body;
    const project = await Project.findById(projectId);

    if (!project) return res.status(404).json({ message: "Projet non trouvé" });

    // Création de l'intention de paiement
    const paymentIntent = await stripe.paymentIntents.create({
      amount: project.budget * 1000, // Conversion en millimes (pour TND) ou centimes
      currency: 'tnd',
      metadata: { projectId: project._id.toString() },
      automatic_payment_methods: { enabled: true },
    });

    // On met à jour le statut du projet en attendant la confirmation
    project.escrowStatus = 'pending_payment';
    await project.save();

    res.json({ clientSecret: paymentIntent.client_secret });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Confirmation après succès sur Flutter
exports.confirmPayment = async (req, res) => {
  try {
    const { projectId } = req.body;
    await Project.findByIdAndUpdate(projectId, { 
        escrowStatus: 'locked',
        status: 'in_progress' 
    });
    res.json({ message: "Fonds bloqués en Escrow avec succès 🔒" });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};