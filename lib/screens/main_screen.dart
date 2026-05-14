import 'package:flutter/material.dart';
import 'package:pfe/screens/home.dart';
import 'package:pfe/screens/profilescreen.dart';
import 'package:pfe/screens/projects_list_screen.dart';
import 'package:pfe/screens/SuiviProjectScreen.dart';
import 'package:pfe/screens/project_tracking_screen.dart';

class MainScreen extends StatefulWidget {
  final String email;
  final String role;
  final String? name;

  const MainScreen({
    super.key,
    required this.email,
    required this.role,
    this.name,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  Map<String, dynamic>? selectedProject;

  void openProject(Map<String, dynamic> project) {
    setState(() {
      selectedProject = project;
    });
    // ✅ Navigation complète vers le tracking (cache la navbar)
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => widget.role == 'client'
            ? SuiviProjectScreen(project: project)
            : ProjectTrackingScreen(project: project, role: widget.role),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(email: widget.email, role: widget.role, name: widget.name),
          ProjectsListScreen(role: widget.role),
          ProfileScreen(email: widget.email),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex, // ✅ Simple, pas de logique > 2
        selectedItemColor: const Color(0xFF9249FD),
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Accueil"),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: "Projets"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }
}