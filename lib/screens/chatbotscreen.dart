import 'package:flutter/material.dart';
import 'package:pfe/service/gemini_service.dart';
import 'package:pfe/Model/chatModel.dart';

class ChatBotScreen extends StatefulWidget {
  final String token;

  ChatBotScreen({required this.token});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  late GeminiService service;
  TextEditingController controller = TextEditingController();

  List<ChatMessage> messages = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    service = GeminiService(widget.token);
  }

  void sendMessage() async {
    String text = controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add(ChatMessage(text: text, isUser: true));
      loading = true;
    });

    controller.clear();

    String reply = await service.sendMessage(text);

    setState(() {
      messages.add(ChatMessage(text: reply, isUser: false));
      loading = false;
    });
  }

  Widget buildMessage(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.all(12),
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: msg.isUser ? Colors.blue : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            color: msg.isUser ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("AI Chatbot"),
      ),
      body: Column(
        children: [

          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return buildMessage(messages[index]);
              },
            ),
          ),

          if (loading)
            Padding(
              padding: EdgeInsets.all(8),
              child: Text("AI is typing... 🤖"),
            ),

          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [

                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: "Type message...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                SizedBox(width: 8),

                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: sendMessage,
                )

              ],
            ),
          ),
        ],
      ),
    );
  }
}