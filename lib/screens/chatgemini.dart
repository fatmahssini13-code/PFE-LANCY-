import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatGeminiScreen extends StatefulWidget {
  @override
  State<ChatGeminiScreen> createState() => _ChatGeminiScreenState();
}

class _ChatGeminiScreenState extends State<ChatGeminiScreen> {
  TextEditingController messageController = TextEditingController();
  String reply = "";
  bool loading = false;

  Future<void> sendMessage() async {
    setState(() {
      loading = true;
      reply = "";
    });

    final url = Uri.parse("http://192.168.100.13:5001/api/chat-gemini");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "message": messageController.text,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        reply = data["reply"] ?? "pas de réponse IA";
      });
    } else {
      setState(() {
        reply = "API Error: ${response.body}";
      });
    }

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat Gemini"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [

            TextField(
              controller: messageController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "votre question...",
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 10),

            ElevatedButton(
              onPressed: loading ? null : sendMessage,
              child: loading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text("Envoyer"),
            ),

            SizedBox(height: 20),

            if (reply.isNotEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(reply),
              ),
          ],
        ),
      ),
    );
  }
}