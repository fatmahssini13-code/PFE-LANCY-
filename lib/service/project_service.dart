import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pfe/config/api_config.dart';
import 'auth_service.dart';

class ProjectService {

  // ===============================
  // 🟢 CREATE PROJECT
  // ===============================
  Future<bool> createProject(
    String title,
    String description,
    String budget,
    String email,
  ) async {
    try {
      String? token = await AuthService.getToken();

      final res = await http.post(
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

      print("CREATE STATUS: ${res.statusCode}");
      return res.statusCode == 201;
    } catch (e) {
      print("❌ CREATE ERROR: $e");
      return false;
    }
  }

  // ===============================
  // 🟡 UPDATE PROJECT
  // ===============================
  static Future<void> updateProject(String id, Map<String, dynamic> data) async {
    final token = await AuthService.getToken();

    final res = await http.put(
      Uri.parse("${ApiConfig.baseURL}/projects/update/$id"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(data),
    );

    if (res.statusCode != 200) {
      throw Exception(jsonDecode(res.body)["message"]);
    }
  }

  // ===============================
  // 🔴 DELETE PROJECT
  // ===============================
  static Future<void> deleteProject(String id) async {
    final token = await AuthService.getToken();

    final res = await http.delete(
      Uri.parse("${ApiConfig.baseURL}/projects/delete/$id"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Delete error");
    }
  }

  // ===============================
  // 💰 ACCEPT PROPOSAL
  // ===============================
  Future<bool> acceptProposal(String proposalId) async {
    try {
      final token = await AuthService.getToken();

      final res = await http.put(
        Uri.parse("${ApiConfig.baseURL}/proposals/$proposalId/accept"),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      print("ACCEPT STATUS: ${res.statusCode}");
      return res.statusCode == 200;
    } catch (e) {
      print("❌ ACCEPT ERROR: $e");
      return false;
    }
  }

  // ===============================
  // 📦 DELIVER WORK
  // ===============================
 Future<bool> deliverProject(String projectId, String link, String message) async {
    try {
      final token = await AuthService.getToken();
      final res = await http.put(
        Uri.parse("${ApiConfig.baseURL}/projects/$projectId/deliver"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "link": link,
          "message": message,
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      print("Error delivering: $e");
      return false;
    }
  }

  // ===============================
  // 💸 RELEASE PAYMENT
  // ===============================
  Future<bool> releasePayment(String projectId) async {
    try {
      final token = await AuthService.getToken();

      final res = await http.put(
        Uri.parse("${ApiConfig.baseURL}/payment/$projectId/release"),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      print("RELEASE STATUS: ${res.statusCode}");
      return res.statusCode == 200;
    } catch (e) {
      print("❌ RELEASE ERROR: $e");
      return false;
    }
  }
 Future<Map<String, dynamic>> createPaymentIntent(String projectId) async {
  // Récupère le token pour que le serveur sache qui paie
  final token = await AuthService.getToken();

  final response = await http.post(
    Uri.parse("${ApiConfig.baseURL}/payment/create-intent"),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token", // Ajoute cette ligne
    },
    body: jsonEncode({
      "projectId": projectId,
    }),
  );

  return jsonDecode(response.body);
}

}
