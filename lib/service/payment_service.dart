import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:pfe/config/api_config.dart';
import 'package:pfe/service/auth_service.dart';

class PaymentService {
  static Future<Map<String, dynamic>?> createPaymentIntent(String projectId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseURL}/payment/create-intent'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'projectId': projectId}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print("Erreur PaymentService: $e");
      return null;
    }
  }
  static Future<void> initAndPresentPaymentSheet(String projectId, String token, BuildContext context) async {
    try {
      // 1. Appeler ton backend pour obtenir le clientSecret
      final data = await createPaymentIntent(projectId, token);
      
      if (data == null || data['clientSecret'] == null) {
        throw Exception("Impossible de récupérer le secret de paiement");
      }

      // 2. Initialiser la feuille de paiement Stripe
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: data['clientSecret'],
          merchantDisplayName: 'Lancy Freelance',
          style: ThemeMode.light,
        ),
      );

      // 3. Afficher l'interface de paiement à l'utilisateur
      await Stripe.instance.presentPaymentSheet();

      // 4. Succès !
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Paiement séquestre réussi ! ✅"), backgroundColor: Colors.green),
      );
      
      // Ici, tu peux naviguer vers un écran de succès ou rafraîchir le statut
    } catch (e) {
      if (e is StripeException) {
        print("Erreur Stripe: ${e.error.localizedMessage}");
      } else {
        print("Erreur générale: $e");
      }
    }
  }
  Future<bool> releasePayment(String projectId) async {
  try {
    final token = await AuthService.getToken();

    debugPrint("=== RELEASE projectId: $projectId ===");
    debugPrint("=== URL: ${ApiConfig.baseURL}/payment/$projectId/release ===");

    final res = await http.put(
      Uri.parse("${ApiConfig.baseURL}/payment/$projectId/release"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    debugPrint("=== STATUS: ${res.statusCode} ===");
    debugPrint("=== BODY: ${res.body} ===");

    return res.statusCode == 200;
  } catch (e) {
    debugPrint("❌ RELEASE ERROR: $e");
    return false;
  }
}
}
