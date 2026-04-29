const mongoose = require('mongoose');

const projectSchema = new mongoose.Schema({
  title: { type: String, required: true },
  description: { type: String, required: true },
  budget: { type: Number, required: true },
  owner: { // Assure-toi que c'est bien 'owner' ici
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  status: { 
    type: String, 
    enum: ["open", "in_progress", "completed", "cancelled"], 
    default: "open" 
  },
  paymentStatus: { 
    type: String, 
    enum: ["unpaid", "escrow_locked", "released", "refunded"], 
    default: "unpaid" 
  },
  selectedProposal: { type: mongoose.Schema.Types.ObjectId, ref: "Proposal" }
}, { timestamps: true });



module.exports = mongoose.models.Project || mongoose.model('Project', projectSchema);