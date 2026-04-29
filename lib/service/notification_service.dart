import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pfe/config/api_config.dart';

class NotificationService {
  final String baseUrl = "${ApiConfig.origin}/api/notifications";

  Future<List<Map<String, dynamic>>> getNotifications(String token) async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {"Authorization": "Bearer $token"},
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => {
          'title': e['title'] ?? '',
          'message': e['message'] ?? '',
          'time': e['createdAt'] != null
            ? _formatTime(e['createdAt'])
            : '',
          'isRead': e['isRead'] ?? false,
          'isToday': e['createdAt'] != null ? _isToday(e['createdAt']) : false,
        }).toList();
      }
      return [];
    } catch (e) {
      print("❌ Notif error: $e");
      return [];
    }
  }
  bool _isToday(String isoDate) {
  final dt = DateTime.parse(isoDate).toLocal();
  final now = DateTime.now();
  return dt.year == now.year && dt.month == now.month && dt.day == now.day;
}

  Future<void> markAllRead(String token) async {
    try {
      await http.put(
        Uri.parse("$baseUrl/read-all"),
        headers: {"Authorization": "Bearer $token"},
      );
    } catch (e) {
      print("❌ Mark read error: $e");
    }
  }

  String _formatTime(String isoDate) {
    final dt = DateTime.parse(isoDate).toLocal();
    return "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }
}