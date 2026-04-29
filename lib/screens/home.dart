import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfe/screens/ProfileScreen.dart';
import 'package:pfe/screens/chat_screen.dart';
import 'package:pfe/screens/notifications_screen.dart';
import 'package:pfe/screens/proposals_list_screen.dart';
import 'package:pfe/screens/send_proposal_screen.dart';
import 'package:pfe/service/home_service.dart';
import 'package:pfe/service/auth_service.dart';
import 'package:pfe/service/project_service.dart'; // Assure-toi que ce fichier contient update et delete
import 'package:socket_io_client/socket_io_client.dart' as IO;

class HomeScreen extends StatefulWidget {
  final String email;
  final String role;
  final String? name;

  const HomeScreen({
    super.key,
    required this.email,
    required this.role,
    this.name,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeService homeService = HomeService();
  final Color skyBlue = const Color(0xFF74C0FC);
  final Color lancyPurple = const Color(0xFF8E2DE2);
  int _refresh =
      0; // Variable utilisée pour forcer le rafraîchissement du FutureBuilder
  IO.Socket? socket;
  bool hasNotification = false;
  List<Map<String, dynamic>> notificationHistory = [];
//socket ??= IO.io('http://192.168.1.100:5001', <String, dynamic>
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectSocket();
    });
  }
  // Déclare le socket en dehors pour qu'il soit persistant

  void _connectSocket() {
  // On initialise le socket s'il est null
  socket ??= IO.io('http://192.168.100.13:5001', <String, dynamic>
  {
    'transports': ['websocket'],
    'autoConnect': true,
    'forceNew': false, // Très important pour garder la même session
  });

  // À chaque reconnexion, on rejoint la room IMMÉDIATEMENT
  socket!.onConnect((_) {
    print('✅ Connexion établie');
    socket!.emit('join', widget.email.trim().toLowerCase());
  });

  // On s'assure qu'on n'a pas de doublons d'écouteurs
  socket!.off('notification'); 

  socket!.on('notification', (data) {
    print('🔔 SIGNAL REÇU !');
    if (mounted) {
      setState(() {
        hasNotification = true;
        notificationHistory.insert(0, Map<String, dynamic>.from(data));
      });
      Get.snackbar(
        data['title'] ?? "Nouveau",
        data['message'] ?? "Proposition reçue",
        backgroundColor: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  });

  // Force la connexion si elle n'est pas active
  if (!socket!.connected) {
    socket!.connect();
  }
}

  @override
  void dispose() {
    socket?.off('notification');
    socket?.disconnect();
    socket?.dispose();
    super.dispose();
  }

  // ... reste de ton code ...
  String get _emailNorm => widget.email.trim().toLowerCase();

  // --- RÉCUPÉRATION DES DONNÉES ---
  Future<List<dynamic>> _getProjects(bool isClient) async {
    final token = await AuthService.getToken();
    if (token == null) return [];
    // Si client, on récupère ses propres projets, sinon tous les projets (freelancer)
    return isClient
        ? homeService.fetchMyProjects(token)
        : homeService.fetchProjects();
  }

  // --- ACTION : SUPPRESSION ---
  void _confirmDeletion(String projectId) {
    Get.defaultDialog(
      title: "Suppression",
      middleText: "Voulez-vous vraiment supprimer ce projet ?",
      textConfirm: "Supprimer",
      textCancel: "Annuler",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        try {
          await ProjectService.deleteProject(projectId);
          Get.back(); // Fermer le dialogue
          setState(() => _refresh++); // Rafraîchir la liste
          Get.snackbar(
            "Succès",
            "Projet supprimé",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.white,
          );
        } catch (e) {
          Get.snackbar("Erreur", "Impossible de supprimer le projet");
        }
      },
    );
  }

  // --- ACTION : MODIFICATION ---
  void _showEditProjectDialog(BuildContext context, dynamic item) {
    final title = TextEditingController(text: item["title"]);
    final desc = TextEditingController(text: item["description"]);
    final budget = TextEditingController(text: item["budget"].toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Modifier la Mission",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogField(title, "Titre du projet", Icons.title),
              const SizedBox(height: 12),
              _buildDialogField(
                desc,
                "Description",
                Icons.description,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              _buildDialogField(
                budget,
                "Budget (DT)",
                Icons.monetization_on,
                isNumber: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: skyBlue,
              shape: const StadiumBorder(),
            ),
            onPressed: () async {
              try {
                await ProjectService.updateProject(item["_id"], {
                  "title": title.text,
                  "description": desc.text,
                  "budget": budget.text,
                });
                Navigator.pop(context);
                setState(() => _refresh++);
                Get.snackbar("Succès", "Projet mis à jour");
              } catch (e) {
                Get.snackbar("Erreur", "Échec de la mise à jour");
              }
            },
            child: const Text(
              "Enregistrer",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isClient = widget.role.toLowerCase() == "client";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          "LANCY",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                onPressed: () {
                  setState(() => hasNotification = false);
                  // --- Redirection vers la page de liste ---
               Get.to(() => NotificationsScreen(

));
                },
                icon: const Icon(Icons.notifications_none_outlined, size: 28),
              ),
              if (hasNotification)
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            onPressed: () => Get.to(() => ProfileScreen(email: widget.email)),
            icon: CircleAvatar(
              backgroundColor: skyBlue.withOpacity(0.2),
              child: const Icon(Icons.person, color: Colors.blue),
            ),
          ),
        ],
      ),
      floatingActionButton: isClient
          ? FloatingActionButton.extended(
              backgroundColor: lancyPurple,
              onPressed: () => _showAddProjectDialog(context),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                "Poster",
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              key: ValueKey(
                _refresh,
              ), // Force la reconstruction quand _refresh change
              future: _getProjects(isClient),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: lancyPurple),
                  );
                }
                final data = snapshot.data ?? [];
                if (data.isEmpty) {
                  return _buildEmptyState(isClient);
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: data.length,
                  itemBuilder: (context, index) =>
                      _projectCard(data[index], isClient),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Bonjour, ${widget.name ?? 'Utilisateur'} 👋",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            widget.role == "client"
                ? "Gérez vos missions publiées"
                : "Trouvez votre prochaine mission",
            style: GoogleFonts.inter(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isClient) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(
            isClient
                ? "Vous n'avez posté aucun projet"
                : "Aucun projet disponible",
            style: GoogleFonts.inter(color: Colors.grey),
          ),
        ],
      ),
    );
  }

Widget _projectCard(dynamic item, bool isClient) {
  // 1. Déterminer les états du projet
  final bool isAccepted = item["acceptedFreelancer"] != null;
  
  // On récupère le statut de la proposition (doit être envoyé par ton backend)
  final String proposalStatus = item["userProposalStatus"] ?? "none"; 
  final bool isRejected = proposalStatus == "rejected";

  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- ENTÊTE : Titre et Menu ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item["title"] ?? "Sans titre",
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isClient)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditProjectDialog(context, item);
                    } else if (value == 'delete') {
                      _confirmDeletion(item["_id"]);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit, color: Colors.blue),
                        title: Text("Modifier"),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text("Supprimer"),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                  child: const Icon(Icons.more_vert, color: Colors.grey),
                ),
            ],
          ),
          const SizedBox(height: 8),
          
          // --- DESCRIPTION ---
          Text(
            item["description"] ?? "",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey[700], height: 1.4),
          ),
          const SizedBox(height: 16),
          
          // --- ACTIONS (BOUTONS) ---
          Row(
            children: [
              // Bouton Principal : Postuler (Freelance) ou Voir Propositions (Client)
              if (!isClient)
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isRejected ? Colors.grey : skyBlue,
                    ),
                    onPressed: isRejected 
                      ? null // Bouton désactivé si refusé
                      : () async {
                          final token = await AuthService.getToken();
                          if (token != null) {
                            Get.to(() => SendProposalScreen(
                              projectId: item["_id"],
                              token: token,
                            ));
                          }
                        },
                    child: Text(isRejected ? "Refusé" : "Postuler"),
                  ),
                )
              else
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.list_alt, size: 18),
                    label: const Text("Voir les propositions"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: lancyPurple,
                      side: BorderSide(color: lancyPurple),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Get.to(
                      () => ProposalsListScreen(projectId: item["_id"]),
                    ),
                  ),
                ),

              const SizedBox(width: 10),

              // --- BOUTON MESSAGE (L'icône Chat) ---
              IconButton(
                tooltip: "Contacter",
                icon: Icon(
                  Icons.message,
                  color: isRejected 
                      ? Colors.grey.withOpacity(0.5) 
                      : (isClient && !isAccepted ? Colors.grey : Colors.green),
                ),
                onPressed: () async {
                  // 1. Bloquer si le freelance est refusé
                  if (!isClient && isRejected) {
                    Get.snackbar(
                      "Accès refusé", 
                      "Vous ne pouvez plus contacter le client car votre offre a été refusée.",
                      backgroundColor: Colors.red[100],
                      colorText: Colors.red[900]
                    );
                    return;
                  }

                  // 2. Bloquer si le client n'a pas encore accepté de freelance
                  if (isClient && !isAccepted) {
                    Get.snackbar(
                      "Action requise", 
                      "Vous devez accepter une proposition pour débloquer le chat.",
                      backgroundColor: Colors.orange[100]
                    );
                    return;
                  }

                  final currentUserId = await AuthService.getUserId();
                  if (currentUserId == null) return;

                  // 3. Récupération dynamique du destinataire
                  String? receiverId;
                  String receiverName = "Utilisateur";

                  if (isClient) {
                    // Le client parle au freelance accepté
                    final fData = item["acceptedFreelancer"];
                    receiverId = (fData is Map) ? fData["_id"] : fData;
                    receiverName = item["freelancerName"] ?? "Freelancer";
                  } else {
                    // Le freelance parle au proprio (clé "owner" d'après tes logs)
                    final oData = item["owner"];
                    receiverId = (oData is Map) ? oData["_id"] : oData;
                    receiverName = (oData is Map) ? (oData["name"] ?? "Client") : "Client";
                  }

                  if (receiverId != null) {
                    Get.to(() => ChatScreen(
                      currentUserId: currentUserId,
                      receiverId: receiverId!,
                      receiverName: receiverName,
                      projectId: item["_id"],
                    ));
                  } else {
                    Get.snackbar("Erreur", "Impossible de trouver l'interlocuteur.");
                  }
                },
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
  // --- DIALOGUE D'AJOUT ---
  void _showAddProjectDialog(BuildContext context) {
    final title = TextEditingController();
    final desc = TextEditingController();
    final budget = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Nouvelle Mission",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogField(title, "Titre du projet", Icons.title),
              const SizedBox(height: 12),
              _buildDialogField(
                desc,
                "Description",
                Icons.description,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              _buildDialogField(
                budget,
                "Budget (DT)",
                Icons.monetization_on,
                isNumber: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: lancyPurple,
              shape: const StadiumBorder(),
            ),
            onPressed: () async {
              final token = await AuthService.getToken();
              if (token == null) return;

              final success = await homeService.addProject({
                "title": title.text,
                "description": desc.text,
                "budget": budget.text,
                "clientEmail": _emailNorm,
              }, token);

              if (success) {
                Navigator.pop(context);
                setState(() {
                  _refresh++; // Déclenche le rechargement de la liste
                });
                Get.snackbar("Succès", "Mission publiée !");
              } else {
                Get.snackbar("Erreur", "Échec de la publication");
              }
            },
            child: const Text("Publier", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    int maxLines = 1,
    bool isNumber = false,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 20, color: skyBlue),
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

  