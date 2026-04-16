import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatService {
  late IO.Socket socket;

  void connect(String userId, Function(dynamic) param1) {
    socket = IO.io('http://192.168.100.13:5000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    
    socket.connect();
    socket.emit('join', userId); // Identifie l'utilisateur sur le serveur

    socket.on('receive_message', (data) {
      print("Nouveau message : ${data['content']}");
      // Ici, utilise GetX pour mettre à jour l'interface du chat
    });
  }

  void sendMessage(String senderId, String receiverId, String content) {
    socket.emit('send_message', {
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
    });
  }
}