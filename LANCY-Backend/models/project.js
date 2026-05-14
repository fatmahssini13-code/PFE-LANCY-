const mongoose = require('mongoose');

const projectSchema = new mongoose.Schema({
  title: { type: String, required: true },
  description: { type: String, required: true },
  budget: { type: Number, required: true },

  owner: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },

  status: {
    type: String,
    enum: ["open", "in_progress", "delivered", "completed", "cancelled", "disputed"],
    default: "open"
  },

  dispute: {
    isOpen: { type: Boolean, default: false },
    reason: { type: String, default: '' },
    openedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    openedAt: Date
  },

  paymentStatus: {
    type: String,
    enum: ["not_locked", "escrow_locked", "released", "refunded"],
    default: "not_locked"
  },

  escrowStatus: {
    type: String,
    enum: ["not_locked", "locked", "released", "refunded"],
    default: "locked"
  },

  delivery: {
    message: { type: String, default: "" },
    file: { type: String, default: "" },
    link: { type: String, default: "" },

    status: {
      type: String,
      enum: ["pending", "delivered", "accepted", "refused"],
      default: "pending"
    }
  },

  escrowAmount: { type: Number, default: 0 }
}, { timestamps: true });
module.exports = mongoose.models.Project || mongoose.model("Project", projectSchema);