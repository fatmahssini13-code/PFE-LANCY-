import 'package:flutter/material.dart';
import '../../service/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String currentUserId;
  final String receiverId;
  final String receiverName;

  const ChatScreen({
    super.key,
    required this.currentUserId,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ChatService _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    // Connexion et écoute
    _chatService.connect(widget.currentUserId, (data) {
      setState(() {
        _messages.add(data as Map<String, dynamic>);
      });
    });
  }

  void _send() {
    if (_messageController.text.isNotEmpty) {
      _chatService.sendMessage(
        widget.currentUserId,
        widget.receiverId,
        _messageController.text,
      );
      setState(() {
        _messages.add({
          'senderId': widget.currentUserId,
          'message': _messageController.text,
        });
      });
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.receiverName)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                bool isMe =
                    _messages[index]['senderId'] == widget.currentUserId;
                return Align(
                  alignment: isMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.symmetric(
                      vertical: 5,
                      horizontal: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isMe
                          ? Colors.blue[200]
                          : Colors.pink[100], // Style un peu girly
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(_messages[index]['message']),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _messageController)),
                IconButton(icon: const Icon(Icons.send), onPressed: _send),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
