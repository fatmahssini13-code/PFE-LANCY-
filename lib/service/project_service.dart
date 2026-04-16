import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pfe/config/api_config.dart';
import 'auth_service.dart';

class ProjectService {
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

      print("📡 STATUS: ${response.statusCode}");
      print("📡 BODY: ${response.body}");

      return response.statusCode == 201;
    } catch (e) {
      print("❌ ERROR: $e");
      return false;
    }
  }
}