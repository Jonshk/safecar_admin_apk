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
          status: _filter == 'all' ? null : _filter);
      setState(() {
        _tows = data;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitudes de Grúa'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load)
        ],
      ),
      body: Column(children: [
        FilterBar(
            selected: _filter,
            onChanged: (f) {
              setState(() => _filter = f);
              _load();
            }),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
              : _tows.isEmpty
                  ? const EmptyState('No hay solicitudes de grúa')
                  : RefreshIndicator(
                      color: const Color(0xFFD4AF37),
                      onRefresh: _load,
                      child: ListView.builder(
                        itemCount: _tows.length,
                        itemBuilder: (_, i) =>
                            _TowCard(tow: _tows[i], onStatusChanged: _load),
                      ),
                    ),
        ),
      ]),
    );
  }
}

class _TowCard extends StatelessWidget {
  final Map<String, dynamic> tow;
  final VoidCallback onStatusChanged;
  const _TowCard({required this.tow, required this.onStatusChanged});

  bool get _hasGps {
    final lat = (tow['pickup_lat'] ?? 0.0) as num;
    final lng = (tow['pickup_lng'] ?? 0.0) as num;
    return lat != 0.0 || lng != 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      onTap: () => _showDetail(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text(tow['reference'] ?? '',
                    style: const TextStyle(
                        color: Color(0xFFD4AF37),
                        fontWeight: FontWeight.bold))),
            StatusBadge(tow['status'] ?? 'pending'),
          ]),
          const SizedBox(height: 10),
          InfoRow(Icons.person_rounded, tow['customer_name'] ?? ''),
          const SizedBox(height: 4),
          InfoRow(
              Icons.directions_car_rounded, tow['vehicle_description'] ?? ''),
          const SizedBox(height: 4),
          InfoRow(Icons.location_on_rounded, tow['pickup_address'] ?? ''),
          if ((tow['destination_address'] ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            InfoRow(Icons.flag_rounded, tow['destination_address']),
          ],
          if (_hasGps) ...[
            const SizedBox(height: 8),
            _GpsBadge(
              lat: (tow['pickup_lat'] as num).toDouble(),
              lng: (tow['pickup_lng'] as num).toDouble(),
            ),
          ],
          const SizedBox(height: 12),
          Row(children: [
            ActionBtn(
              icon: Icons.phone_rounded,
              label: 'Llamar',
              color: const Color(0xFF10B981),
              onTap: () => launchUrl(Uri.parse('tel:${tow['customer_phone']}')),
            ),
            const SizedBox(width: 8),
            if (_hasGps) ...[
              ActionBtn(
                icon: Icons.map_rounded,
                label: 'Maps',
                color: const Color(0xFF3B82F6),
                onTap: () => _openMaps(),
              ),
              const SizedBox(width: 8),
            ],
            ActionBtn(
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

  void _openMaps() {
    final lat = (tow['pickup_lat'] as num).toDouble();
    final lng = (tow['pickup_lng'] as num).toDouble();
    launchUrl(
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng'),
        mode: LaunchMode.externalApplication);
  }

  void _changeStatus(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => StatusSelectorSheet(
        currentStatus: tow['status'] ?? 'pending',
        options: const [
          'pending',
          'confirmed',
          'in_progress',
          'completed',
          'cancelled'
        ],
        onSelected: (s) async {
          await ApiService.updateTowStatus(tow['id'], s);
          onStatusChanged();
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        builder: (_, sc) => SingleChildScrollView(
          controller: sc,
          padding: const EdgeInsets.all(24),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                  child: Text(tow['reference'] ?? '',
                      style: const TextStyle(
                          color: Color(0xFFD4AF37),
                          fontSize: 18,
                          fontWeight: FontWeight.bold))),
              StatusBadge(tow['status'] ?? 'pending'),
            ]),
            const Divider(color: Colors.white12, height: 24),
            _DR('Cliente', tow['customer_name'] ?? ''),
            _DR('Teléfono', tow['customer_phone'] ?? ''),
            _DR('Vehículo', tow['vehicle_description'] ?? ''),
            _DR('Recogida', tow['pickup_address'] ?? ''),
            if ((tow['destination_address'] ?? '').isNotEmpty)
              _DR('Destino', tow['destination_address']),
            if ((tow['notes'] ?? '').isNotEmpty) _DR('Notas', tow['notes']),
            _DR('Fecha', tow['created_at'] ?? ''),
            if (_hasGps)
              _DR(
                  'GPS',
                  '${(tow['pickup_lat'] as num).toStringAsFixed(6)}, '
                      '${(tow['pickup_lng'] as num).toStringAsFixed(6)}'),
            const SizedBox(height: 20),
            if (_hasGps)
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.map_rounded),
                    label: const Text('Abrir en Google Maps'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A73E8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _openMaps,
                  )),
            const SizedBox(height: 10),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.phone_rounded),
                  label: Text('Llamar a ${tow['customer_name']}'),
                  onPressed: () =>
                      launchUrl(Uri.parse('tel:${tow['customer_phone']}')),
                )),
          ]),
        ),
      ),
    );
  }
}

class _GpsBadge extends StatelessWidget {
  final double lat, lng;
  const _GpsBadge({required this.lat, required this.lng});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF002800),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF00C47A).withOpacity(0.4)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.gps_fixed_rounded,
              size: 12, color: Color(0xFF00C47A)),
          const SizedBox(width: 6),
          Text('${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
              style: const TextStyle(
                  color: Color(0xFF00C47A),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace')),
        ]),
      );
}

class _DR extends StatelessWidget {
  final String label, value;
  const _DR(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              width: 80,
              child: Text(label,
                  style: const TextStyle(color: Colors.white38, fontSize: 12))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(color: Colors.white, fontSize: 14))),
        ]),
      );
}
