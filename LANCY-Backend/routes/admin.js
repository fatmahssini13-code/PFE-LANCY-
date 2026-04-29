const express = require('express');
const router = express.Router();
const User = require('../models/User'); // Pour les statistiques
const userController = require('../controllers/usercontroller'); // Pour la liste complète
const projectController = require('../controllers/projectController');
// --- ROUTE 1 : OBTENIR LES STATISTIQUES (Pour le Dashboard) ---
// Accessible via : GET /api/admin/stats
router.get('/stats', async (req, res) => {
  try {
    const totalUsers = await User.countDocuments();
    const freelancers = await User.countDocuments({ role: 'freelance' });
    const clients = await User.countDocuments({ role: 'client' });

    res.json({
      users: totalUsers,
      freelancers,
      clients
    });
  } catch (error) {
    res.status(500).json({ message: "Erreur lors du calcul des stats", error });
  }
});

// --- ROUTE 2 : OBTENIR TOUS LES UTILISATEURS (Pour la partie Utilisateurs) ---
// Accessible via : GET /api/admin/users
router.get('/projects', projectController.getAllProjectsAdmin);
router.get('/users', userController.getAllUsers);
router.delete('/users/:id', userController.deleteUser);
module.exports = router;