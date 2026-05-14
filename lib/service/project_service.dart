import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pfe/config/api_config.dart';
import 'auth_service.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
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
  Future<List<dynamic>> getMyProjects({required String role}) async {
  try {
    final token = await AuthService.getToken();
   final endpoint = role == 'freelancer'
        ? "${ApiConfig.baseURL}/projects/freelancer"
        : "${ApiConfig.baseURL}/projects/my";

    final res = await http.get(
     Uri.parse(endpoint),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      print("❌ ERROR: ${res.body}");
      return [];
    }
  } catch (e) {
    print("❌ EXCEPTION: $e");
    return [];
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
    
    debugPrint("=== DELIVER projectId: $projectId ===");
    debugPrint("=== token: $token ===");
    debugPrint("=== URL: ${ApiConfig.baseURL}/projects/$projectId/deliver ===");
    
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
    
    debugPrint("=== STATUS: ${res.statusCode} ===");
    debugPrint("=== BODY: ${res.body} ===");
    
    return res.statusCode == 200;
  } catch (e) {
    debugPrint("❌ Error delivering: $e");
    return false;
  }
}
  // ===============================
  // 💸 RELEASE PAYMENT
  // ===============================
Future<bool> releasePayment(String projectId) async {
  try {
    final token = await AuthService.getToken();

    // ✅ POST au lieu de PUT, projectId dans le body
    final res = await http.post(
      Uri.parse("${ApiConfig.baseURL}/payment/release"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "projectId": projectId,  // ✅ dans le body
      }),
    );

    debugPrint("=== RELEASE STATUS: ${res.statusCode} ===");
    debugPrint("=== RELEASE BODY: ${res.body} ===");

    return res.statusCode == 200;
  } catch (e) {
    debugPrint("❌ RELEASE ERROR: $e");
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
Future<bool> uploadDeliveryFile(
  String projectId,
  File? file,
  String link,
) async {
  final token = await AuthService.getToken();

  var request = http.MultipartRequest(
    'PUT',
    Uri.parse("${ApiConfig.baseURL}/projects/$projectId/deliver"),
  );

  request.headers['Authorization'] = "Bearer $token";

  request.fields['link'] = link;

  if (file != null) {
    request.files.add(
      await http.MultipartFile.fromPath('file', file.path),
    );
  }

  var response = await request.send();

  return response.statusCode == 200;
}
Future<Map<String, dynamic>> getProjectById(String id) async {
  try {
    final token = await AuthService.getToken();

    final res = await http.get(
      Uri.parse("${ApiConfig.baseURL}/projects/$id"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load project");
    }
  } catch (e) {
    throw Exception("ERROR: $e");
  }
}
}  
    

