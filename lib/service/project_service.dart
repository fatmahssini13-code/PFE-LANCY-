import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pfe/config/api_config.dart';
import 'auth_service.dart';

class ProjectService {
  
  // --- CRÉER UN PROJET ---
  Future<bool> createProject(
    String title,
    String description,
    String budget,
    String email,
  ) async {
    try {
      // Correction ici : On appelle AuthService.getToken()
      String? token = await AuthService.getToken();

      final response = await http.post(
        Uri.parse("${ApiConfig.baseURL}/projects/add"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "title": title,
          "description": description,
          "budget": int.tryParse(budget) ?? 0,
          "clientEmail": email,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      print("❌ ERROR CREATE: $e");
      return false;
    }
  }

  // --- MODIFIER UN PROJET ---
  // On enlève "static" pour rester cohérent avec createProject, 
  // ou on le garde si tu veux l'appeler sans instancier la classe.
  static Future<void> updateProject(String id, Map<String, dynamic> data) async {
    final token = await AuthService.getToken(); // Correction ici
    final url = Uri.parse("${ApiConfig.baseURL}/projects/update/$id");

    final res = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(data),
    );

    if (res.statusCode != 200) {
      final errorBody = jsonDecode(res.body);
      throw Exception(errorBody["message"] ?? "Échec de la modification");
    }
  }

  // --- SUPPRIMER UN PROJET ---
  static Future<void> deleteProject(String id) async {
    final token = await AuthService.getToken(); // Correction ici
    final url = Uri.parse("${ApiConfig.baseURL}/projects/delete/$id");

    final res = await http.delete(
      url,
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Échec de la suppression");
    }
  }
}