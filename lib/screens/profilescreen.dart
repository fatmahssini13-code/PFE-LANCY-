import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:pfe/Model/User.dart';
import 'package:pfe/screens/ChangePasswordScreen.dart';
import 'package:pfe/screens/auth/login.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pfe/service/auth_service.dart';
import 'package:pfe/service/user_service.dart';
import 'package:pfe/service/project_service.dart';

class ProfileScreen extends StatefulWidget {
  final String email;

  const ProfileScreen({super.key, required this.email});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService userService = UserService();
  final ProjectService projectService = ProjectService();

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController budgetController = TextEditingController();

  final Color mintCrystal = const Color(0xFF81E38F);
  final Color skyBlue = const Color(0xFF74C0FC);
  final Color darkText = const Color(0xFF1A1C1E);
  final Color backgroundLight = const Color(0xFFF9FBFF);

  late Future<UserModel> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = userService.fetchProfile(widget.email.trim());
  }

  void _reloadProfile() {
    setState(() {
      _profileFuture = userService.fetchProfile(widget.email.trim());
    });
  }

  @override
  void dispose() {
    titleController.dispose();
    descController.dispose();
    budgetController.dispose();
    super.dispose();
  }

  String _initialFor(UserModel user) {
    final n = user.name?.trim();
    if (n != null && n.isNotEmpty) return n[0].toUpperCase();
    final e = user.email.trim();
    if (e.isNotEmpty) return e[0].toUpperCase();
    return '?';
  }

  String _roleLabel(String? role) {
    final r = (role ?? 'user').toLowerCase();
    if (r == 'client') return 'Client';
    if (r == 'freelancer') return 'Freelancer';
    return role?.toUpperCase() ?? 'UTILISATEUR';
  }

  InputDecoration _sheetInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: skyBlue, size: 22),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: skyBlue, width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }

  Future<void> _confirmLogout() async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Déconnexion',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
            'Tu seras renvoyé à l\'écran de connexion. Continuer ?',
            style: GoogleFonts.inter(height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler',
                style:
                    GoogleFonts.poppins(color: Colors.grey.shade700)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: skyBlue, foregroundColor: Colors.white),
            child: Text('Se déconnecter',
                style:
                    GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (go != true || !mounted) return;
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showEditProfileDialog(UserModel user) {
    final nameCtrl = TextEditingController(text: user.name);
    final bioCtrl = TextEditingController(text: user.bio ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text("Modifier le profil",
                  style: GoogleFonts.poppins(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                decoration: _sheetInputDecoration(
                    "Nom", Icons.person_outline),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bioCtrl,
                maxLines: 3,
                decoration: _sheetInputDecoration(
                    "Bio", Icons.notes_rounded),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: skyBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () async {
                  final ok = await userService.updateProfile(
                    email: widget.email,
                    name: nameCtrl.text,
                    bio: bioCtrl.text,
                  );
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  if (ok) {
                    _reloadProfile();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Profil mis à jour ✅",
                            style: GoogleFonts.inter()),
                        backgroundColor: mintCrystal,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: Text("Enregistrer",
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddProjectDialog() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Poster une mission',
                  style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: darkText)),
              const SizedBox(height: 6),
              Text(
                  'Décris ta mission pour attirer les bons freelances.',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.35)),
              const SizedBox(height: 22),
              TextField(
                controller: titleController,
                decoration: _sheetInputDecoration(
                    'Titre', Icons.title_rounded),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: _sheetInputDecoration(
                    'Description', Icons.notes_rounded),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: budgetController,
                keyboardType: TextInputType.number,
                decoration: _sheetInputDecoration(
                    'Budget', Icons.payments_outlined),
              ),
              const SizedBox(height: 24),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    if (titleController.text.isEmpty ||
                        descController.text.isEmpty ||
                        budgetController.text.isEmpty) return;
                    try {
                      final success = await projectService.createProject(
                        titleController.text.trim(),
                        descController.text.trim(),
                        budgetController.text.trim(),
                        widget.email,
                      );
                      if (!mounted) return;
                      if (success) {
                        Navigator.of(context).pop();
                        titleController.clear();
                        descController.clear();
                        budgetController.clear();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Mission publiée !'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: mintCrystal,
                          ),
                        );
                        setState(() {});
                      }
                    } catch (e) {
                      debugPrint('$e');
                    }
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Ink(
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [skyBlue, mintCrystal]),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: skyBlue.withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text('Confirmer la publication',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: backgroundLight,
      body: FutureBuilder<UserModel>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(
                    color: skyBlue, strokeWidth: 3));
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return _buildErrorBody();
          }
          final user = snapshot.data!;
          return RefreshIndicator(
            color: skyBlue,
            onRefresh: () async {
              final f =
                  userService.fetchProfile(widget.email.trim());
              setState(() => _profileFuture = f);
              try {
                await f;
              } catch (_) {}
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                    child: _buildHeader(context, user, topPad)),
                SliverPadding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ✅ Stats
                      _buildStatsCard(user),
                      const SizedBox(height: 16),

                      // Contact
                      _buildContactCard(user),
                      const SizedBox(height: 16),

                      // Bio
                      _buildAboutCard(user),

                      // Spécialité freelancer
                      if (user.role == 'freelancer' &&
                          (user.speciality != null &&
                              user.speciality!.trim().isNotEmpty)) ...[
                        const SizedBox(height: 16),
                        _buildSpecialityCard(
                            user.speciality!.trim()),
                      ],

                      // Skills freelancer
                      if (user.role == 'freelancer') ...[
                        const SizedBox(height: 16),
                        _buildSkillsSection(user),
                      ],

                      // Actions client
                      if (user.role == 'client') ...[
                        const SizedBox(height: 20),
                        _buildSectionLabel('Mes actions'),
                        const SizedBox(height: 12),
                        _buildPrimaryCta(
                          label: 'Poster une nouvelle mission',
                          icon: Icons.add_circle_outline_rounded,
                          onTap: _showAddProjectDialog,
                        ),
                      ],

                      // ✅ Sécurité
                      const SizedBox(height: 28),
                      _buildSectionLabel('Sécurité'),
                      const SizedBox(height: 10),
                      _buildSecurityCard(),

                      // Connexion
                      const SizedBox(height: 20),
                      _buildSectionLabel('Connexion'),
                      const SizedBox(height: 10),
                      _buildLoginOutCard(),
                      const SizedBox(height: 24),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ✅ Stats card
  Widget _buildStatsCard(UserModel user) {
    final isClient = user.role == 'client';
    return Row(
      children: [
        Expanded(
          child: _statTile(
            value: isClient
                ? "${user.projectCount ?? 0}"
                : "${user.proposalCount ?? 0}",
            label:
                isClient ? "Projets publiés" : "Propositions",
            color: skyBlue,
            icon: isClient
                ? Icons.work_outline
                : Icons.send_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statTile(
            value: isClient
                ? "0"
                : "${user.wonCount ?? 0}",
            label: isClient
                ? "Missions terminées"
                : "Missions gagnées",
            color: mintCrystal,
            icon: Icons.emoji_events_outlined,
          ),
        ),
      ],
    );
  }

  Widget _statTile({
    required String value,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: color)),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  // ✅ Security card
  Widget _buildSecurityCard() {
    return _surfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline_rounded,
                  color: skyBlue, size: 22),
              const SizedBox(width: 10),
              Text("Mot de passe",
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: darkText)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Modifie ton mot de passe pour sécuriser ton compte.",
            style: GoogleFonts.inter(
                fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Get.to(() =>
                  ChangePasswordScreen(email: widget.email)),
              icon: Icon(Icons.lock_reset_rounded,
                  color: skyBlue, size: 18),
              label: Text("Changer le mot de passe",
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: skyBlue)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: skyBlue),
                padding:
                    const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBody() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('Impossible de charger le profil',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: darkText)),
            const SizedBox(height: 8),
            Text('Vérifie ta connexion et réessaie.',
                textAlign: TextAlign.center,
                style:
                    GoogleFonts.inter(color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _reloadProfile,
              style: FilledButton.styleFrom(
                backgroundColor: skyBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: Text('Réessayer',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, UserModel user, double topPad) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: topPad + 8,
        left: 8,
        right: 20,
        bottom: 28,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [skyBlue, const Color(0xFF5BA9E8), mintCrystal],
        ),
        borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: skyBlue.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          // Bouton retour
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              style: IconButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withOpacity(0.2),
              ),
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 20),
            ),
          ),
          const SizedBox(height: 8),

          // Avatar
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
           // ✅ Remplace le CircleAvatar existant par ça
child: GestureDetector(
  onTap: () => _pickAndUploadImage(user),
  child: Stack(
    children: [
      Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: CircleAvatar(
          radius: 48,
          backgroundColor: Colors.white,
          backgroundImage: (user.avatar != null && user.avatar!.isNotEmpty)
              ? NetworkImage(user.avatar!) // ✅ affiche la photo
              : null,
          child: (user.avatar == null || user.avatar!.isEmpty)
              ? Text(
                  _initialFor(user),
                  style: GoogleFonts.poppins(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: skyBlue),
                )
              : null,
        ),
      ),
      // ✅ Icône appareil photo
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: skyBlue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.camera_alt,
              color: Colors.white, size: 14),
        ),
      ),
    ],
  ),
),
          ),
          const SizedBox(height: 16),

          // Nom
          Text(
            user.displayName,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.15),
          ),
          const SizedBox(height: 6),

          // Email
          Text(
            user.email,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white.withOpacity(0.92)),
          ),
          const SizedBox(height: 14),

          // Badge role
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.white.withOpacity(0.35)),
            ),
            child: Text(
              _roleLabel(user.role),
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: Colors.white),
            ),
          ),
          const SizedBox(height: 14),

          // ✅ Bouton modifier profil
          OutlinedButton.icon(
            onPressed: () => _showEditProfileDialog(user),
            icon: const Icon(Icons.edit, size: 16, color: Colors.white),
            label: Text("Modifier le profil",
                style: GoogleFonts.inter(
                    color: Colors.white, fontSize: 13)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(99)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(UserModel user) {
    return _surfaceCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: skyBlue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.alternate_email_rounded,
                color: skyBlue, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('E-mail',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Text(user.email,
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: darkText)),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Future<void> _pickAndUploadImage(UserModel user) async {
  final picker = ImagePicker();
  final picked = await picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 80,
    maxWidth: 500,
  );

  if (picked == null) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text("Upload en cours...", style: GoogleFonts.inter()),
      backgroundColor: skyBlue,
      behavior: SnackBarBehavior.floating,
    ),
  );

  final url = await userService.uploadAvatar(
    email: widget.email,
    filePath: picked.path,
  );

  if (!mounted) return;

  if (url != null) {
    _reloadProfile(); // ✅ recharge le profil avec la nouvelle photo
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Photo mise à jour ✅", style: GoogleFonts.inter()),
        backgroundColor: mintCrystal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Erreur upload ❌", style: GoogleFonts.inter()),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

  Widget _buildAboutCard(UserModel user) {
    final bio = (user.bio ?? '').trim();
    final text = bio.isEmpty
        ? 'Aucune bio disponible pour le moment.'
        : bio;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('À propos'),
        const SizedBox(height: 10),
        _surfaceCard(
          accent: true,
          child: Text(text,
              style: GoogleFonts.inter(
                  fontSize: 15,
                  height: 1.5,
                  color: bio.isEmpty
                      ? Colors.grey.shade600
                      : darkText)),
        ),
      ],
    );
  }

  Widget _buildSpecialityCard(String speciality) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Spécialité'),
        const SizedBox(height: 10),
        _surfaceCard(
          child: Row(
            children: [
              Icon(Icons.workspace_premium_outlined,
                  color: mintCrystal),
              const SizedBox(width: 12),
              Expanded(
                child: Text(speciality,
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: darkText)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsSection(UserModel user) {
    final skills = user.skills ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Compétences'),
        const SizedBox(height: 10),
        if (skills.isEmpty)
          _surfaceCard(
            child: Text('Aucune compétence renseignée.',
                style: GoogleFonts.inter(
                    color: Colors.grey.shade600, fontSize: 15)),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skills
                .map((s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: skyBlue.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: skyBlue.withOpacity(0.25)),
                      ),
                      child: Text(s,
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1C5F8C),
                              fontSize: 13)),
                    ))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildSectionLabel(String title) {
    return Text(title,
        style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: darkText));
  }

  Widget _surfaceCard({required Widget child, bool accent = false}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (accent)
                Container(
                  width: 4,
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
                  padding: EdgeInsets.fromLTRB(
                      accent ? 14 : 18, 18, 18, 18),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginOutCard() {
    return _surfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.login_rounded, color: skyBlue, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Déconnecte-toi pour te reconnecter avec un autre compte.',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.35),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _confirmLogout,
              icon: Icon(Icons.logout_rounded,
                  color: Colors.red.shade700),
              label: Text('Se déconnecter',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade700)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade200),
                padding:
                    const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryCta({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: 56,
          decoration: BoxDecoration(
            gradient:
                LinearGradient(colors: [skyBlue, mintCrystal]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: skyBlue.withOpacity(0.3),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text(label,
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }
}