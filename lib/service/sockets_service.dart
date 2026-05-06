import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:pfe/config/api_config.dart';

class SocketService {
  late IO.Socket socket;

  void connect(String userId) {
    socket = IO.io(
      ApiConfig.origin,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket.connect();

    socket.onConnect((_) {
      print("✅ Socket connecté");
      socket.emit("join", userId); // مهم
    });

    socket.on("notification", (data) {
      print("🔔 Notification: $data");

      Get.snackbar(
        data["title"] ?? "Notification",
        data["message"] ?? "",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.black,
        colorText: Colors.white,
      );
    });

    socket.onDisconnect((_) {
      print("❌ Socket disconnected");
    });
  }
}