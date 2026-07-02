// lib/screens/chat_screen_admin.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/sc_theme.dart';
import '../services/api_service.dart';

class ChatScreenAdmin extends StatefulWidget {
  final int towId;
  final String technicianName;
  const ChatScreenAdmin({super.key, required this.towId, required this.technicianName});

  @override
  State<ChatScreenAdmin> createState() => _ChatScreenAdminState();
}

class _ChatScreenAdminState extends State<ChatScreenAdmin> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  int _lastId = 0;
  bool _sending = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _load());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final msgs = await ApiService.getChatMessages(widget.towId, afterId: _lastId);
    if (msgs.isEmpty || !mounted) return;
    setState(() {
      _messages.addAll(msgs);
      _lastId = msgs.last['id'] as int;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _ctrl.clear();
    final ok = await ApiService.sendChatMessage(
      towId: widget.towId,
      sender: 'technician',
      senderName: widget.technicianName,
      text: text,
    );
    setState(() => _sending = false);
    if (ok) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SC.bg,
      appBar: AppBar(
        backgroundColor: SC.surface,
        title: Row(
          children: [
            Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(color: SC.cyan, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            const Text('Chat con el cliente'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text('Sin mensajes aún.',
                        style: TextStyle(color: SC.white30, fontSize: 14)),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) => _buildBubble(_messages[i]),
                  ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildBubble(Map<String, dynamic> msg) {
    final isMe = msg['sender'] == 'technician';
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMe ? SC.orange : SC.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe) ...[
              Text(msg['sender_name'] ?? 'Cliente',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: SC.cyan)),
              const SizedBox(height: 3),
            ],
            Text(msg['text'] ?? '',
                style: const TextStyle(color: Colors.white, fontSize: 14)),
            const SizedBox(height: 3),
            Text(
              (msg['created_at'] as String?)?.substring(11, 16) ?? '',
              style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.45)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 12, right: 12, top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: SC.surface,
        border: Border(top: BorderSide(color: SC.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: SC.bg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: SC.border),
              ),
              child: TextField(
                controller: _ctrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'Escribe al cliente...',
                  hintStyle: TextStyle(color: SC.white30, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: SC.orange,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: SC.orange.withOpacity(0.4), blurRadius: 10)],
              ),
              child: _sending
                  ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}