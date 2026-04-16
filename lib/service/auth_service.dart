import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class AuthService {
  static Future<void> _persistAuthPayload(Map<String, dynamic> data) async {
    final token = data["token"];
    if (token is! String || token.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("token", token);

    final user = data["user"];
    if (user is Map) {
      final u = Map<String, dynamic>.from(user);
      final uEmail = u["email"]?.toString();
      final role = u["role"]?.toString();
      final uName = u["name"]?.toString();
      if (uEmail != null && uEmail.isNotEmpty) {
        await prefs.setString("user_email", uEmail);
      }
      if (role != null && role.isNotEmpty) {
        await prefs.setString("user_role", role);
      }
      if (uName != null && uName.trim().isNotEmpty) {
        await prefs.setString("user_name", uName.trim());
      }
    } else if (data["role"] != null) {
      await prefs.setString("user_role", data["role"].toString());
    }
  }

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
      "email": email.trim().toLowerCase(),
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

  // --- LOGIN ---
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse("${ApiConfig.baseURL}/auth/login");

    try {
      final res = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "email": email.trim().toLowerCase(),
              "password": password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      Map<String, dynamic> data;
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is! Map) {
          throw Exception(
            "Réponse invalide (HTTP ${res.statusCode}) — vérifie que le backend répond en JSON sur le port ${ApiConfig.apiPort}",
          );
        }
        data = Map<String, dynamic>.from(decoded);
      } on FormatException {
        throw Exception(
          "Réponse non JSON (HTTP ${res.statusCode}). Vérifie l’URL API et que Node écoute sur le port ${ApiConfig.apiPort}.",
        );
      }

      if (res.statusCode != 200) {
        final msg = data["message"]?.toString() ?? "Erreur ${res.statusCode}";
        throw Exception(msg);
      }

      if (data["token"] == null) {
        throw Exception("Le serveur n'a pas renvoyé de token.");
      }

      await _persistAuthPayload(data);

      return data;
    } on TimeoutException {
      throw Exception(
        "Délai dépassé — vérifie le Wi‑Fi et que le backend tourne (port ${ApiConfig.apiPort}).",
      );
    } on http.ClientException {
      throw Exception(
        "Connexion impossible — lance le serveur Node sur le port ${ApiConfig.apiPort}.",
      );
    }
  }

  // --- GESTION DU TOKEN & LOGOUT ---
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("user_email");
  }

  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("user_role");
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("user_name");
  }

  static Future<void> saveUserName(String name) async {
    final n = name.trim();
    if (n.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("user_name", n);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
    await prefs.remove("user_role");
    await prefs.remove("user_email");
    await prefs.remove("user_name");
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
    required String code,
    required bool isFromRegister,
  }) async {
    final url = Uri.parse("${ApiConfig.baseURL}/auth/verify-otp");

    try {
      final res = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "email": email.trim().toLowerCase(),
              "code": code,
              "isFromRegister": isFromRegister,
            }),
          )
          .timeout(const Duration(seconds: 20));

      Map<String, dynamic> data;
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is! Map) {
          throw Exception("Réponse serveur invalide (OTP)");
        }
        data = Map<String, dynamic>.from(decoded);
      } on FormatException {
        throw Exception(
          "Réponse non JSON — vérifie le backend (port ${ApiConfig.apiPort})",
        );
      }

      if (res.statusCode != 200) {
        throw Exception(
          data["message"]?.toString() ?? "Échec de la vérification du code",
        );
      }

      if (data["token"] != null) {
        await _persistAuthPayload(data);
      }
    } on TimeoutException {
      throw Exception("Délai dépassé lors de la vérification OTP");
    } on http.ClientException {
      throw Exception("Connexion impossible au serveur");
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