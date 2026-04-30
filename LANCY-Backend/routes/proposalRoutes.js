const express = require("express");
const router = express.Router();

const {
  createProposal,
  getProjectProposals,
  acceptProposal,
  rejectProposal,
} = require("../controllers/proposalController");

const { requireAuth } = require("../middleware/authMiddleware");

router.post("/", requireAuth, createProposal);
router.get("/project/:id", requireAuth, getProjectProposals);
router.put("/:id/accept", requireAuth, acceptProposal);
router.put("/:id/reject", requireAuth, rejectProposal);
module.exports = router;