const express = require("express");
const cors = require("cors");
const http = require("http");
require("dotenv").config();

const app = express();
const server = http.createServer(app);

const { Server } = require("socket.io");
const io = new Server(server, { cors: { origin: "*" } });

const connectDB = require("./config/db");
const Message = require("./models/message");
const Project = require("./models/project");
const User = require("./models/User");
const stripe = require("./config/stripe");

app.set("socketio", io);

// ================= MIDDLEWARE =================
app.use(cors());

// IMPORTANT: webhook MUST be before express.json()
app.post(
  "/webhook",
  express.raw({ type: "application/json" }),
  async (req, res) => {
    const sig = req.headers["stripe-signature"];

    let event;

    try {
      event = stripe.webhooks.constructEvent(
        req.body,
        sig,
        process.env.STRIPE_WEBHOOK_SECRET
      );
    } catch (err) {
      console.log("❌ webhook error:", err.message);
      return res.sendStatus(400);
    }

    // ================= ESCROW + WALLET TOP-UP =================
    if (event.type === "payment_intent.succeeded") {
      const paymentIntent = event.data.object;
      const meta = paymentIntent.metadata || {};

      if (meta.purpose === "wallet_topup" && meta.userId) {
        const piId = paymentIntent.id;
        const cents =
          paymentIntent.amount_received != null
            ? paymentIntent.amount_received
            : paymentIntent.amount;
        const euros = cents / 100;
        const up = await User.updateOne(
          {
            _id: meta.userId,
            processedWalletTopUpIntentIds: { $nin: [piId] }
          },
          {
            $inc: { walletBalance: euros },
            $push: { processedWalletTopUpIntentIds: piId }
          }
        );
        if (up.modifiedCount > 0) {
          console.log("💰 Wallet rechargé (webhook):", meta.userId, euros, "EUR");
        }
        return res.json({ received: true });
      }

      const projectId = meta.projectId;
      if (!projectId) {
        return res.json({ received: true });
      }

      const project = await Project.findById(projectId);

      if (project) {
       project.paymentStatus = "escrow_locked";
       project.escrowStatus = "locked";
       project.status = "in_progress";
        await project.save();

        console.log("🔒 ESCROW LOCKED:", projectId);

        if (project.acceptedFreelancer) {
          io.to(project.acceptedFreelancer.toString()).emit("notification", {
            title: "Mission démarrée 🚀",
            message: "Paiement confirmé - escrow locked",
            projectId: project._id,
          });
        }
      }
    }

    res.json({ received: true });
  }
);

// AFTER webhook ONLY
app.use(express.json());
app.use("/uploads", express.static("uploads"));

// Clé publique Stripe : même compte que STRIPE_SECRET_KEY (évite mismatch app mobile).
app.get("/api/config/stripe-publishable-key", (req, res) => {
  const pk = process.env.STRIPE_PUBLISHABLE_KEY;
  if (!pk || !String(pk).startsWith("pk_")) {
    return res.status(500).json({ error: "STRIPE_PUBLISHABLE_KEY manquante ou invalide" });
  }
  res.json({ publishableKey: String(pk).trim() });
});

// ================= ROUTES =================
app.use("/api/auth", require("./routes/authRoutes"));
app.use("/api/users", require("./routes/userroutes"));

app.use("/api/projects", require("./routes/projectsRoutes"));
app.use("/api/proposals", require("./routes/proposalRoutes"));
app.use("/api/messages", require("./routes/messageRoutes"));
app.use("/api/payment", require("./routes/paymentRoutes"));

app.use("/api/admin", require("./routes/admin"));
const escrowRoutes = require("./routes/escrowRoutes");
app.use("/api/admin/escrow", escrowRoutes);
app.get("/ping", (req, res) => res.json({ ok: true }));

// ================= SOCKET =================
io.on("connection", (socket) => {
  console.log("socket connected:", socket.id);

  socket.on("join", (userId) => {
    socket.join(String(userId));
  });
});
console.log("MAIN SERVER LOADED");
// ================= START =================
const PORT = process.env.PORT || 5000;

connectDB()
  .then(() => {
    server.listen(PORT, () =>
      console.log(`🚀 server running on port ${PORT}`)
    );
  })

  .catch((err) => console.log(err));