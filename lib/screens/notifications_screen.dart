import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfe/service/notification_service.dart';
import 'package:pfe/service/auth_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _service = NotificationService();
  final Color lancyPurple = const Color(0xFF8E2DE2);
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final token = await AuthService.getToken();
    if (token == null) {
      setState(() => _loading = false);
      return;
    }
    final data = await _service.getNotifications(token);
    setState(() {
      _notifications = data;
      _loading = false;
    });
  }

  Future<void> _markAllRead() async {
    final token = await AuthService.getToken();
    if (token == null) return;
    await _service.markAllRead(token);
    setState(() {
      for (var n in _notifications) {
        n['isRead'] = true;
      }
    });
  }

  // Récupère les initiales du nom dans le message
  String _getInitials(String message) {
    final parts = message.split(' ');
    if (parts.isEmpty) return '?';
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  // Détermine le type de notification
  String _getType(String title) {
    if (title.contains('acceptée')) return 'accepted';
    if (title.contains('refusée')) return 'rejected';
    return 'new';
  }

  // Groupe les notifications par date
  Map<String, List<Map<String, dynamic>>> _groupByDate() {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var notif in _notifications) {
      final time = notif['time'] ?? '';
      final key = notif['isToday'] == true ? "Aujourd'hui" : "Hier";
      grouped.putIfAbsent(key, () => []).add(notif);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text("Notifications",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: Text(
              "Tout marquer lu",
              style: GoogleFonts.inter(
                  color: lancyPurple, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: lancyPurple))
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: lancyPurple,
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      // Séparateur de date
                      final notif = _notifications[index];
                      final showTodayHeader = index == 0;
                      final showYesterdayHeader = index > 0 &&
                          _notifications[index - 1]['isToday'] == true &&
                          notif['isToday'] != true;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showTodayHeader) _buildDateHeader("Aujourd'hui"),
                          if (showYesterdayHeader) _buildDateHeader("Hier"),
                          _buildNotifCard(notif),
                        ],
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildDateHeader(String label) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFF8F9FA),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
          letterSpacing: 0.06,
        ),
      ),
    );
  }

Widget _buildNotifCard(Map<String, dynamic> notif) {
    final type = _getType(notif['title'] ?? '');
    final isRead = notif['isRead'] ?? true;
    final initials = _getInitials(notif['message'] ?? '');

    Color avatarBg;
    Widget avatarChild;
    Color cardBg;

    switch (type) {
      case 'accepted':
        avatarBg = Colors.green.shade50;
        avatarChild = const Text('🎉', style: TextStyle(fontSize: 20));
        cardBg = Colors.white;
        break;
      case 'rejected':
        avatarBg = Colors.red.shade50;
        avatarChild = Icon(Icons.close, color: Colors.red.shade300, size: 20);
        cardBg = Colors.white;
        break;
      default:
        avatarBg = lancyPurple;
        avatarChild = Text(
          initials,
          style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.w500, fontSize: 15),
        );
        cardBg = isRead ? Colors.white : const Color(0xFFEEEDFE);
    }

    return Container(
      // ✅ color dans BoxDecoration uniquement
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: avatarBg,
              shape: BoxShape.circle,
            ),
            child: Center(child: avatarChild),
          ),
          const SizedBox(width: 12),

          // Contenu
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        notif['title'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: type == 'new' && !isRead
                              ? const Color(0xFF3C3489)
                              : Colors.black87,
                        ),
                      ),
                    ),
                    Text(
                      notif['time'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: type == 'new' && !isRead
                            ? const Color(0xFF534AB7)
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  notif['message'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: type == 'new' && !isRead
                        ? const Color(0xFF534AB7)
                        : Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                if (!isRead && type == 'new') ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: lancyPurple,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      "Nouvelle",
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 80, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text("Aucune notification",
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 6),
          Text("Vous serez notifié ici",
              style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13)),
        ],
      ),
    );
  }
}