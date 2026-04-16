const express = require("express");
const cors = require("cors");
const http = require("http"); // Indispensable pour Socket.io
require("dotenv").config();
const { Server } = require('socket.io');

const connectDB = require("./config/db");
const Message = require('./models/message');

// Initialisation de l'application
const app = express();
const server = http.createServer(app); // On crée le serveur à partir de app
const io = new Server(server, {
    cors: { origin: "*" } 
});

// 1. MIDDLEWARES
app.use(cors());
app.use(express.json());

// 2. LOGIQUE SOCKET.IO (MESSENGER)
io.on('connection', (socket) => {
    console.log('Utilisateur connecté au socket:', socket.id);

    socket.on('join', (userId) => {
        socket.join(userId);
        console.log(`Utilisateur ${userId} a rejoint sa room`);
    });

    socket.on('send_message', async (data) => {
        const { senderId, receiverId, message } = data;
        try {
            // Sauvegarde dans MongoDB
            const newMessage = new Message({ senderId, receiverId, message });
            await newMessage.save();

            // Envoi au destinataire
            io.to(receiverId).emit('receive_message', {
                senderId,
                message,
                timestamp: newMessage.timestamp
            });
        } catch (err) {
            console.error("Erreur envoi message:", err);
        }
    });

    socket.on('disconnect', () => {
        console.log('Utilisateur déconnecté');
    });
});

// 3. IMPORTATION DES ROUTES
const authRoutes = require("./routes/authRoutes");
const userRoutes = require("./routes/userroutes");
const adminRoutes = require('./routes/admin');
const projectsRoutes = require("./routes/projectsRoutes");

// 4. DÉFINITION DES ROUTES API
app.get("/ping", (req, res) => {
    res.json({ message: "pong" });
});

app.use("/api/auth", authRoutes);
app.use("/api/users", userRoutes);
app.use("/api/admin", adminRoutes);
app.use("/api/projects", projectsRoutes);

// 5. CONNEXION DB ET LANCEMENT UNIQUE
const PORT = 5000;
const MY_IP = "192.168.100.13"; 

connectDB()
    .then(() => {
        // IMPORTANT : Utiliser server.listen et non app.listen pour que Socket.io fonctionne
        server.listen(PORT, "0.0.0.0", () => {
            console.log(`✅ Serveur Lancy connecté à MongoDB`);
            console.log(`🚀 API et Messenger : http://${MY_IP}:${PORT}`);
        });
    })
    .catch((err) => {
        console.error("❌ Erreur de connexion MongoDB :", err);
    });