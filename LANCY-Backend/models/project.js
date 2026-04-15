const mongoose = require("mongoose");

const projectSchema = new mongoose.Schema(
  {
    title: String,
    description: String,
    budget: Number,
    clientId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
    },
    status: {
      type: String,
      default: "open",
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model("Project", projectSchema);