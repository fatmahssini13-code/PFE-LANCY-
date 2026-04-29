import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatService {
  late IO.Socket socket;

  void connect(String userId, Function(dynamic) onMessage) {
    socket = IO.io('http://192.168.100.13:5001', {
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.onConnect((_) {
      print("✅ Connected");
      socket.emit('join', userId);
    });

    socket.on('receive_message', (data) {
      print("📩 Nouveau message : ${data['text']}");
      onMessage(data); // 🔥 update UI
    });
  }
  void sendMessage(String senderId, String receiverId, String content,String projectId) {
   socket.emit('send_message', {
  'senderId': senderId,
  'receiverId': receiverId,
  'text': content,
  'projectId': projectId,
});
  }
   void disconnect() {
    socket.disconnect();
  }
}