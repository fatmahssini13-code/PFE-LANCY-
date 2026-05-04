const express = require("express");
const router = express.Router();
const paymentController = require("../controllers/paymentController");

router.post("/create-intent", paymentController.createPaymentIntent);
router.post("/release", paymentController.releasePayment);

module.exports = router;