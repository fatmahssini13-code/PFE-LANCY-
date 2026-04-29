import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../service/message_service.dart';

class ChatScreen extends StatefulWidget {
  final String currentUserId;
  final String receiverId;
  final String receiverName;
  final String projectId;

  const ChatScreen({
    super.key,
    required this.currentUserId,
    required this.receiverId,
    required this.receiverName,
    required this.projectId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List messages = [];
  final controller = TextEditingController();
  final scrollController = ScrollController();

  late IO.Socket socket;

  @override
  void initState() {
    super.initState();
    initSocket();
    loadMessages();
  }

  void initSocket() {
    socket = IO.io("http://192.168.100.13:5001", {
      "transports": ["websocket"],
      "autoConnect": true,
    });

    socket.onConnect((_) {
      socket.emit("join", widget.currentUserId);
    });

    socket.on("receive_message", (data) {
      setState(() {
        messages.add(data);
      });

      scrollToBottom();
    });
  }

  Future<void> loadMessages() async {
    final data = await MessageService.getMessages(widget.projectId);
    setState(() => messages = data);
  }

  void send() {
    if (controller.text.trim().isEmpty) return;

    final text = controller.text;

    socket.emit("send_message", {
      "senderId": widget.currentUserId,
      "receiverId": widget.receiverId,
      "projectId": widget.projectId,
      "text": text,
    });

    controller.clear();
  }

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    socket.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.receiverName)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: messages.length,
              itemBuilder: (_, i) {
                final msg = messages[i];
                final isMe = msg["senderId"] == widget.currentUserId;

                return Align(
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(msg["text"] ?? ""),
                  ),
                );
              },
            ),
          ),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: "Message...",
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: send,
              )
            ],
          )
        ],
      ),
    );
  }
}