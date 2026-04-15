import 'dart:convert';
import 'package:http/http.dart' as http;

class HomeService {
  final String baseUrl = "http://192.168.100.13:5000";

  // --- 1. POUR LE CLIENT : VOIR LES FREELANCERS ---
  Future<List<dynamic>> fetchFreelancers() async {
    final response = await http.get(Uri.parse("$baseUrl/api/users/all-freelancers"));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Erreur serveur lors de la récupération des freelancers");
    }
  }

  // --- 2. POUR LE FREELANCER : VOIR TOUS LES PROJETS ---
  Future<List<dynamic>> fetchProjects() async {
    final response = await http.get(Uri.parse("$baseUrl/api/projects/"));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Erreur serveur lors de la récupération des projets");
    }
  }

  // --- 3. POUR LE CLIENT : POSTER UN NOUVEAU PROJET ---
  // On ajoute le 'token' car ta route backend utilise 'requireAuth'
  Future<bool> addProject(Map<String, dynamic> projectData, String token) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/projects/add"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token", // Transmission du token de sécurité
        },
        body: jsonEncode(projectData),
      );

      if (response.statusCode == 201) {
        return true; // Succès
      } else {
        print("Erreur Backend: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Erreur connexion: $e");
      return false;
    }
  }
}