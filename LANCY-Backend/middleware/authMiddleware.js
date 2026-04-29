const jwt = require("jsonwebtoken");
const User = require("../models/User");

const requireAuth = async (req, res, next) => {
  try {
    const header = req.headers.authorization;

    if (!header) return res.status(401).json({ message: "No token" });

    const [type, token] = header.split(" ");

    if (type !== "Bearer" || !token) {
      return res.status(401).json({ message: "Bad token format" });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET || "SECRET_KEY");

    const user = await User.findById(decoded.id);

    if (!user) {
      return res.status(401).json({ message: "User not found" });
    }

    req.user = user;
    next();
  } catch (err) {
    return res.status(401).json({ message: "Invalid token" });
  }
};
const isAdmin = (req, res, next) => {
  // On vérifie si req.user existe (rempli par requireAuth) et si son rôle est admin
  if (req.user && req.user.role === 'admin') {
    next(); // L'utilisateur est admin, on passe à la suite
  } else {
    // Si l'utilisateur n'est pas admin, on bloque l'accès
    res.status(403).json({ message: "Accès refusé : Privilèges administrateur requis." });
  }
};
module.exports = { requireAuth };