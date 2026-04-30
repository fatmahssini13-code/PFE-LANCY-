import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pfe/config/api_config.dart';

class HomeService {
  // --- 1. POUR LE CLIENT : VOIR LES FREELANCERS ---
  Future<List<dynamic>> fetchFreelancers() async {
    final response = await http.get(
      Uri.parse("${ApiConfig.origin}/api/users/all-freelancers"),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Erreur serveur lors de la récupération des freelancers");
    }
  }

  // --- 2. POUR LE FREELANCER : VOIR TOUTES LES MISSIONS (projets clients) ---
  /// Passe [authToken] pour recevoir `userProposalStatus` (déjà postulé ou non).
  Future<List<dynamic>> fetchProjects({String? authToken}) async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.origin}/api/projects"),
        headers: {
          "Content-Type": "application/json",
          if (authToken != null && authToken.isNotEmpty)
            "Authorization": "Bearer $authToken",
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded is List ? decoded : <dynamic>[];
      }
      return [];
    } catch (e) {
      // ignore: avoid_print
      print("❌ Erreur fetchProjects: $e");
      return [];
    }
  }

  /// Projets publiés par le client connecté (JWT requis).
  Future<List<dynamic>> fetchMyProjects(String token) async {
  final response = await http.get(
    Uri.parse("${ApiConfig.origin}/api/projects/my"),
    headers: {"Authorization": "Bearer $token"},
  );
  
  // ✅ Ajoute ces logs
  print("📡 fetchMyProjects status: ${response.statusCode}");
  print("📡 fetchMyProjects body: ${response.body}");
  
  if (response.statusCode == 200) {
    final list = jsonDecode(response.body);
    return list is List ? list : <dynamic>[];
  }
  if (response.statusCode == 401) {
    throw Exception("Session expirée — reconnecte-toi.");
  }
  throw Exception("Erreur lors du chargement de tes projets");
}
  // --- 3. POUR LE CLIENT : POSTER UN NOUVEAU PROJET ---
  // On ajoute le 'token' car ta route backend utilise 'requireAuth'
  Future<bool> addProject(
    Map<String, dynamic> projectData,
    String token,
  ) async {
    try {
      // Conversion forcée du budget en nombre pour éviter l'erreur au Backend
      if (projectData.containsKey('budget')) {
        projectData['budget'] =
            int.tryParse(projectData['budget'].toString()) ?? 0;
      }

      final response = await http.post(
        Uri.parse("${ApiConfig.origin}/api/projects/add"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(projectData),
      );

      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 201) {
        return true;
      } else {
        // Regarde ton terminal VS Code ici pour voir l'erreur exacte
        return false;
      }
    } catch (e) {
      print("Erreur connexion: $e");
      return false;
    }
  }
}
