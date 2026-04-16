import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfe/screens/ProfileScreen.dart';
import 'package:pfe/service/home_service.dart';
import 'package:pfe/service/auth_service.dart';
import 'package:pfe/service/user_service.dart';

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
  final UserService _userService = UserService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  final Color mintCrystal = const Color(0xFF81E38F);
  final Color skyBlue = const Color(0xFF74C0FC);
  final Color darkText = const Color(0xFF1A1C1E);
  final Color backgroundLight = const Color(0xFFF9FBFF);

  int _listRefresh = 0;
  String _resolvedName = '';

  @override
  void initState() {
    super.initState();
    _bootstrapDisplayName();
  }

  Future<void> _bootstrapDisplayName() async {
    var provisional = widget.name?.trim() ?? '';
    if (provisional.isEmpty) {
      final fromPrefs = await AuthService.getUserName();
      provisional = fromPrefs?.trim() ?? '';
    }
    if (provisional.isNotEmpty && mounted) {
      setState(() => _resolvedName = provisional);
    }

    try {
      final profile = await _userService.fetchProfile(_emailNorm);
      final fromApi = profile.name?.trim() ?? '';
      if (fromApi.isNotEmpty) {
        if (mounted) setState(() => _resolvedName = fromApi);
        await AuthService.saveUserName(fromApi);
      }
    } catch (_) {
      /* garde le nom prefs / widget si l’API échoue */
    }
  }

  String get _avatarLetter {
    final s = _resolvedName.isNotEmpty
        ? _resolvedName
        : (widget.email.isNotEmpty ? widget.email : '?');
    return s.trim().isEmpty ? '?' : s.trim()[0].toUpperCase();
  }

  String get _headlineName {
    if (_resolvedName.isNotEmpty) return _resolvedName;
    return 'Bienvenue';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _budgetController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _goToProfile() {
    Get.to(() => ProfileScreen(email: widget.email));
  }

  String get _emailNorm => widget.email.trim().toLowerCase();

  @override
  Widget build(BuildContext context) {
    bool isClient = widget.role.trim().toLowerCase() == "client";

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text("LANCY",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800, color: darkText)),
        actions: [
          IconButton(
            onPressed: _goToProfile,
            icon: CircleAvatar(
              backgroundColor: skyBlue.withValues(alpha: 0.1),
              child: Text(
                _avatarLetter,
                style: TextStyle(
                  color: skyBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: isClient
          ? FloatingActionButton.extended(
              onPressed: () => _showAddProjectSheet(context),
              backgroundColor: skyBlue,
              label: const Text("Publier un projet",
                  style: TextStyle(color: Colors.white)),
              icon: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Bonjour",
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _headlineName,
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: darkText,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.email,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                isClient ? "Mes missions" : "Missions ouvertes",
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildMainList(isClient)),
          ],
        ),
      ),
    );
  }

  Future<List<dynamic>> _mainListFuture(bool isClient) async {
    if (isClient) {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        return [];
      }
      return homeService.fetchMyProjects(token);
    }
    return homeService.fetchProjects();
  }

  Future<void> _refreshList(bool isClient) async {
    setState(() => _listRefresh++);
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

  void _showAddProjectSheet(BuildContext context) {
    _titleController.clear();
    _budgetController.clear();
    _descController.clear();

    final busy = ValueNotifier<bool>(false);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: ValueListenableBuilder<bool>(
            valueListenable: busy,
            builder: (context, isBusy, _) {
              return Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF9FBFF),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Nouvelle mission 🚀",
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: darkText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Décris ton besoin — les freelancers pourront te répondre.",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _sheetField(
                        controller: _titleController,
                        hint: "Titre du projet",
                        icon: Icons.title_rounded,
                      ),
                      const SizedBox(height: 16),
                      _sheetField(
                        controller: _descController,
                        hint: "Description",
                        icon: Icons.notes_rounded,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      _sheetField(
                        controller: _budgetController,
                        hint: "Budget (nombre)",
                        icon: Icons.payments_outlined,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 28),
                      InkWell(
                        onTap: isBusy
                            ? null
                            : () async {
                                final title = _titleController.text.trim();
                                final desc = _descController.text.trim();
                                final budget = _budgetController.text.trim();
                                if (title.isEmpty ||
                                    desc.isEmpty ||
                                    budget.isEmpty) {
                                  Get.snackbar(
                                    "Champs requis",
                                    "Remplis titre, description et budget.",
                                    backgroundColor: Colors.orange.shade700,
                                    colorText: Colors.white,
                                  );
                                  return;
                                }

                                final token = await AuthService.getToken();
                                if (token == null || token.isEmpty) {
                                  Get.snackbar(
                                    "Session",
                                    "Reconnecte-toi pour publier un projet.",
                                    backgroundColor: Colors.redAccent,
                                    colorText: Colors.white,
                                  );
                                  return;
                                }

                                busy.value = true;
                                try {
                                  final success = await homeService.addProject({
                                    "title": title,
                                    "description": desc,
                                    "budget": budget,
                                    "clientEmail": _emailNorm,
                                  }, token);

                                  if (!sheetContext.mounted) return;

                                  if (success) {
                                    Navigator.pop(sheetContext);
                                    setState(() => _listRefresh++);
                                    Get.snackbar(
                                      "Succès ✨",
                                      "Projet publié !",
                                      backgroundColor:
                                          mintCrystal.withValues(alpha: 0.95),
                                      colorText: Colors.white,
                                    );
                                  } else {
                                    Get.snackbar(
                                      "Erreur",
                                      "Impossible d’ajouter le projet (vérifie le serveur).",
                                      backgroundColor: Colors.redAccent,
                                      colorText: Colors.white,
                                    );
                                  }
                                } catch (e) {
                                  Get.snackbar("Erreur", e.toString());
                                } finally {
                                  busy.value = false;
                                }
                              },
                        child: Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [skyBlue, mintCrystal],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: skyBlue.withValues(alpha: 0.28),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            child: isBusy
                                ? const SizedBox(
                                    width: 26,
                                    height: 26,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    "PUBLIER LA MISSION",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _sheetField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(
          color: darkText,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: skyBlue, size: 22),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildMainList(bool isClient) {
    return FutureBuilder<List<dynamic>>(
      key: ValueKey('list_${_listRefresh}_$isClient'),
      future: _mainListFuture(isClient),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                "Erreur: ${snapshot.error}",
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final data = snapshot.data ?? [];

        if (data.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => _refreshList(isClient),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.25,
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      isClient
                          ? "Aucune mission pour l’instant.\nPublie ta première avec le bouton + ou tire pour actualiser."
                          : "Aucun projet disponible pour le moment.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => _refreshList(isClient),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: data.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _missionProjectCard(data[index], isClient),
              );
            },
          ),
        );
      },
    );
  }

  Widget _missionProjectCard(dynamic raw, bool isClient) {
    final item = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    final title = item['title']?.toString() ??
        item['name']?.toString() ??
        item['fullName']?.toString() ??
        "Sans titre";
    final description = (item['description']?.toString() ?? '').trim();
    final budget = item['budget'];
    final statusKey = (item['status']?.toString() ?? 'open').toLowerCase();
    final statusUi = _statusChipStyle(statusKey);

    String? clientLine;
    if (!isClient) {
      final client = item['clientId'];
      if (client is Map) {
        final n = client['name']?.toString();
        final em = client['email']?.toString();
        if (n != null && n.isNotEmpty) {
          clientLine = n;
        } else if (em != null && em.isNotEmpty) {
          clientLine = em;
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [skyBlue, mintCrystal],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: LinearGradient(
                                colors: [
                                  skyBlue.withValues(alpha: 0.2),
                                  mintCrystal.withValues(alpha: 0.25),
                                ],
                              ),
                            ),
                            child: Icon(
                              isClient
                                  ? Icons.rocket_launch_outlined
                                  : Icons.handshake_outlined,
                              color: skyBlue,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: GoogleFonts.poppins(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: darkText,
                                    height: 1.25,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (clientLine != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.person_outline,
                                        size: 15,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          clientLine,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: Colors.grey[700],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          description,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _infoChip(
                            icon: Icons.payments_outlined,
                            label: budget != null ? 'Budget $budget' : 'Budget —',
                            color: darkText,
                          ),
                          _statusChip(
                            label: statusUi.label,
                            bg: statusUi.background,
                            fg: statusUi.foreground,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ({String label, Color background, Color foreground}) _statusChipStyle(
    String key,
  ) {
    switch (key) {
      case 'open':
        return (
          label: 'Ouvert',
          background: mintCrystal.withValues(alpha: 0.22),
          foreground: const Color(0xFF2F6F3A),
        );
      case 'closed':
      case 'done':
        return (
          label: key == 'done' ? 'Terminé' : 'Fermé',
          background: Colors.grey.shade200,
          foreground: Colors.grey.shade800,
        );
      case 'in_progress':
      case 'progress':
        return (
          label: 'En cours',
          background: skyBlue.withValues(alpha: 0.2),
          foreground: const Color(0xFF1C5F8C),
        );
      default:
        return (
          label: key,
          background: Colors.grey.shade200,
          foreground: Colors.grey.shade800,
        );
    }
  }

  Widget _infoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color.withValues(alpha: 0.75)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip({
    required String label,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
