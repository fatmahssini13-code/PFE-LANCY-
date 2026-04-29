const express = require('express');
const router = express.Router();
const User = require('../models/User'); 
const Project = require('../models/Project');

const escrowController = require('../controllers/escrowController');
const userController = require('../controllers/usercontroller');
const projectController = require('../controllers/projectController');
const adminController = require('../controllers/adminController');
// --- ROUTE 1 : OBTENIR LES STATISTIQUES (Pour le Dashboard) ---
// Accessible via : GET /api/admin/stats
const { requireAuth, isAdmin } = require('../middleware/authMiddleware');
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
router.get('/users', userController.getAllUsers);
router.delete('/users/:id', userController.deleteUser);

// --- ROUTE 3 : GESTION DES PROJETS ---
router.get('/projects', projectController.getAllProjectsAdmin);

// --- ROUTE 4 : ACTIONS ESCROW (Nouveau !) ---
// Ces routes correspondent aux actions du site Angular
router.get('/escrow-projects', escrowController.getEscrowProjects);
router.post('/release-funds', escrowController.releaseFunds);
router.post('/refund-client', escrowController.refundClient);
module.exports = router;
module.exports = router;