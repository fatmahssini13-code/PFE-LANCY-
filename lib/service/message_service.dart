import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class MessageService {

  // ➜ GET messages
  static Future<List> getMessages(String projectId) async {
    final url = Uri.parse("${ApiConfig.baseURL}/messages/$projectId");

    final res = await http.get(url);

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      return [];
    }
  }

  // ➜ SEND message (REST)
  static Future<void> sendMessage(
    String projectId,
    String senderId,
    String receiverId,
    String text,
  ) async {

    final url = Uri.parse("${ApiConfig.baseURL}/messages");

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "projectId": projectId,
        "senderId": senderId,
        "receiverId": receiverId,
        "text": text,
      }),
    );

    if (res.statusCode != 201) {
      throw Exception("Erreur envoi message");
    }
  }
}