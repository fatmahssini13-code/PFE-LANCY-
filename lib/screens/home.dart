import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfe/screens/ProfileScreen.dart';
import 'package:pfe/service/home_service.dart';
import 'package:pfe/service/auth_service.dart';

class HomeScreen extends StatefulWidget {
  final String email;
  final String role;

  const HomeScreen({
    super.key,
    required this.email,
    required this.role,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeService homeService = HomeService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  final Color skyBlue = const Color(0xFF74C0FC);
  final Color darkText = const Color(0xFF1A1C1E);
  
  get AuthService => null;

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

  @override
  Widget build(BuildContext context) {
    bool isClient = widget.role.trim().toLowerCase() == "client";

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFF),
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
              backgroundColor: skyBlue.withOpacity(0.1),
              child: Text(widget.email[0].toUpperCase(),
                  style: TextStyle(color: skyBlue)),
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
          children: [
            Text("Bonjour ${widget.email}",
                style: GoogleFonts.poppins(
                    fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(child: _buildMainList(isClient)),
          ],
        ),
      ),
    );
  }

  // ================= ADD PROJECT =================
  void _showAddProjectSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Nouvelle mission 🚀",
                style: GoogleFonts.poppins(
                    fontSize: 20, fontWeight: FontWeight.bold)),

            const SizedBox(height: 15),

            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Titre"),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: "Description"),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Budget"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: skyBlue),
              onPressed: () async {
                try {
                  String? token = await AuthService.getToken();

                  if (token == null || token.isEmpty) {
                    Get.snackbar("Erreur", "Reconnecte-toi !");
                    return;
                  }

                  bool success = await homeService.addProject({
                    "title": _titleController.text,
                    "description": _descController.text,
                    "budget": _budgetController.text,
                    "clientEmail": widget.email,
                  }, token);

                  if (success) {
                    Navigator.pop(context);
                    Get.snackbar("Succès", "Projet ajouté !");
                    setState(() {});
                  } else {
                    Get.snackbar("Erreur", "Échec ajout");
                  }
                } catch (e) {
                  Get.snackbar("Erreur", e.toString());
                }
              },
              child: const Text("Confirmer"),
            ),
          ],
        ),
      ),
    );
  }

  // ================= LIST =================
  Widget _buildMainList(bool isClient) {
    return FutureBuilder<List<dynamic>>(
      future: isClient
          ? homeService.fetchFreelancers()
          : homeService.fetchProjects(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Erreur: ${snapshot.error}"));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Aucune donnée"));
        }

        final data = snapshot.data!;

        return ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, index) {
            final item = data[index];

            return Card(
              child: ListTile(
                title: Text(item['title'] ??
                    item['fullName'] ??
                    "Sans titre"),
                subtitle: Text(
                    isClient ? "Freelancer" : "Projet"),
              ),
            );
          },
        );
      },
    );
  }
}