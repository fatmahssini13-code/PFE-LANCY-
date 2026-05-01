import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  final String baseUrl = "http://192.168.100.13:5001/api/";
  final String token;

  GeminiService(this.token);

  Future<String> sendMessage(String message) async {
    final response = await http.post(
      Uri.parse("$baseUrl/chat-gemini"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "message": message,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["reply"] ?? "No response";
    } else {
      return "Error: ${response.body}";
    }
  }
}