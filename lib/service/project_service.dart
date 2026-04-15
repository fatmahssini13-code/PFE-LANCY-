import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ProjectService {
  final String baseUrl = "http://192.168.100.13:5000/api/projects";
  
  get AuthService => null;

  Future<bool> createProject(
    String title,
    String description,
    String budget,
    String email,
  ) async {
    try {
      String? token = await AuthService.getToken();

      print("🔵 TOKEN: $token");
      print("Envoi vers backend - Email: '$email', Budget: $budget");

      final response = await http.post(
        Uri.parse("$baseUrl/add"),
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

      print("📡 STATUS: ${response.statusCode}");
      print("📡 BODY: ${response.body}");

      return response.statusCode == 201;
    } catch (e) {
      print("❌ ERROR: $e");
      return false;
    }
  }
}