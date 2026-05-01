const express = require("express");
const cors = require("cors");
const http = require("http"); // Indispensable pour Socket.io
require("dotenv").config();
const { Server } = require('socket.io');
const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
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

function strId(v) {
  if (v === undefined || v === null) return "";
  return typeof v === "string" ? v : String(v);
}

function chatRoom(projectId) {
  return `chat:${strId(projectId)}`;
}

io.on('connection', (socket) => {
    console.log('Client connecté:', socket.id);

    socket.on('join', (userId) => {
        const id = strId(userId);
        if (id) {
            socket.join(id);
            console.log(`✅ Room utilisateur ${id} (notif / ciblage)`);
        }
    });

    /** Les deux interlocuteurs rejoignent cette room pendant l’écran chat. */
    socket.on('join_project_chat', (payload = {}) => {
        const userId = strId(payload.userId);
        const projectId = strId(payload.projectId);
        if (!projectId) return;
        socket.join(chatRoom(projectId));
        if (userId) socket.join(userId);
        console.log(`✅ Room chat ${chatRoom(projectId)} user=${userId || "?"}`);
    });

    socket.on('leave_project_chat', (payload = {}) => {
        const projectId = strId(payload.projectId);
        if (!projectId) return;
        socket.leave(chatRoom(projectId));
    });

    socket.on('send_message', async (data = {}) => {
        const senderId = strId(data.senderId);
        const receiverId = strId(data.receiverId);
        const projectId = strId(data.projectId);
        const text = typeof data.text === "string" ? data.text.trim() : "";

        if (!senderId || !receiverId || !projectId || !text) {
            socket.emit("message_error", { message: "Données invalides" });
            return;
        }

        /** même room utilisée pour le broadcast — garantit avant DB que cet émetteur reçoit l’écho. */
        const room = chatRoom(projectId);
        socket.join(room);

        try {
            const project = await Project.findById(projectId).lean();
            if (!project || !project.acceptedFreelancer) {
                socket.emit("message_error", {
                    message: "Chat non autorisé pour ce projet",
                });
                return;
            }

            const ownerStr = strId(project.owner);
            const freeStr = strId(project.acceptedFreelancer);
            const allowed = new Set([ownerStr, freeStr]);

            if (
                !allowed.has(senderId) ||
                !allowed.has(receiverId) ||
                senderId === receiverId
            ) {
                socket.emit("message_error", {
                    message: "Interlocuteurs invalides pour ce projet",
                });
                return;
            }

            const newMessage = await Message.create({
                senderId,
                receiverId,
                projectId,
                text,
            });

            const msg = {
                _id: strId(newMessage._id),
                senderId,
                receiverId,
                projectId,
                text,
                createdAt: newMessage.createdAt,
            };

            /**
             * Tous les clients dans cette mission (dont l’expéditeur désormais join).
             * + émission directe sur ce socket au cas où (latence join vs broadcast rare).
             */
            io.to(room).emit("receive_message", msg);
            socket.emit("receive_message", msg);

            io.to(receiverId).emit("notification", {
                title: "Nouveau message",
                message: text.length > 80 ? `${text.slice(0, 80)}…` : text,
                projectId,
                senderId,
            });
        } catch (err) {
            console.error("Erreur envoi message:", err);
            socket.emit("message_error", {
                message: err.message || "Erreur serveur",
            });
        }
    });

    socket.on('disconnect', () => {
        console.log('Client déconnecté ❌');
    });
});

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

app.post("/chat", async (req, res) => {
  const message = req.body.message;

  if (!message) {
    return res.status(400).json({ error: "message required" });
  }

  try {
    const response = await axios.post(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${GEMINI_API_KEY}`,
      {
        contents: [
          {
            parts: [{ text: message }]
          }
        ]
      }
    );

    const reply =
      response.data.candidates?.[0]?.content?.parts?.[0]?.text ||
      "no response";

    res.json({ reply });

  } catch (error) {
    res.status(500).json({
      error: error.message
    });
  }
});
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