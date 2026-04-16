const express = require("express");
const cors = require("cors");
require("dotenv").config();
const connectDB = require("./config/db");

const app = express();

// 1. MIDDLEWARES
app.use(cors());
app.use(express.json()); 

// 2. IMPORTATION DES ROUTES (On déclare les variables ici)
const authRoutes = require("./routes/authRoutes");
const userRoutes = require("./routes/userroutes");
const adminRoutes = require('./routes/admin');
const projectsRoutes = require("./routes/projectsRoutes"); // <--- CORRECTION : Il manquait cet import !

// 3. ROUTES DE TEST
app.get("/ping", (req, res) => {
    res.json({ message: "pong" });
});

// 4. DÉFINITION DES PRÉFIXES API (On les regroupe tous ici)
app.use("/auth", authRoutes);

app.use("/api/auth", authRoutes);
app.use("/api/users", userRoutes);
app.use("/api/admin", adminRoutes);
app.use("/api/projects", projectsRoutes);
 // <--- Déplacé ici pour plus de clarté

// 5. CONNEXION DB ET LANCEMENT
// 5001 par défaut : sur macOS le port 5000 est souvent pris par AirPlay (réponses non-JSON → erreur côté app).
const PORT = Number(process.env.PORT) || 5001;
const MY_IP = "192.168.100.13";

connectDB()
  .then(() => {
    app.listen(PORT, "0.0.0.0", () => {
      console.log(`✅Serveur Lancy connecté à MongoDB`);
      console.log(` URL pour Flutter : http://${MY_IP}:${PORT}`);
    });
  })
  .catch((err) => {
    console.error("Erreur de connexion MongoDB :", err);
  });