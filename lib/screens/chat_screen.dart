import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../config/api_config.dart';
import '../service/message_service.dart';

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
  final List<dynamic> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  IO.Socket? _socket;
  bool _connectingSocket = true;

  static const Color _blue = Color(0xFF00AEEF);
  static const Color _purple = Color(0xFF8E2DE2);
  static const Color _bg = Color(0xFFEEF2F7);
  static const Color _incomingFill = Color(0xFFF8FAFC);
  static const Color _incomingBorder = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    /** Socket + listeners immédiatement : les messages live ne sont pas perdus. */
    _initSocket();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMessages());
  }

  void _registerSocketRooms() {
    final s = _socket;
    if (s == null || !s.connected) return;
    /** Room utilisateur : cohérent avec notifications serveur (`io.to(userId)`). */
    s.emit('join', widget.currentUserId);
    /** Room projet : tous les chats ouverts sur cette mission reçoivent les messages en direct. */
    s.emit('join_project_chat', {
      'userId': widget.currentUserId,
      'projectId': widget.projectId,
    });
  }

  bool _sameProject(dynamic rawPid, String localPid) {
    final a = rawPid?.toString().trim() ?? '';
    final b = localPid.trim();
    return a.isNotEmpty && a == b;
  }

  void _initSocket() {
    _socket = IO.io(ApiConfig.socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'forceNew': false,
      'reconnection': true,
      'reconnectionDelay': 1000,
      'reconnectionAttempts': 120,
    });

    _socket!.onConnect((_) {
      _registerSocketRooms();
      if (mounted) setState(() => _connectingSocket = false);
    });

    _socket!.onReconnect((_) {
      _registerSocketRooms();
      if (mounted) setState(() => _connectingSocket = false);
    });

    _socket!.onConnectError((_) {
      if (mounted) setState(() => _connectingSocket = false);
    });

    _socket!.onDisconnect((_) {
      if (mounted) setState(() => _connectingSocket = true);
    });

    _socket!.on('message_error', (data) {
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((m) {
          if (m is! Map) return false;
          return m['_pending'] == true &&
              _sameUser(m['senderId'], widget.currentUserId);
        });
      });
      final msg = data is Map ? data['message']?.toString() : null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            msg ?? 'Impossible d’envoyer le message',
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    });

    _socket!.on('receive_message', (data) {
      if (!mounted || data == null || data is! Map) return;
      final normalized = <String, dynamic>{};
      for (final e in (data as Map).entries) {
        normalized[e.key.toString()] = e.value;
      }
      _addIncomingSocketMessage(normalized);
    });
  }

  int _timeMs(dynamic raw) {
    if (raw == null) return 0;
    return DateTime.tryParse(raw.toString())?.millisecondsSinceEpoch ?? 0;
  }

  int _compareMessageOrder(Map a, Map b) {
    final c = _timeMs(a['createdAt']).compareTo(_timeMs(b['createdAt']));
    if (c != 0) return c;
    final pa = a['_pending'] == true ? 1 : 0;
    final pb = b['_pending'] == true ? 1 : 0;
    return pa.compareTo(pb);
  }

  void _dedupeAndSortMessages() {
    final byId = <String, Map<String, dynamic>>{};
    final pending = <Map<String, dynamic>>[];
    for (final m in _messages) {
      if (m is! Map) continue;
      final map = Map<String, dynamic>.from(m);
      if (map['_pending'] == true) {
        pending.add(map);
        continue;
      }
      final id = _idString(map['_id']);
      if (id.isNotEmpty) {
        byId[id] = map;
      }
    }
    final merged = byId.values.toList()..addAll(pending);
    merged.sort(_compareMessageOrder);
    _messages
      ..clear()
      ..addAll(merged);
  }

  Future<void> _loadMessages() async {
    final raw = await MessageService.getMessages(widget.projectId);
    if (!mounted) return;

    final fromApi = <Map<String, dynamic>>[];
    for (final e in raw) {
      if (e is Map) fromApi.add(Map<String, dynamic>.from(e));
    }
    final idsFromApi =
        fromApi.map((m) => m['_id']?.toString()).whereType<String>().toSet();

    final kept = <Map<String, dynamic>>[];
    for (final m in List<dynamic>.from(_messages)) {
      if (m is! Map) continue;
      final mm = Map<String, dynamic>.from(m);
      if (mm['_pending'] == true) {
        kept.add(mm);
        continue;
      }
      final id = mm['_id']?.toString();
      if (id != null && id.isNotEmpty && !idsFromApi.contains(id)) {
        kept.add(mm);
      }
    }

    setState(() {
      _messages.clear();
      _messages.addAll(fromApi);
      _messages.addAll(kept);
      _dropDuplicatesPendingVsReal();
      _dedupeAndSortMessages();
    });
    _scrollToBottom();
  }

  void _addIncomingSocketMessage(Map<String, dynamic> map) {
    if (!_sameProject(map['projectId'], widget.projectId)) return;

    final txt = map['text']?.toString();

    setState(() {
      if (txt != null && _sameUser(map['senderId'], widget.currentUserId)) {
        _messages.removeWhere((m) {
          if (m is! Map) return false;
          return m['_pending'] == true &&
              _sameUser(m['senderId'], widget.currentUserId) &&
              m['text']?.toString() == txt;
        });
      }

      final mid = _idString(map['_id']);
      if (mid.isNotEmpty &&
          _messages.any(
            (m) => m is Map && _idString((m as Map)['_id']) == mid,
          )) {
        return;
      }

      _messages.add(Map<String, dynamic>.from(map));
      _dedupeAndSortMessages();
    });
    _scrollToBottom();
  }

  /// Une bulle "Envoi…" inutile si le même message est déjà en base.
  void _dropDuplicatesPendingVsReal() {
    for (var i = _messages.length - 1; i >= 0; i--) {
      final raw = _messages[i];
      if (raw is! Map) continue;
      final m = Map<String, dynamic>.from(raw);
      if (m['_pending'] != true) continue;
      final sid = _idString(m['senderId']);
      final txt = m['text']?.toString();
      if (sid.isEmpty || txt == null) continue;
      final superseded = _messages.any((o) {
        if (identical(o, raw) || o is! Map) return false;
        final om = Map<String, dynamic>.from(o as Map);
        if (om['_pending'] == true) return false;
        return _idString(om['senderId']) == sid &&
            om['text']?.toString() == txt;
      });
      if (superseded) _messages.removeAt(i);
    }
  }

  String _idString(dynamic v) {
    if (v == null) return '';
    if (v is Map && v[r'$oid'] != null) {
      return v[r'$oid'].toString().trim();
    }
    final s = v.toString().trim();
    if (s == 'null') return '';
    return s;
  }

  bool _sameUser(dynamic senderId, String userId) =>
      _idString(senderId).isNotEmpty &&
      userId.trim().isNotEmpty &&
      _idString(senderId) == userId.trim();

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final s = _socket;
    if (s == null || !s.connected) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Pas de connexion temps réel. Vérifie le réseau puis réessayez.',
          ),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final ts = DateTime.now().millisecondsSinceEpoch;
    final optimistic = {
      '_id': 'pending_$ts',
      'senderId': widget.currentUserId,
      'receiverId': widget.receiverId,
      'projectId': widget.projectId,
      'text': text,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      '_pending': true,
    };

    _controller.clear();

    setState(() {
      _messages.add(optimistic);
      _dedupeAndSortMessages();
    });
    _scrollToBottom();

    _registerSocketRooms();

    s.emit('send_message', {
      'senderId': widget.currentUserId,
      'receiverId': widget.receiverId,
      'projectId': widget.projectId,
      'text': text,
    });

    /** Sécurité : si aucun événement socket pour l’écho, resync court avec l’API. */
    Future.delayed(const Duration(milliseconds: 1200), () async {
      if (!mounted) return;
      final stuck = _messages.any((m) {
        if (m is! Map) return false;
        return (m['_pending'] == true) &&
            _sameUser(m['senderId'], widget.currentUserId);
      });
      if (!stuck) return;
      await _loadMessages();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (!mounted || !_scrollController.hasClients) return;
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      });
    });
  }

  String _bubbleTime(dynamic raw) {
    if (raw == null) return '';
    final dt =
        raw is String ? DateTime.tryParse(raw) : DateTime.tryParse('$raw');
    if (dt == null) return '';
    return DateFormat.Hm('fr_FR').format(dt.toLocal());
  }

  @override
  void dispose() {
    try {
      if (_socket?.connected ?? false) {
        _socket!.emit('leave_project_chat', {'projectId': widget.projectId});
      }
      _socket?.dispose();
    } catch (_) {}
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: _blue.withValues(alpha: 0.14),
              child: Text(
                widget.receiverName.isNotEmpty
                    ? widget.receiverName[0].toUpperCase()
                    : '?',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: _purple,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.receiverName,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Conversation mission',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Tooltip(
              message: _connectingSocket
                  ? 'Reconnexion…'
                  : 'Messagerie connectée',
              child: Icon(
                Icons.circle,
                size: 10,
                color: _connectingSocket
                    ? Colors.amber.shade700
                    : Colors.green.shade600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.forum_rounded,
                            size: 56,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun message pour l’instant',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Envoyez un message pour démarrer '
                            'l’échange avec ${widget.receiverName}.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              height: 1.4,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      if (msg is! Map) return const SizedBox.shrink();

                      final isMe =
                          _sameUser(msg['senderId'], widget.currentUserId);
                      final pending = msg['_pending'] == true;
                      final body = msg['text']?.toString() ?? '';
                      final time = pending
                          ? 'Envoi…'
                          : _bubbleTime(msg['createdAt']);

                      return Opacity(
                        opacity: pending && isMe ? 0.92 : 1,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                          mainAxisAlignment: isMe
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!isMe) ...[
                              CircleAvatar(
                                radius: 16,
                                backgroundColor:
                                    _incomingBorder.withValues(alpha: 0.8),
                                child: Icon(
                                  Icons.person_outline_rounded,
                                  size: 18,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.sizeOf(context).width * 0.78,
                                ),
                                decoration: BoxDecoration(
                                  gradient: isMe
                                      ? const LinearGradient(
                                          colors: [_blue, _purple],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        )
                                      : null,
                                  color:
                                      isMe ? null : _incomingFill,
                                  borderRadius: BorderRadius.only(
                                    topLeft:
                                        Radius.circular(isMe ? 18 : 6),
                                    topRight:
                                        Radius.circular(isMe ? 6 : 18),
                                    bottomLeft:
                                        const Radius.circular(18),
                                    bottomRight:
                                        const Radius.circular(18),
                                  ),
                                  border: isMe
                                      ? null
                                      : Border.all(
                                          color: _incomingBorder),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.06),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 11,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      body,
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        height: 1.42,
                                        color: isMe
                                            ? Colors.white
                                            : const Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      time,
                                      style: GoogleFonts.inter(
                                        fontSize: 10.5,
                                        color: isMe
                                            ? Colors.white
                                                .withValues(alpha: 0.85)
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 8),
                              CircleAvatar(
                                radius: 16,
                                backgroundColor:
                                    _blue.withValues(alpha: 0.2),
                                child: Icon(
                                  pending
                                      ? Icons.schedule_rounded
                                      : Icons.check_rounded,
                                  size: 16,
                                  color: _blue,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                    },
                  ),
                ),
          Material(
            color: Colors.white,
            elevation: 8,
            shadowColor: Colors.black26,
            child: SafeArea(
              top: false,
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: TextField(
                          controller: _controller,
                          minLines: 1,
                          maxLines: 5,
                          textCapitalization:
                              TextCapitalization.sentences,
                          style: GoogleFonts.inter(fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'Message…',
                            hintStyle: GoogleFonts.inter(
                              color: Colors.grey.shade500,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [_blue, _purple],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x4000AEEF),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _send,
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
