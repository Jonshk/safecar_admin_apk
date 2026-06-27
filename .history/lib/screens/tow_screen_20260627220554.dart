// lib/screens/tow_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../widgets/status_badge.dart';

class TowScreen extends StatefulWidget {
  const TowScreen({super.key});
  @override
  State<TowScreen> createState() => _TowScreenState();
}

class _TowScreenState extends State<TowScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _tows = [];
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getTowRequests(
        status: _filter == 'all' ? null : _filter,
      );
      setState(() { _tows = data; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) _snack('Error cargando grúas: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitudes de Grúa'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          _FilterBar(
            selected: _filter,
            onChanged: (f) { setState(() => _filter = f); _load(); },
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
                : _tows.isEmpty
                    ? _Empty('No hay solicitudes de grúa')
                    : RefreshIndicator(
                        color: const Color(0xFFD4AF37),
                        onRefresh: _load,
                        child: ListView.builder(
                          itemCount: _tows.length,
                          itemBuilder: (_, i) => _TowCard(
                            tow: _tows[i],
                            onStatusChanged: _load,
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

class _TowCard extends StatelessWidget {
  final Map<String, dynamic> tow;
  final VoidCallback onStatusChanged;

  const _TowCard({required this.tow, required this.onStatusChanged});

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      onTap: () => _showDetail(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(
                tow['reference'] ?? '',
                style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
              ),
            ),
            StatusBadge(tow['status'] ?? 'pending'),
          ]),
          const SizedBox(height: 10),
          _Info(Icons.person_rounded, tow['customer_name'] ?? ''),
          const SizedBox(height: 4),
          _Info(Icons.directions_car_rounded, tow['vehicle_description'] ?? ''),
          const SizedBox(height: 4),
          _Info(Icons.location_on_rounded, tow['pickup_address'] ?? ''),
          if ((tow['destination_address'] ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            _Info(Icons.flag_rounded, tow['destination_address']),
          ],
          const SizedBox(height: 12),
          Row(children: [
            _ActionBtn(
              icon: Icons.phone_rounded,
              label: 'Llamar',
              color: const Color(0xFF10B981),
              onTap: () => _call(tow['customer_phone'] ?? ''),
            ),
            const SizedBox(width: 8),
            _ActionBtn(
              icon: Icons.edit_rounded,
              label: 'Estado',
              color: const Color(0xFFD4AF37),
              onTap: () => _changeStatus(context),
            ),
          ]),
        ]),
      ),
    );
  }

  void _call(String phone) {
    launchUrl(Uri.parse('tel:$phone'));
  }

  void _changeStatus(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => StatusSelectorSheet(
        currentStatus: tow['status'] ?? 'pending',
        options: const ['pending', 'confirmed', 'in_progress', 'completed', 'cancelled'],
        onSelected: (newStatus) async {
          try {
            await ApiService.updateTowStatus(tow['id'], newStatus);
            onStatusChanged();
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _TowDetailSheet(tow: tow, onStatusChanged: onStatusChanged),
    );
  }
}

class _TowDetailSheet extends StatelessWidget {
  final Map<String, dynamic> tow;
  final VoidCallback onStatusChanged;
  const _TowDetailSheet({required this.tow, required this.onStatusChanged});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      builder: (_, sc) => SingleChildScrollView(
        controller: sc,
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(tow['reference'] ?? '',
                style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.bold))),
            StatusBadge(tow['status'] ?? 'pending'),
          ]),
          const Divider(color: Colors.white12, height: 24),
          _DetailRow('Cliente', tow['customer_name'] ?? ''),
          _DetailRow('Teléfono', tow['customer_phone'] ?? ''),
          _DetailRow('Vehículo', tow['vehicle_description'] ?? ''),
          _DetailRow('Recogida', tow['pickup_address'] ?? ''),
          if ((tow['destination_address'] ?? '').isNotEmpty)
            _DetailRow('Destino', tow['destination_address']),
          if ((tow['notes'] ?? '').isNotEmpty)
            _DetailRow('Notas', tow['notes']),
          if ((tow['admin_notes'] ?? '').isNotEmpty)
            _DetailRow('Notas admin', tow['admin_notes']),
          _DetailRow('Creado', tow['created_at'] ?? ''),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.phone_rounded),
              label: Text('Llamar a ${tow['customer_name']}'),
              onPressed: () => launchUrl(Uri.parse('tel:${tow['customer_phone']}')),
            ),
          ),
        ]),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 90,
          child: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12))),
      Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 14))),
    ]),
  );
}

class _Info extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Info(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 14, color: Colors.white38),
    const SizedBox(width: 6),
    Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13),
        maxLines: 1, overflow: TextOverflow.ellipsis)),
  ]);
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

class _FilterBar extends StatelessWidget {
  final String selected;
  final void Function(String) onChanged;
  const _FilterBar({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final filters = [
      ('all', 'Todos'),
      ('pending', 'Pendiente'),
      ('confirmed', 'Confirmado'),
      ('in_progress', 'En curso'),
      ('completed', 'Completado'),
    ];
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: filters.map((f) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(f.$2),
            selected: selected == f.$1,
            onSelected: (_) => onChanged(f.$1),
          ),
        )).toList(),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String msg;
  const _Empty(this.msg);
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.inbox_rounded, color: Colors.white24, size: 64),
      const SizedBox(height: 12),
      Text(msg, style: const TextStyle(color: Colors.white38)),
    ]),
  );
}
