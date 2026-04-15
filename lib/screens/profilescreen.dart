import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfe/Model/User.dart';
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

  // Controllers pour le formulaire de projet
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController budgetController = TextEditingController();

  // Couleurs Lancy
  final Color primaryBlue = const Color(0xFF00AEEF);
  final Color primaryPurple = const Color(0xFF8E2DE2);

  @override
  void dispose() {
    titleController.dispose();
    descController.dispose();
    budgetController.dispose();
    super.dispose();
  }

  // --- STYLE DES INPUTS DU FORMULAIRE ---
  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryBlue),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: primaryPurple, width: 2),
      ),
    );
  }

  // --- MODAL POUR AJOUTER UN PROJET ---
  void _showAddProjectDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 25,
          right: 25,
          top: 25,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            Text("Poster une mission 🚀", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(controller: titleController, decoration: _buildInputDecoration("Titre", Icons.title)),
            const SizedBox(height: 15),
            TextField(controller: descController, maxLines: 3, decoration: _buildInputDecoration("Description", Icons.description)),
            const SizedBox(height: 15),
            TextField(controller: budgetController, keyboardType: TextInputType.number, decoration: _buildInputDecoration("Budget (DT)", Icons.payments)),
            const SizedBox(height: 25),
            _buildGradientButton("Confirmer la publication", () async {
              if (titleController.text.isEmpty || descController.text.isEmpty || budgetController.text.isEmpty) return;
              try {
                bool success = await projectService.createProject(
                  titleController.text.trim(),
                  descController.text.trim(),
                  budgetController.text.trim(),
                  widget.email,
                );
                if (success) {
                  Navigator.pop(context);
                  titleController.clear(); descController.clear(); budgetController.clear();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mission publiée ! ✅")));
                  setState(() {}); // Rafraîchir l'UI
                }
              } catch (e) {
                print(e);
              }
            }),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BOUTON DÉGRADÉ ---
  Widget _buildGradientButton(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [primaryBlue, primaryPurple]),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: primaryPurple.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Center(child: Text(text, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: FutureBuilder<UserModel>(
        future: userService.fetchProfile(widget.email),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryPurple));
          } else if (snapshot.hasData) {
            final user = snapshot.data!;
            return CustomScrollView(
              slivers: [
                _buildSliverAppBar(user),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle("À propos"),
                        _buildInfoCard(user.bio ?? "Aucune bio disponible."),
                        const SizedBox(height: 25),
                        if (user.role == "freelancer") ...[
                          _buildSectionTitle("Compétences"),
                          _buildSkills(user.skills),
                        ] else ...[
                          _buildSectionTitle("Mes actions"),
                          _buildGradientButton("Poster une nouvelle mission", _showAddProjectDialog),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
          return const Center(child: Text("Erreur de chargement"));
        },
      ),
    );
  }

  Widget _buildSliverAppBar(UserModel user) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(gradient: LinearGradient(colors: [primaryBlue, primaryPurple])),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                child: Text(user.name?[0].toUpperCase() ?? "U", style: TextStyle(fontSize: 30, color: primaryPurple, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),
              Text(user.displayName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              Text(user.role?.toUpperCase() ?? "USER", style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
  );

  Widget _buildInfoCard(String content) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
    child: Text(content, style: GoogleFonts.inter(height: 1.5)),
  );

  Widget _buildSkills(List<String>? skills) => Wrap(
    spacing: 10,
    children: (skills ?? []).map((s) => Chip(label: Text(s), backgroundColor: primaryBlue.withOpacity(0.1))).toList(),
  );
}