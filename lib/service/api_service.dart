import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:pfe/config/api_config.dart';



class ApiService {

  // --- INSCRIPTION ---

  static Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {

    final url = Uri.parse("${ApiConfig.baseURL}/auth/register");

   

    try {

      final res = await http.post(

        url,

        headers: {"Content-Type": "application/json"},

        body: jsonEncode(data),

      );



      if (res.statusCode == 201) {

        return jsonDecode(res.body) as Map<String, dynamic>;

      } else {

        final errorData = jsonDecode(res.body);

        throw Exception(errorData['message'] ?? "Erreur lors de l'inscription");

      }

    } catch (e) {

      throw Exception("Impossible de se connecter au serveur 🌐");

    }

  }



  // --- VÉRIFICATION OTP (Inscription & Reset) ---

  static Future<Map<String, dynamic>> verifyOTP({

    required String email,

    required String code,

    required bool isFromRegister

  }) async {

    final url = Uri.parse("${ApiConfig.baseURL}/auth/verify-otp");

   

    try {

      final res = await http.post(

        url,

        headers: {"Content-Type": "application/json"},

        body: jsonEncode({

          "email": email,

          "code": code,

          "isFromRegister": isFromRegister, // On envoie l'info au backend

        }),

      );



      if (res.statusCode == 200) {

        return jsonDecode(res.body);

      } else {

        final errorData = jsonDecode(res.body);

        throw Exception(errorData['message'] ?? "Code invalide");

      }

    } catch (e) {

      throw Exception("Erreur de connexion lors de la vérification");

    }

  }



  // --- MOT DE PASSE OUBLIÉ (Envoi du mail) ---

  static Future<void> forgotPassword(String email) async {

    final url = Uri.parse("${ApiConfig.baseURL}/auth/forgot-password");

   

    try {

      final res = await http.post(

        url,

        headers: {"Content-Type": "application/json"},

        body: jsonEncode({"email": email}),

      );



      if (res.statusCode != 200) {

        final errorData = jsonDecode(res.body);

        throw Exception(errorData['message'] ?? "Erreur d'envoi");

      }

    } catch (e) {

      throw Exception("Serveur injoignable");

    }

  }

}