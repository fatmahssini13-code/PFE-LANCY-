import 'dart:convert';
import 'package:http/http.dart' as http;

class ProposalService {
  final String baseUrl = "http://192.168.100.13:5001/api/proposals";

  /// 🔹 CREATE PROPOSAL
  Future<bool> createProposal({
    required String token,
    required String projectId,
    required String coverLetter,
    required int price,
    required int deliveryTime,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl), // ✅ FIX (ما عادش /proposals)
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "projectId": projectId,
          "price": price,
          "deliveryTime": deliveryTime,
          "coverLetter": coverLetter,
        }),
      );

      // ✅ Debug مهم
      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");

      return response.statusCode == 201;
    } catch (e) {
      print("❌ Create Error: $e");
      return false;
    }
  }

  /// 🔹 GET PROPOSALS
  Future<List<dynamic>> getProposals(String token, String projectId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/project/$projectId"),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return [];
    } catch (e) {
      print("❌ Get Error: $e");
      return [];
    }
  }

  /// 🔹 ACCEPT PROPOSAL
  Future<bool> acceptProposal(String token, String id) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/$id/accept"),
        headers: {"Authorization": "Bearer $token"},
      );

      return response.statusCode == 200;
    } catch (e) {
      print("❌ Accept Error: $e");
      return false;
    }
  }

  /// 🔹 REJECT PROPOSAL
  Future<bool> rejectProposal(String token, String id) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/$id/reject"),
        headers: {"Authorization": "Bearer $token"},
      );

      return response.statusCode == 200;
    } catch (e) {
      print("❌ Reject Error: $e");
      return false;
    }
  }
}