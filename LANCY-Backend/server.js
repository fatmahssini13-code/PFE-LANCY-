const express = require("express");
const cors = require("cors");
const http = require("http"); // Indispensable pour Socket.io
require("dotenv").config();
const { Server } = require('socket.io');

const connectDB = require("./config/db");
const Message = require('./models/message');
const Project = require("./models/project");
// Initialisation de l'application
const app = express();
const server = http.createServer(app); // On crée le serveur à partir de app
const io = new Server(server, {
    cors: { origin: "*" } 
});
app.set('io', io);
// 1. MIDDLEWARES
app.use(cors());
app.use(express.json());
// ✅ import simple
const notificationRoutes = require("./routes/notificationRoutes");
app.use("/api/notifications", notificationRoutes);

// 2. LOGIQUE SOCKET.IO (MESSENGER)
// ... (haut du fichier inchangé jusqu'à app.set)

// 2. LOGIQUE SOCKET.IO (MESSENGER & NOTIFICATIONS)
io.on('connection', (socket) => {
    console.log('Client connecté:', socket.id);

    // L'utilisateur rejoint sa room dès qu'il se connecte
    socket.on('join', (userId) => {
        if (userId) {
            socket.join(userId);
            console.log(`✅ Utilisateur ${userId} a rejoint sa room de notifications`);
        }
    });

    // Gestion des messages (Messenger)
socket.on('send_message', async (data) => {
    const { senderId, receiverId, text, projectId } = data;

    try {
        const newMessage = new Message({
            senderId,
            receiverId,
            projectId,
            text,
        });

        await newMessage.save();

        // ✔ ENVOI PROPRE SOCKET
        const msg = {
            _id: newMessage._id,
            senderId,
            receiverId,
            projectId,
            text,
            createdAt: newMessage.createdAt
        };

        io.to(receiverId).emit("receive_message", msg);
        io.to(senderId).emit("receive_message", msg); // sync sender aussi
io.to(receiverId).emit("notification", {
    title: "Nouveau message",
    message: text,
    projectId,
    senderId
});
    } catch (err) {
        console.error("Erreur envoi message:", err);
    }
});
    // UN SEUL disconnect, et BIEN PLACÉ à l'intérieur du bloc connection
    socket.on('disconnect', () => {
        console.log('Client déconnecté ❌');
    });
}); // <--- La fermeture correcte de io.on est ici

// 3. IMPORTATION DES ROUTES
// ... (le reste de ton code est correct)


// 3. IMPORTATION DES ROUTES
const authRoutes = require("./routes/authRoutes");
const userRoutes = require("./routes/userroutes");
const adminRoutes = require('./routes/admin');
const projectsRoutes = require("./routes/projectsRoutes");
const proposalRoutes = require("./routes/proposalRoutes");
app.use("/api/proposals", proposalRoutes);
const messageRoutes = require("./routes/messageRoutes");

app.use("/api/messages", messageRoutes);
// 4. DÉFINITION DES ROUTES API
app.get("/ping", (req, res) => {
    res.json({ message: "pong" });
});

app.use("/api/auth", authRoutes);
app.use("/api/users", userRoutes);
app.use("/api/admin", adminRoutes);
app.use("/api/projects", projectsRoutes);
app.use("/uploads", express.static("uploads"));

 app.use("/api/auth", (req,res,next)=>{
  console.log("AUTH ROUTE HIT:", req.url);
  next();
}, authRoutes);
// 5. CONNEXION DB ET LANCEMENT UNIQUE
const PORT = Number(process.env.PORT) || 5001;
const MY_IP = "192.168.100.13"; 
//const MY_IP = "192.168.1.100"; 
const paymentRoutes = require("./routes/paymentRoutes");
app.use("/api/payment", paymentRoutes);

connectDB()
    .then(() => {
        // IMPORTANT : Utiliser server.listen et non app.listen pour que Socket.io fonctionne
        server.listen(PORT, "0.0.0.0", () => {
            console.log(`✅ Serveur Lancy connecté à MongoDB`);
            console.log(`: http://${MY_IP}:${PORT}`);
        });
    })
    .catch((err) => {
        console.error("❌ Erreur de connexion MongoDB :", err);
    });