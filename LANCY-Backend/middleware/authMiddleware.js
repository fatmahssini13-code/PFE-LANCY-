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

module.exports = { requireAuth };