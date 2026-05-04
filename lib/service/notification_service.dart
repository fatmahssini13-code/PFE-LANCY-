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
        return data
            .map(
              (e) => {
                'title': e['title'] ?? '',
                'message': e['message'] ?? '',
                'createdAt': e['createdAt'], // 🔥 AJOUT CRUCIAL
                'time': _formatTime(e['createdAt']),
                'isRead': e['isRead'] ?? false,
                'isToday': _isToday(e['createdAt']),
              },
            )
            .toList();
      }
      return [];
    } catch (e) {
      print("❌ Notif error: $e");
      return [];
    }
  }

  bool _isToday(dynamic isoDate) {
    if (isoDate == null) return false;

    final dt = DateTime.tryParse(isoDate.toString());
    if (dt == null) return false;

    final local = dt.toLocal();
    final now = DateTime.now();

    return local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
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

  String _formatTime(dynamic isoDate) {
    if (isoDate == null) return '';

    final dt = DateTime.tryParse(isoDate.toString());
    if (dt == null) return '';

    final local = dt.toLocal();
    return "${local.hour}:${local.minute.toString().padLeft(2, '0')}";
  }
}
