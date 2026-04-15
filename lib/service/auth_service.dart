import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class AuthService {
  // --- REGISTER ---
  static Future<void> register({
    required String email,
    required String password,
    required String name,
    required String role,
    String? skills,
    String? bio,
  }) async {
    final url = Uri.parse("${ApiConfig.baseURL}/auth/register");

    final Map<String, dynamic> requestBody = {
      "name": name,
      "email": email,
      "password": password,
      "role": role,
      "skills": skills ?? "",
      "bio": bio ?? "",
    };

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(requestBody),
    );

    if (res.statusCode != 201) {
      throw Exception(jsonDecode(res.body)["message"] ?? "Register failed");
    }
  }

  // --- LOGIN (Version Corrigée) ---
  static Future<dynamic> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse("${ApiConfig.baseURL}/auth/login");

    try {
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) {
        final errorData = jsonDecode(res.body);
        throw errorData["message"] ?? "Erreur serveur (${res.statusCode})";
      }

      final data = jsonDecode(res.body);

      if (data["token"] == null) {
        throw "Le serveur n'a pas renvoyé de token.";
      }

      // Sauvegarde des infos essentielles
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", data["token"]);
      
      // Sauvegarde du rôle pour l'affichage du profil dynamique
      if (data["role"] != null) {
        await prefs.setString("user_role", data["role"]);
      }

      return data;
    } catch (e) {
      if (e is FormatException) {
        throw "Format de réponse invalide (vérifie ton backend Node.js)";
      }
      throw e.toString();
    }
  }

  // --- GESTION DU TOKEN & LOGOUT ---
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
    await prefs.remove("user_role");
  }

  // --- RÉINITIALISATION DU MOT DE PASSE (OTP) ---
  static Future<void> forgotPassword({required String email}) async {
    final url = Uri.parse("${ApiConfig.baseURL}/auth/forgot-password");
    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );

    if (res.statusCode != 200) {
      throw Exception(jsonDecode(res.body)["message"] ?? "Failed to send OTP");
    }
  }

  static Future<void> verifyOTP({
    required String email,
    required String code, required bool isFromRegister,
  }) async {
    final url = Uri.parse("${ApiConfig.baseURL}/auth/verify-otp");
    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "code": code}),
    );

    if (res.statusCode != 200) {
      throw Exception(jsonDecode(res.body)["message"] ?? "OTP verification failed");
    }
  }

  static Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final url = Uri.parse("${ApiConfig.baseURL}/auth/reset-password");
    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "code": code,
        "newPassword": newPassword,
        "confirmPassword": confirmPassword,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception(jsonDecode(res.body)["message"] ?? "Password reset failed");
    }
  }
}