const express = require("express");
const router = express.Router();
const { releasePayment } = require("../controllers/paymentController");
const { requireAuth } = require("../middleware/authMiddleware");

router.put("/:id/release", requireAuth, releasePayment);

module.exports = router;