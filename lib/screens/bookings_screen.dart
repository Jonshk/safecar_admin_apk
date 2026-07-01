// lib/screens/bookings_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hugeicons/hugeicons.dart';
import '../services/api_service.dart';
import '../widgets/status_badge.dart';
import '../widgets/search_filter_bar.dart';
import '../theme/sc_theme.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});
  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _bookings = [];
  String _filter = 'all';
  String _query = '';

  List<Map<String, dynamic>> get _filteredBookings {
    if (_query.trim().isEmpty) return _bookings;
    final q = _query.toLowerCase();
    return _bookings.where((b) {
      final ref = (b['reference'] ?? '').toString().toLowerCase();
      final name = (b['customer_name'] ?? '').toString().toLowerCase();
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
      final data = await ApiService.getBookings(
          status: _filter == 'all' ? null : _filter);
      setState(() {
        _bookings = data;
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
        title: const Text('Reservas de servicio'),
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
              : _filteredBookings.isEmpty
                  ? const EmptyState('No hay reservas de servicio')
                  : RefreshIndicator(
                      color: SC.orange,
                      backgroundColor: SC.surface,
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        itemCount: _filteredBookings.length,
                        itemBuilder: (_, i) => _BookingCard(
                            booking: _filteredBookings[i], onStatusChanged: _load),
                      ),
                    ),
        ),
      ]),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onStatusChanged;
  const _BookingCard({required this.booking, required this.onStatusChanged});

  @override
  Widget build(BuildContext context) {
    final vehicle =
        '${booking['vehicle_year']} ${booking['vehicle_make']} ${booking['vehicle_model']}'
            .trim();
    return AdminCard(
      onTap: () => _showDetail(context),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            HugeIcon(icon: HugeIcons.strokeRoundedWrench01, color: SC.cyan, size: 16),
            const SizedBox(width: 8),
            Expanded(
                child: Text(booking['reference'] ?? '',
                    style: SC.mono(size: 12, color: SC.textSecondary))),
            StatusBadge(booking['status'] ?? 'pending'),
          ]),
          const SizedBox(height: 8),
          _ServicePill(booking['service_type'] ?? ''),
          const SizedBox(height: 10),
          InfoRow(Icons.person_rounded, booking['customer_name'] ?? ''),
          const SizedBox(height: 4),
          if (vehicle.isNotEmpty)
            InfoRow(Icons.directions_car_rounded, vehicle),
          const SizedBox(height: 4),
          InfoRow(
              Icons.calendar_today_rounded,
              '${booking['preferred_date']} ${booking['preferred_time'] ?? ''}'
                  .trim()),
          const SizedBox(height: 10),
          Row(children: [
            ActionBtn(
              icon: Icons.phone_rounded,
              label: 'Llamar',
              color: SC.cyan,
              onTap: () =>
                  launchUrl(Uri.parse('tel:${booking['customer_phone']}')),
            ),
            const SizedBox(width: 8),
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

  void _changeStatus(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => StatusSelectorSheet(
        currentStatus: booking['status'] ?? 'pending',
        options: const [
          'pending',
          'confirmed',
          'in_progress',
          'completed',
          'cancelled'
        ],
        onSelected: (s) async {
          await ApiService.updateBookingStatus(booking['id'], s);
          onStatusChanged();
        },
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final vehicle =
        '${booking['vehicle_year']} ${booking['vehicle_make']} ${booking['vehicle_model']}'
            .trim();
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
                  child: Text(booking['reference'] ?? '',
                      style: SC.mono(size: 15, color: SC.orange))),
              StatusBadge(booking['status'] ?? 'pending'),
            ]),
            const SizedBox(height: 8),
            _ServicePill(booking['service_type'] ?? ''),
            const SizedBox(height: 16),
            _DR('Cliente', booking['customer_name'] ?? ''),
            _DR('Email', booking['customer_email'] ?? ''),
            _DR('Teléfono', booking['customer_phone'] ?? ''),
            if (vehicle.isNotEmpty) _DR('Vehículo', vehicle),
            _DR('Fecha', booking['preferred_date'] ?? ''),
            if ((booking['preferred_time'] ?? '').isNotEmpty)
              _DR('Hora', booking['preferred_time']),
            if ((booking['notes'] ?? '').isNotEmpty)
              _DR('Notas', booking['notes']),
            _DR('Creado', booking['created_at'] ?? ''),
            const SizedBox(height: 18),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.phone_rounded),
                  label: Text('Llamar a ${booking['customer_name']}'),
                  onPressed: () =>
                      launchUrl(Uri.parse('tel:${booking['customer_phone']}')),
                )),
          ]),
        ),
      ),
    );
  }
}

class _ServicePill extends StatelessWidget {
  final String type;
  const _ServicePill(this.type);

  static const _labels = {
    'oil_change': ('Cambio de aceite', SC.cyan),
    'brake_service': ('Frenos', SC.orange),
    'diagnostics': ('Diagnóstico', SC.cyan),
    'tire_rotation': ('Neumáticos', SC.cyan),
    'general_repair': ('Reparación general', SC.success),
    'tow_followup': ('Seguimiento grúa', SC.orange),
    'other': ('Otro', SC.textMuted),
  };

  @override
  Widget build(BuildContext context) {
    final entry = _labels[type];
    final label = entry?.$1 ?? type;
    final color = entry?.$2 ?? SC.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: SC.bg,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(label,
          style: SC.body(size: 11, weight: FontWeight.w500, color: color)),
    );
  }
}

class _DR extends StatelessWidget {
  final String label, value;
  const _DR(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              width: 90,
              child: Text(label, style: SC.body(size: 11.5, color: SC.textMuted))),
          Expanded(child: Text(value, style: SC.body(size: 13))),
        ]),
      );
}