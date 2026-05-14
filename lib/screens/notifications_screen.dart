import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pfe/config/api_config.dart';
import 'package:pfe/service/notification_service.dart';
import 'package:pfe/service/auth_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  final NotificationService _service = NotificationService();

  // ── Lancy Brand ─────────────────────────────────────
  static const Color _blue    = Color(0xFF00D2FF);
  static const Color _purple  = Color(0xFF9249FD);
  static const Color _dark    = Color(0xFF1A1A2E);
  static const Color _bgLight = Color(0xFFF4F6FF);
  static const LinearGradient _grad = LinearGradient(
    colors: [_blue, _purple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;

  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _loadNotifications();
    _markAllRead();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _markAllRead() async {
    final token = await AuthService.getToken();
    await http.put(
      Uri.parse('${ApiConfig.baseURL}/notifications/read-all'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Future<void> _loadNotifications() async {
    setState(() => _loading = true);
    final token = await AuthService.getToken();
    if (token == null) {
      setState(() => _loading = false);
      return;
    }
    final data = await _service.getNotifications(token);
    setState(() {
      _notifications = data;
      _loading       = false;
    });
    _animCtrl.forward(from: 0);
  }

  // ── Helpers ──────────────────────────────────────────
  String _notifType(String? title) {
    final t = (title ?? '').toLowerCase();
    if (t.contains('acceptée') || t.contains('accepté')) return 'accepted';
    if (t.contains('refusée') || t.contains('refusé'))  return 'rejected';
    if (t.contains('livré'))                             return 'delivered';
    if (t.contains('payé') || t.contains('paiement'))   return 'payment';
    return 'new';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          if (_loading)
            const SliverFillRemaining(child: _LancyLoader())
          else if (_notifications.isEmpty)
            SliverFillRemaining(child: _buildEmpty())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _buildItemWithHeader(i),
                  childCount: _notifications.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── App Bar ──────────────────────────────────────────
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: _purple,
      foregroundColor: Colors.white,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: TextButton(
            onPressed: _markAllRead,
            child: Text(
              'Tout lire',
              style: GoogleFonts.plusJakartaSans(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w700,
                  fontSize: 13),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: _grad),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Notifications',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_notifications.length} notification${_notifications.length != 1 ? 's' : ''}',
                    style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.75), fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
        title: Text('Notifications',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: Colors.white)),
        titlePadding: const EdgeInsets.only(left: 56, bottom: 14),
      ),
    );
  }

  // ── List item with date header ────────────────────────
  Widget _buildItemWithHeader(int index) {
    final notif = _notifications[index];
    final dateStr = notif['createdAt']?.toString() ?? '';
    final date = DateTime.tryParse(dateStr) ?? DateTime.now();
    final now  = DateTime.now();

    bool   showHeader  = false;
    String headerLabel = '';

    if (index == 0) {
      showHeader = true;
    } else {
      final prev = DateTime.tryParse(
          _notifications[index - 1]['createdAt'].toString());
      if (prev != null && date.day != prev.day) showHeader = true;
    }

    if (showHeader) {
      if (date.day == now.day && date.month == now.month) {
        headerLabel = "Aujourd'hui";
      } else if (date.day == now.subtract(const Duration(days: 1)).day) {
        headerLabel = 'Hier';
      } else {
        headerLabel = DateFormat('dd MMM yyyy', 'fr_FR').format(date);
      }
    }

    final animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: Interval(
          (index / _notifications.length).clamp(0.0, 1.0),
          1.0,
          curve: Curves.easeOut,
        ),
      ),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
                begin: const Offset(0, 0.15), end: Offset.zero)
            .animate(animation),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader) _buildDateHeader(headerLabel),
            _buildNotifCard(notif),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 0, 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 14,
            decoration: BoxDecoration(
                gradient: _grad, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: _purple.withOpacity(0.7),
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifCard(Map<String, dynamic> notif) {
    final type   = _notifType(notif['title']);
    final isRead = notif['read'] ?? notif['isRead'] ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: isRead
                ? Colors.black.withOpacity(0.04)
                : _purple.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: isRead
            ? null
            : Border.all(color: _purple.withOpacity(0.15)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Unread indicator bar
              if (!isRead)
                Container(
                  width: 4,
                  decoration: const BoxDecoration(gradient: _grad),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAvatar(type, notif),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    notif['title'] ?? '',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: isRead
                                          ? FontWeight.w600
                                          : FontWeight.w800,
                                      color: _dark,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  notif['time'] ?? _timeAgo(notif['createdAt']),
                                  style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: Colors.grey.shade400),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notif['message'] ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String type, Map<String, dynamic> notif) {
    if (type == 'accepted') {
      return _avatarContainer(
          Colors.green.shade50, const Text('🎉', style: TextStyle(fontSize: 20)));
    }
    if (type == 'rejected') {
      return _avatarContainer(
          Colors.red.shade50,
          Icon(Icons.close_rounded, color: Colors.red.shade400, size: 20));
    }
    if (type == 'payment') {
      return _avatarContainer(
          Colors.amber.shade50,
          Icon(Icons.payments_rounded, color: Colors.amber.shade600, size: 20));
    }
    if (type == 'delivered') {
      return _avatarContainer(
          Colors.blue.shade50,
          Icon(Icons.inventory_2_outlined, color: Colors.blue.shade400, size: 20));
    }
    // Default: gradient avatar with initials
    final msg = notif['message']?.toString() ?? '';
    final initials = msg.trim().isNotEmpty
        ? msg.trim()[0].toUpperCase()
        : '?';
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: _grad,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              color: _purple.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Center(
        child: Text(initials,
            style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16)),
      ),
    );
  }

  Widget _avatarContainer(Color bg, Widget child) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Center(child: child),
    );
  }

  String _timeAgo(dynamic raw) {
    if (raw == null) return '';
    final dt = DateTime.tryParse(raw.toString());
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inHours < 1)   return 'Il y a ${diff.inMinutes} min';
    if (diff.inDays < 1)    return 'Il y a ${diff.inHours} h';
    return 'Il y a ${diff.inDays} j';
  }

  // ── Empty State ──────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _blue.withOpacity(0.07),
                  _purple.withOpacity(0.07),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: ShaderMask(
              shaderCallback: (b) => _grad.createShader(b),
              child: const Icon(Icons.notifications_none_rounded,
                  size: 56, color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          Text('Tout est calme ici',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 18, fontWeight: FontWeight.w800, color: _dark)),
          const SizedBox(height: 8),
          Text(
            'Vous recevrez une notification dès\nqu\'il y a du nouveau.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Shared Loader ────────────────────────────────────
class _LancyLoader extends StatelessWidget {
  const _LancyLoader();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [Color(0xFF00D2FF), Color(0xFF9249FD)],
            ).createShader(b),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.white),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text('Chargement...',
              style: GoogleFonts.inter(
                  color: Colors.grey.shade500, fontSize: 13)),
        ],
      ),
    );
  }
}