/*import 'package:flutter/material.dart';
import 'package:pfe/screens/ProjectDetailScreen.dart';
import 'home.dart'; // Ta page d'accueil
 // Ta page de liste

class MainScreen extends StatefulWidget {
  final String role; // "client" ou "freelancer"

  const MainScreen({super.key, required this.role});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0; // Pour savoir quelle page est affichée (0, 1 ou 2)

  @override
  Widget build(BuildContext context) {
    // Liste des pièces (écrans)
    final List<Widget> pages = [
      const HomeScreen(email: '', role: '',), 
      ProjectDetailScreen(userRole: widget.role, project: null,), // La liste change selon le rôle
      const Center(child: Text("Mon Profil")),
    ];

    return Scaffold(
      // 1. Le corps de la page change selon l'index
      body: pages[_currentIndex],

      // 2. La barre de navigation en bas
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index; // Change la page quand on clique
          });
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Accueil",
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.work),
            label: widget.role == "client" ? "Mes Projets" : "Mes Missions",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profil",
          ),
        ],
      ),
    );
  }
}*/