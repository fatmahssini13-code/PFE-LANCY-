import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pfe/screens/ProfileScreen.dart';
import 'package:pfe/screens/chat_screen.dart';
import 'package:pfe/screens/notifications_screen.dart';
import 'package:pfe/screens/proposals_list_screen.dart';
import 'package:pfe/screens/send_proposal_screen.dart';
import 'package:pfe/service/home_service.dart';
import 'package:pfe/service/auth_service.dart';
import 'package:pfe/service/project_service.dart'; // Assure-toi que ce fichier contient update et delete
import 'package:pfe/config/api_config.dart';
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
  static const Color _cardBorder = Color(0xFFE8ECF2);
  static const Color _slateText = Color(0xFF475569);
  /// Not [late]: hot reload does not re-run [initState], which caused LateInitializationError.
  Future<List<dynamic>>? _projectsFuture;
  IO.Socket? socket;
  bool hasNotification = false;
  List<Map<String, dynamic>> notificationHistory = [];
//socket ??= IO.io('http://192.168.1.100:5001', <String, dynamic>
  @override
  void initState() {
    super.initState();
    _ensureProjectsFuture();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectSocket();
    });
  }

  @override
  void reassemble() {
    super.reassemble();
    // Only invoked during debug hot reload — re-bind future because [initState] does not run again.
    _projectsFuture = _loadProjectsList();
  }

  void _ensureProjectsFuture() {
    _projectsFuture ??= _loadProjectsList();
  }

  Future<List<dynamic>> _loadProjectsList() async {
    final isClient = widget.role.toLowerCase() == 'client';
    return _getProjects(isClient);
  }

  Future<void> _reloadProjects() async {
    setState(() {
      _projectsFuture = _loadProjectsList();
    });
    await _projectsFuture;
  }
  // Déclare le socket en dehors pour qu'il soit persistant

  void _connectSocket() {
  // On initialise le socket s'il est null
  socket ??= IO.io(ApiConfig.socketUrl, <String, dynamic>
  {
    'transports': ['websocket'],
    'autoConnect': true,
    'forceNew': false, // Très important pour garder la même session
  });

  // À chaque reconnexion, on rejoint la room IMMÉDIATEMENT
  socket!.onConnect((_) {
    Future.microtask(() async {
      final uid = await AuthService.getUserId();
      if (!mounted || socket == null) return;
      /** Même clé que le backend : Mongo user id pour `io.to(id)` (notifs, etc.). */
      if (uid != null && uid.isNotEmpty) {
        socket!.emit('join', uid);
      } else {
        socket!.emit('join', widget.email.trim().toLowerCase());
      }
      if (mounted) debugPrint('✅ Connexion établie (socket join)');
    });
  });

  // On s'assure qu'on n'a pas de doublons d'écouteurs
  socket!.off('notification');

  socket!.on('notification', (data) {
    debugPrint('🔔 SIGNAL REÇU !');
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
        : homeService.fetchProjects(authToken: token);
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
          _reloadProjects(); // Rafraîchir la liste
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
                _reloadProjects();
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
    _ensureProjectsFuture();
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
              backgroundColor: skyBlue.withValues(alpha: 0.2),
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
              future: _projectsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: lancyPurple),
                  );
                }
                final data = snapshot.data ?? [];
                if (data.isEmpty) {
                  return RefreshIndicator(
                    color: lancyPurple,
                    onRefresh: _reloadProjects,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildEmptyState(isClient),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  color: lancyPurple,
                  onRefresh: _reloadProjects,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: data.length,
                    itemBuilder: (context, index) =>
                        _projectCard(data[index], isClient),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final isClient = widget.role.toLowerCase() == 'client';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Bonjour, ${widget.name ?? 'Utilisateur'} 👋",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isClient
                ? "Gérez vos missions publiées"
                : "Trouvez votre prochaine mission",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.35,
            ),
          ),
          if (!isClient) ...[
            const SizedBox(height: 10),
            Text(
              "Budget, client et statut sur chaque carte — tirez vers le bas pour actualiser.",
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[500],
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isClient) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_outline_rounded, size: 72, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              isClient
                  ? "Vous n'avez pas encore publié de mission"
                  : "Aucune mission pour le moment",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isClient
                  ? "Utilisez le bouton « Poster » pour attirer des freelances."
                  : "Revenez plus tard ou tirez pour actualiser la liste.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _projectCard(dynamic item, bool isClient) {
    final bool isAccepted = item["acceptedFreelancer"] != null;

    if (isClient) {
      return _buildClientMissionCard(item, isAccepted);
    }
    return _buildFreelancerMissionCard(item);
  }

  /// Budget projet (nombre entier DT) pour l’API / lecture seule proposition.
  int _budgetAsInt(dynamic raw) {
    if (raw == null) return 0;
    if (raw is int) return raw;
    if (raw is num) return raw.round();
    return int.tryParse(raw.toString()) ?? 0;
  }

  BoxDecoration _missionCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _cardBorder),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.06),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  ({String label, Color bg, Color fg}) _statusStyle(String? status) {
    switch ((status ?? 'open').toLowerCase()) {
      case 'open':
        return (
          label: 'Ouverte',
          bg: const Color(0xFFE0F2FE),
          fg: const Color(0xFF0369A1),
        );
      case 'in_progress':
        return (
          label: 'En cours',
          bg: const Color(0xFFFEF3C7),
          fg: const Color(0xFFB45309),
        );
      case 'delivered':
        return (
          label: 'Livrée',
          bg: const Color(0xFFD1FAE5),
          fg: const Color(0xFF047857),
        );
      case 'completed':
        return (
          label: 'Terminée',
          bg: const Color(0xFFE5E7EB),
          fg: const Color(0xFF374151),
        );
      default:
        return (
          label: status ?? '—',
          bg: const Color(0xFFF1F5F9),
          fg: _slateText,
        );
    }
  }

  Widget _statusBadge(String? status) {
    final s = _statusStyle(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        s.label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: s.fg,
        ),
      ),
    );
  }

  Widget _metaChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF334155),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatBudget(dynamic raw) {
    if (raw == null) return '—';
    final n = raw is num ? raw : num.tryParse(raw.toString());
    if (n == null) return '$raw DT';
    final intPart = n.round();
    if ((n - intPart).abs() < 1e-9) {
      return '${NumberFormat.decimalPattern('fr_FR').format(intPart)} DT';
    }
    return '${NumberFormat.decimalPattern('fr_FR').format(n)} DT';
  }

  String _ownerDisplayName(dynamic item) {
    final o = item['owner'];
    if (o is Map) {
      final name = o['name']?.toString().trim();
      if (name != null && name.isNotEmpty) return name;
      final mail = o['email']?.toString();
      if (mail != null && mail.isNotEmpty) {
        final local = mail.split('@').first;
        return local.isNotEmpty ? local : 'Client';
      }
    }
    return 'Client';
  }

  /// Nom du freelance retenu pour le chat côté client (API populate `acceptedFreelancer`).
  String _acceptedFreelancerChatName(dynamic item) {
    final f = item['acceptedFreelancer'];
    if (f is Map) {
      final name = f['name']?.toString().trim();
      if (name != null && name.isNotEmpty) return name;
      final mail = f['email']?.toString();
      if (mail != null && mail.isNotEmpty) {
        final local = mail.split('@').first;
        if (local.isNotEmpty) return local;
      }
    }
    final legacy = item['freelancerName']?.toString().trim();
    if (legacy != null && legacy.isNotEmpty) return legacy;
    return 'Freelancer';
  }

  String _postedRelative(dynamic raw) {
    if (raw == null) return '';
    final dt = DateTime.tryParse(raw.toString());
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inHours < 1) return 'Il y a ${diff.inMinutes} min';
    if (diff.inDays < 1) return 'Il y a ${diff.inHours} h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} j';
    return DateFormat.yMMMd('fr_FR').format(dt);
  }

  Future<void> _openMissionChat(
    dynamic item, {
    required bool isClient,
    required bool isRejected,
    required bool isAccepted,
  }) async {
    if (!isClient && isRejected) {
      Get.snackbar(
        "Accès refusé",
        "Vous ne pouvez plus contacter le client car votre offre a été refusée.",
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
      return;
    }
    if (!isClient) {
      final ps = item["userProposalStatus"]?.toString() ?? "none";
      if (ps != "accepted") {
        Get.snackbar(
          "Chat verrouillé",
          "Le client doit accepter votre proposition pour ouvrir la messagerie.",
          backgroundColor: Colors.orange[100],
          colorText: Colors.orange.shade900,
        );
        return;
      }
    }
    if (isClient && !isAccepted) {
      Get.snackbar(
        "Action requise",
        "Vous devez accepter une proposition pour débloquer le chat.",
        backgroundColor: Colors.orange[100],
      );
      return;
    }

    final currentUserId = await AuthService.getUserId();
    if (currentUserId == null) return;

    String? receiverId;
    String receiverName = "Utilisateur";

    if (isClient) {
      final fData = item["acceptedFreelancer"];
      receiverId = (fData is Map) ? fData["_id"] ?? fData["id"] : fData;
      receiverName = _acceptedFreelancerChatName(item);
    } else {
      final oData = item["owner"];
      receiverId = (oData is Map) ? oData["_id"] : oData;
      receiverName =
          (oData is Map) ? (oData["name"] ?? "Client") : "Client";
    }

    if (receiverId != null) {
      Get.to(() => ChatScreen(
            currentUserId: currentUserId,
            receiverId: receiverId!,
            receiverName: receiverName,
            projectId: item["_id"].toString(),
          ));
    } else {
      Get.snackbar("Erreur", "Impossible de trouver l'interlocuteur.");
    }
  }

  Widget _buildFreelancerMissionCard(dynamic item) {
    final title = item["title"] ?? "Sans titre";
    final desc = (item["description"] ?? "").toString();
    final status = item["status"]?.toString();
    final posted = _postedRelative(item["createdAt"]);
    final String proposalStatus =
        item["userProposalStatus"]?.toString() ?? "none";
    final bool isRejected = proposalStatus == "rejected";
    final bool hasActiveProposal =
        proposalStatus == "pending" || proposalStatus == "accepted";
    final bool canPostuler = !isRejected && !hasActiveProposal;

    final bool proposalAccepted =
        proposalStatus == "accepted";
    final chatEnabled = proposalAccepted;
    final chatColor = chatEnabled
        ? const Color(0xFF059669)
        : Colors.grey.withValues(alpha: 0.45);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: _missionCardDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _statusBadge(status)),
                if (posted.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.schedule_rounded,
                      size: 15, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    posted,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.25,
                letterSpacing: -0.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _metaChip(
                  icon: Icons.payments_outlined,
                  label: _formatBudget(item["budget"]),
                ),
                _metaChip(
                  icon: Icons.person_outline_rounded,
                  label: _ownerDisplayName(item),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              desc.isEmpty ? 'Pas de description.' : desc,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.45,
                color: _slateText,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: canPostuler
                        ? () async {
                            final token = await AuthService.getToken();
                            if (token != null && mounted) {
                              final sent = await Get.to<bool>(() =>
                                  SendProposalScreen(
                                    projectId: item["_id"].toString(),
                                    token: token,
                                    projectTitle:
                                        title?.toString() ?? 'Sans titre',
                                    clientBudget: _budgetAsInt(item["budget"]),
                                  ));
                              if (sent == true && mounted) {
                                await _reloadProjects();
                              }
                            }
                          }
                        : null,
                    icon: Icon(
                      canPostuler
                          ? Icons.send_rounded
                          : Icons.block_rounded,
                      size: 20,
                    ),
                    label: Text(
                      isRejected
                          ? 'Proposition refusée'
                          : hasActiveProposal
                              ? 'Proposition envoyée'
                              : 'Postuler',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: canPostuler
                          ? skyBlue
                          : Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Material(
                  color: chatEnabled
                      ? const Color(0xFFECFDF5)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: chatEnabled
                        ? () => _openMissionChat(
                              item,
                              isClient: false,
                              isRejected: isRejected,
                              isAccepted: item["acceptedFreelancer"] != null,
                            )
                        : null,
                    child: SizedBox(
                      width: 52,
                      height: 52,
                      child: Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: chatColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientMissionCard(dynamic item, bool isAccepted) {
    final title = item["title"] ?? "Sans titre";
    final desc = (item["description"] ?? "").toString();
    final status = item["status"]?.toString();
    final proposalStatus = item["userProposalStatus"] ?? "none";
    final isRejected = proposalStatus == "rejected";

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: _missionCardDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _statusBadge(status)),
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
                        leading: Icon(Icons.edit_rounded, color: Colors.blue),
                        title: Text("Modifier"),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete_outline_rounded,
                            color: Colors.red),
                        title: Text("Supprimer"),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(Icons.more_horiz_rounded, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _metaChip(
                  icon: Icons.payments_outlined,
                  label: _formatBudget(item["budget"]),
                ),
                if (_postedRelative(item["createdAt"]).isNotEmpty)
                  _metaChip(
                    icon: Icons.calendar_today_outlined,
                    label: _postedRelative(item["createdAt"]),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              desc.isEmpty ? 'Pas de description.' : desc,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.45,
                color: _slateText,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.group_outlined, size: 20),
                    label: const Text('Voir les propositions'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: lancyPurple,
                      side: BorderSide(color: lancyPurple.withValues(alpha: 0.65)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
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
                Material(
                  color: !isAccepted
                      ? Colors.grey.shade100
                      : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _openMissionChat(
                          item,
                          isClient: true,
                          isRejected: isRejected,
                          isAccepted: isAccepted,
                        ),
                    child: SizedBox(
                      width: 52,
                      height: 52,
                      child: Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: !isAccepted
                            ? Colors.grey.withValues(alpha: 0.45)
                            : const Color(0xFF059669),
                      ),
                    ),
                  ),
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
                await _reloadProjects();
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

  