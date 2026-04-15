const jwt = require("jsonwebtoken");
const User = require("../models/User");

exports.requireAuth = async (req, res, next) => {
  try {
    const header = req.headers.authorization;

    if (!header) {
      return res.status(401).json({ message: "No token" });
    }

    const [type, token] = header.split(" ");

    if (type !== "Bearer" || !token) {
      return res.status(401).json({ message: "Bad token format" });
    }

    // 1. Vérification du token avec la clé secrète
    // Utilise une valeur par défaut si ton .env n'est pas chargé
    const decoded = jwt.verify(token, process.env.JWT_SECRET || "SECRET_KEY");

    console.log("✅ DECODED TOKEN:", decoded);

    // 2. Trouver l'utilisateur (on cherche par ID ou par Email pour être sûr)
    // On met cette logique BIEN À L'INTÉRIEUR du try
    const user = await User.findById(decoded.id).select("-password") 
                 || await User.findOne({ email: decoded.email }).select("-password");

    if (!user) {
      console.log("❌ Utilisateur introuvable en base pour:", decoded);
      return res.status(401).json({ message: "User not found" });
    }

    // 3. On attache l'utilisateur à la requête pour que la route 'add project' puisse l'utiliser
    req.user = user;

    next();
  } catch (err) {
    console.log("❌ ERROR JWT:", err.message);
    return res.status(401).json({
      message: "Token invalid",
      error: err.message,
    });
  }
};