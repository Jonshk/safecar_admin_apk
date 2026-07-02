// lib/screens/tow_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hugeicons/hugeicons.dart';
import '../services/api_service.dart';
import '../services/technician_location_service.dart';
import '../widgets/status_badge.dart';
import '../widgets/search_filter_bar.dart';
import '../theme/sc_theme.dart';
import 'chat_screen_admin.dart';

/// Para grúas, "in_progress" se le muestra al cliente como "En camino"
/// (no "En curso") porque implica desplazamiento físico con GPS.
const _towLabels = {
  'pending': 'Pendiente',
  'confirmed': 'Confirmado',
  'in_progress': 'En camino',
  'completed': 'Completado',
  'cancelled': 'Cancelado',
};

class TowScreen extends StatefulWidget {
  const TowScreen({super.key});
  @override
  State<TowScreen> createState() => _TowScreenState();
}

class _TowScreenState extends State<TowScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _tows = [];
  String _filter = 'all';
  String _query = '';

  List<Map<String, dynamic>> get _filteredTows {
    if (_query.trim().isEmpty) return _tows;
    final q = _query.toLowerCase();
    return _tows.where((t) {
      final ref = (t['reference'] ?? '').toString().toLowerCase();
      final name = (t['customer_name'] ?? '').toString().toLowerCase();
      return ref.contains(q) || name.contains(q);
    }).toList();
  }

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
      backgroundColor: SC.bg,
      appBar: AppBar(
        title: const Text('Solicitudes de grúa'),
        actions: [
          IconButton(
            icon: HugeIcon(icon: HugeIcons.strokeRoundedRefresh, color: SC.orange, size: 19),
            onPressed: _load,
          ),
        ],
      ),
      body: Column(children: [
        SearchFilterBar(
          query: _query,
          onQueryChanged: (v) => setState(() => _query = v),
          selectedFilter: _filter,
          onFilterChanged: (f) {
            setState(() => _filter = f);
            _load();
          },
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: SC.orange))
              : _filteredTows.isEmpty
                  ? const EmptyState('No hay solicitudes de grúa')
                  : RefreshIndicator(
                      color: SC.orange,
                      backgroundColor: SC.surface,
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        itemCount: _filteredTows.length,
                        itemBuilder: (_, i) =>
                            _TowCard(tow: _filteredTows[i], onStatusChanged: _load),
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
    final status = tow['status'] ?? 'pending';
    return AdminCard(
      onTap: () => _showDetail(context),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            HugeIcon(icon: HugeIcons.strokeRoundedTowTruck, color: SC.orange, size: 16),
            const SizedBox(width: 8),
            Expanded(
                child: Text(tow['reference'] ?? '',
                    style: SC.mono(size: 12, color: SC.textSecondary))),
            StatusBadge(status, overrideLabel: _towLabels[status]),
          ]),
          const SizedBox(height: 10),
          InfoRow(Icons.person_rounded, tow['customer_name'] ?? ''),
          const SizedBox(height: 4),
          InfoRow(Icons.directions_car_rounded, tow['vehicle_description'] ?? ''),
          const SizedBox(height: 4),
          InfoRow(Icons.location_on_rounded, tow['pickup_address'] ?? ''),
          if ((tow['destination_address'] ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            InfoRow(Icons.flag_rounded, tow['destination_address']),
          ],
          if (status == 'in_progress') ...[
            const SizedBox(height: 8),
            const _TrackingPulse(),
          ],
          if (_hasGps) ...[
            const SizedBox(height: 8),
            _GpsBadge(
              lat: (tow['pickup_lat'] as num).toDouble(),
              lng: (tow['pickup_lng'] as num).toDouble(),
            ),
          ],
          const SizedBox(height: 10),
          const _LaneDivider(),
          const SizedBox(height: 10),
          Row(children: [
            ActionBtn(
              icon: Icons.phone_rounded,
              label: 'Llamar',
              color: SC.cyan,
              onTap: () => launchUrl(Uri.parse('tel:${tow['customer_phone']}')),
            ),
            const SizedBox(width: 8),
            if (_hasGps) ...[
              ActionBtn(
                icon: Icons.map_rounded,
                label: 'Maps',
                color: SC.textPrimary,
                onTap: () => _openMaps(),
              ),
              const SizedBox(width: 8),
            ],
            if (status == 'confirmed' || status == 'in_progress') ...[
              ActionBtn(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Chat',
                color: SC.orange,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreenAdmin(
                      towId: tow['id'] as int,
                      technicianName: 'Técnico Safe Car',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            ActionBtn(
              icon: Icons.edit_rounded,
              label: 'Estado',
              color: SC.orange,
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
        labelOverrides: _towLabels,
        options: const [
          'pending',
          'confirmed',
          'in_progress',
          'completed',
          'cancelled'
        ],
        onSelected: (s) async {
          await ApiService.updateTowStatus(tow['id'], s);

          // Arranca el envío de GPS del técnico solo cuando pasa a
          // "en camino"; lo detiene en cualquier otro estado
          // (completado, cancelado, o si se retrocede el estado).
          if (s == 'in_progress') {
            await TechnicianLocationService.instance.start(tow['id'] as int);
          } else if (TechnicianLocationService.instance.activeTowId == tow['id']) {
            await TechnicianLocationService.instance.stop();
          }

          onStatusChanged();
        },
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final status = tow['status'] ?? 'pending';
    showModalBottomSheet(
      context: context,
      backgroundColor: SC.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        builder: (_, sc) => SingleChildScrollView(
          controller: sc,
          padding: const EdgeInsets.all(22),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                  child: Text(tow['reference'] ?? '',
                      style: SC.mono(size: 15, color: SC.orange))),
              StatusBadge(status, overrideLabel: _towLabels[status]),
            ]),
            const SizedBox(height: 16),
            const _LaneDivider(),
            const SizedBox(height: 16),
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
            const SizedBox(height: 18),
            if (_hasGps)
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.map_rounded),
                    label: const Text('Abrir en Google Maps'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SC.surfaceAlt,
                      foregroundColor: SC.textPrimary,
                      side: const BorderSide(color: SC.border),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
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
            if (status == 'confirmed' || status == 'in_progress') ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text('Chat con el cliente'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SC.orangeBg,
                    foregroundColor: SC.orange,
                    side: BorderSide(color: SC.orange.withOpacity(0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreenAdmin(
                        towId: tow['id'] as int,
                        technicianName: 'Técnico Safe Car',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

/// Indicador de que el GPS del técnico está activo y transmitiendo —
/// se muestra solo cuando el estado es in_progress.
class _TrackingPulse extends StatefulWidget {
  const _TrackingPulse();
  @override
  State<_TrackingPulse> createState() => _TrackingPulseState();
}

class _TrackingPulseState extends State<_TrackingPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: SC.orangeBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: SC.orange.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        FadeTransition(
          opacity: _c,
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: SC.orange, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 7),
        Text('GPS transmitiendo en vivo',
            style: SC.mono(size: 10, color: SC.orange, weight: FontWeight.w500)),
      ]),
    );
  }
}

class _LaneDivider extends StatelessWidget {
  const _LaneDivider();
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size(double.infinity, 1), painter: _DashPainter());
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = SC.border..strokeWidth = 1;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + 5, 0), paint);
      x += 10;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GpsBadge extends StatelessWidget {
  final double lat, lng;
  const _GpsBadge({required this.lat, required this.lng});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: SC.cyanBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: SC.cyan.withOpacity(0.35)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.gps_fixed_rounded, size: 12, color: SC.cyan),
          const SizedBox(width: 6),
          Text('${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
              style: SC.mono(size: 10.5, color: SC.cyan, weight: FontWeight.w500)),
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
              child: Text(label, style: SC.body(size: 11.5, color: SC.textMuted))),
          Expanded(child: Text(value, style: SC.body(size: 13))),
        ]),
      );
}