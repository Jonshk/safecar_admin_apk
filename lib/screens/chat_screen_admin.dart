// lib/screens/chat_screen_admin.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/sc_theme.dart';
import '../services/api_service.dart';
import '../widgets/status_badge.dart';

class ChatScreenAdmin extends StatefulWidget {
  final int towId;
  final String technicianName;
  final String currentStatus;
  final Map<String, String> labelOverrides;
  final List<String> statusOptions;
  final double? pickupLat;
  final double? pickupLng;
  final double? techLat;
  final double? techLng;
  final VoidCallback? onStatusChanged;

  const ChatScreenAdmin({
    super.key,
    required this.towId,
    required this.technicianName,
    required this.currentStatus,
    required this.labelOverrides,
    required this.statusOptions,
    this.pickupLat,
    this.pickupLng,
    this.techLat,
    this.techLng,
    this.onStatusChanged,
  });

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
  late String _currentStatus;

  // Altura del mapa — redimensionable
  double _mapHeight = 220;
  static const _minMap = 80.0;
  static const _maxMap = 420.0;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.currentStatus;
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
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
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

  void _changeStatus() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatusSelectorSheet(
        currentStatus: _currentStatus,
        labelOverrides: widget.labelOverrides,
        options: widget.statusOptions,
        onSelected: (s) async {
          await ApiService.updateTowStatus(widget.towId, s);
          setState(() => _currentStatus = s);
          widget.onStatusChanged?.call();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPickup = (widget.pickupLat ?? 0) != 0;
    final hasTech = (widget.techLat ?? 0) != 0;
    final showMap = hasPickup || hasTech;
    final center = hasTech
        ? LatLng(widget.techLat!, widget.techLng!)
        : hasPickup
            ? LatLng(widget.pickupLat!, widget.pickupLng!)
            : const LatLng(41.8781, -87.6298);

    return Scaffold(
      backgroundColor: SC.bg,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: SC.surface,
        title: Row(children: [
          Container(width: 8, height: 8,
              decoration: const BoxDecoration(color: SC.cyan, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          const Text('Chat con el cliente'),
        ]),
        actions: [
          // Botón cambiar estado en el AppBar
          GestureDetector(
            onTap: _changeStatus,
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: SC.orangeBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: SC.orange.withOpacity(0.4)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.edit_rounded, color: SC.orange, size: 14),
                const SizedBox(width: 5),
                Text(widget.labelOverrides[_currentStatus] ?? _currentStatus,
                    style: TextStyle(color: SC.orange, fontSize: 12, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── MAPA REDIMENSIONABLE ─────────────────────────
            if (showMap) ...[
              SizedBox(
                height: _mapHeight,
                child: FlutterMap(
                  options: MapOptions(initialCenter: center, initialZoom: 15),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.safecar.safecar_admin',
                    ),
                    MarkerLayer(markers: [
                      if (hasPickup) Marker(
                        point: LatLng(widget.pickupLat!, widget.pickupLng!),
                        width: 40, height: 40,
                        child: Container(
                          decoration: BoxDecoration(color: SC.cyan, shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2)),
                          child: const Icon(Icons.person_pin_circle_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                      if (hasTech) Marker(
                        point: LatLng(widget.techLat!, widget.techLng!),
                        width: 44, height: 44,
                        child: Container(
                          decoration: BoxDecoration(color: SC.orange, shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2)),
                          child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 24),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
              // Handle para redimensionar
              GestureDetector(
                onVerticalDragUpdate: (d) {
                  setState(() {
                    _mapHeight = (_mapHeight + d.delta.dy).clamp(_minMap, _maxMap);
                  });
                },
                child: Container(
                  height: 20,
                  color: SC.surface,
                  child: Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: SC.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ],

            // ── CHAT ──────────────────────────────────────────
            Expanded(
              child: _messages.isEmpty
                  ? Center(child: Text('Sin mensajes aún.',
                      style: TextStyle(color: SC.textMuted, fontSize: 14)))
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) => _buildBubble(_messages[i]),
                    ),
            ),
            _buildInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(Map<String, dynamic> msg) {
    final isMe = msg['sender'] == 'technician';
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
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
            Text(msg['text'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14)),
            const SizedBox(height: 3),
            Text((msg['created_at'] as String?)?.substring(11, 16) ?? '',
                style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.45))),
          ],
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: SC.surface,
        border: Border(top: BorderSide(color: SC.border)),
      ),
      child: Row(children: [
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
                hintStyle: TextStyle(color: SC.textMuted, fontSize: 13),
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
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: SC.orange, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: SC.orange.withOpacity(0.4), blurRadius: 10)],
            ),
            child: _sending
                ? const Padding(padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }
}