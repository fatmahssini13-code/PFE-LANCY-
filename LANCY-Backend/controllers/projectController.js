const Project = require("../models/project");
const Proposal = require("../models/proposal");
const User = require("../models/user");

// --- 1. CRÉER UN PROJET (C'est ici que l'erreur se produisait) ---
exports.createProject = async (req, res) => {
  try {
    const { title, description, budget, clientEmail } = req.body;

    // Log pour débogage (à voir dans ton terminal VS Code)
    console.log("------------------------------------");
    console.log("📥 Requête reçue pour :", clientEmail);

    // 1. Chercher l'utilisateur par l'email envoyé par Flutter
    const user = await User.findOne({ email: clientEmail });

    if (!user) {
      console.log("❌ Utilisateur non trouvé en base.");
      return res.status(404).json({ message: "Utilisateur non trouvé" });
    }

    // 2. Créer le projet avec l'ID de l'utilisateur trouvé
    const newProject = new Project({
      title: title,
      description: description,
      budget: Number(budget),
      owner: user._id // <--- Attribution de l'ID à 'owner'
    });

    // 3. Sauvegarder dans MongoDB
    await newProject.save();
    console.log("✅ Projet créé avec succès !");
    console.log("------------------------------------");

    res.status(201).json(newProject);
  } catch (error) {
    console.log("🔥 Erreur lors de la création :", error.message);
    res.status(500).json({ message: "Erreur serveur", error: error.message });
  }
};
exports.getAllProjects = async (req, res) => {
  try {
    // On récupère TOUS les projets et on remplit les infos du client (owner)
    const projects = await Project.find().populate("owner", "name email");
    console.log(`🔍 ${projects.length} projets envoyés au freelancer`);
    res.json(projects);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// --- 2. RÉCUPÉRER TOUS LES PROJETS (Admin ou Freelancer) ---
exports.getProjects = async (req, res) => {
  try {
    const projects = await Project.find()
      .populate("owner", "name avatar email")
      .sort({ createdAt: -1 });

    let enriched = projects.map((p) => p.toObject());

    if (req.user) {
      const ids = enriched.map((p) => p._id);
      const mine = await Proposal.find({
        freelancer: req.user._id,
        project: { $in: ids },
      })
        .select("project status")
        .lean();

      const statusByProject = {};
      for (const row of mine) {
        statusByProject[row.project.toString()] = row.status;
      }

      enriched = enriched.map((p) => ({
        ...p,
        userProposalStatus: statusByProject[p._id.toString()] || "none",
      }));
    } else {
      enriched = enriched.map((p) => ({
        ...p,
        userProposalStatus: "none",
      }));
    }

    res.status(200).json(enriched);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// --- 3. RÉCUPÉRER TOUS LES PROJETS (Dashboard Admin spécifique) ---
exports.getAllProjectsAdmin = async (req, res) => {
  try {
    const projects = await Project.find()
      .populate('owner', 'name avatar')
      .sort({ createdAt: -1 });
    
    res.status(200).json(projects);
  } catch (err) {
    res.status(500).json({ message: "Erreur récupération admin", error: err.message });
  }
};

// --- 4. MODIFIER UN PROJET ---
exports.updateProject = async (req, res) => {
  try {
    const { id } = req.params;
    const project = await Project.findByIdAndUpdate(id, req.body, { new: true });

    if (!project) return res.status(404).json({ message: "Projet non trouvé" });

    res.status(200).json({ message: "Projet modifié avec succès", project });
  } catch (error) {
    res.status(500).json({ message: "Erreur modification", error });
  }
};

// --- 5. SUPPRIMER UN PROJET ---
exports.deleteProject = async (req, res) => {
  try {
    const { id } = req.params;
    const project = await Project.findByIdAndDelete(id);

    if (!project) return res.status(404).json({ message: "Projet non trouvé" });

    res.status(200).json({ message: "Projet supprimé avec succès" });
  } catch (error) {
    res.status(500).json({ message: "Erreur suppression", error });
  }
};
exports.deliverProject = async (req, res) => {
  const project = await Project.findById(req.params.id);

  project.status = "delivered";
  project.delivery = {
    message: req.body.message,
    file: req.body.file
  };

  await project.save();

  res.json({ message: "Travail livré ✅" });
};
// Dans ton controller Node.js (projectController.js)
const addProject = async (req, res) => {
    try {
        const { title, description, budget, clientEmail } = req.body;
        
        // DEBUG : Ajoute cette ligne pour voir ce que Node reçoit
        console.log("RECU DU FRONT:", req.body);

        const user = await User.findOne({ email: clientEmail });
        
        if (!user) {
            return res.status(404).json({ message: "Utilisateur non trouvé" });
        }

        const newProject = new Project({
            title,
            description,
            budget,
            owner: user._id // <--- Si user est null, ça plante ici !
        });

        await newProject.save();
        res.status(201).json(newProject);
    } catch (error) {
        console.error("ERREUR:", error.message);
        res.status(500).json({ message: "Erreur serveur", error: error.message });
    }
};
// --- 6. APPROUVER ET LIBÉRER LES FONDS (Action Client) ---
exports.approveAndReleaseFunds = async (req, res) => {
  try {
    const { id } = req.params;
    const project = await Project.findById(id);

    if (!project) return res.status(404).json({ message: "Projet non trouvé" });

    // Sécurité : Seul le propriétaire (owner) peut approuver
    // if (project.owner.toString() !== req.user._id.toString()) {
    //   return res.status(403).json({ message: "Non autorisé" });
    // }

    project.status = "completed";
    project.paymentStatus = "released";
    
    await project.save();

    console.log(`✅ Fonds libérés pour le projet : ${project.title}`);
    res.status(200).json({ message: "Paiement libéré au freelance avec succès !", project });
  } catch (error) {
    res.status(500).json({ message: "Erreur lors de la libération des fonds", error: error.message });
  }
};
// --- 7. ACTIONS ADMIN (Litige) ---
exports.adminReleaseOrRefund = async (req, res) => {
  try {
    const { id } = req.params;
    const { action } = req.body; // 'release' ou 'refund'

    const project = await Project.findById(id);
    if (!project) return res.status(404).json({ message: "Projet non trouvé" });

    if (action === "release") {
      project.status = "completed";
      project.paymentStatus = "released";
    } else if (action === "refund") {
      project.status = "cancelled";
      project.paymentStatus = "refunded";
    }

    await project.save();
    res.status(200).json({ message: `Action Admin : ${action} effectuée`, project });
  } catch (error) {
    res.status(500).json({ message: "Erreur Admin", error: error.message });
  }
};