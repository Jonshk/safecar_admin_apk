// lib/screens/bookings_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../widgets/status_badge.dart';
import 'tow_screen.dart' show _FilterBar, _Empty, _Info, _ActionBtn;

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});
  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _bookings = [];
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getBookings(
        status: _filter == 'all' ? null : _filter,
      );
      setState(() { _bookings = data; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservas de Servicio'),
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
                : _bookings.isEmpty
                    ? const _Empty('No hay reservas de servicio')
                    : RefreshIndicator(
                        color: const Color(0xFFD4AF37),
                        onRefresh: _load,
                        child: ListView.builder(
                          itemCount: _bookings.length,
                          itemBuilder: (_, i) => _BookingCard(
                            booking: _bookings[i],
                            onStatusChanged: _load,
                          ),
                        ),
                      ),
          ),
        ],
      ),
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
        '${booking['vehicle_year']} ${booking['vehicle_make']} ${booking['vehicle_model']}'.trim();

    return AdminCard(
      onTap: () => _showDetail(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(
                booking['reference'] ?? '',
                style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
              ),
            ),
            StatusBadge(booking['status'] ?? 'pending'),
          ]),
          const SizedBox(height: 8),
          _ServiceTypePill(booking['service_type'] ?? ''),
          const SizedBox(height: 10),
          _Info(Icons.person_rounded, booking['customer_name'] ?? ''),
          const SizedBox(height: 4),
          if (vehicle.isNotEmpty)
            _Info(Icons.directions_car_rounded, vehicle),
          const SizedBox(height: 4),
          _Info(Icons.calendar_today_rounded,
              '${booking['preferred_date']} ${booking['preferred_time'] ?? ''}'.trim()),
          const SizedBox(height: 12),
          Row(children: [
            _ActionBtn(
              icon: Icons.phone_rounded,
              label: 'Llamar',
              color: const Color(0xFF10B981),
              onTap: () => launchUrl(Uri.parse('tel:${booking['customer_phone']}')),
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

  void _changeStatus(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => StatusSelectorSheet(
        currentStatus: booking['status'] ?? 'pending',
        options: const ['pending', 'confirmed', 'in_progress', 'completed', 'cancelled'],
        onSelected: (newStatus) async {
          try {
            await ApiService.updateBookingStatus(booking['id'], newStatus);
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
      builder: (_) => _BookingDetailSheet(
        booking: booking, onStatusChanged: onStatusChanged,
      ),
    );
  }
}

class _BookingDetailSheet extends StatelessWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onStatusChanged;
  const _BookingDetailSheet({required this.booking, required this.onStatusChanged});

  @override
  Widget build(BuildContext context) {
    final vehicle =
        '${booking['vehicle_year']} ${booking['vehicle_make']} ${booking['vehicle_model']}'.trim();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      builder: (_, sc) => SingleChildScrollView(
        controller: sc,
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(booking['reference'] ?? '',
                style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.bold))),
            StatusBadge(booking['status'] ?? 'pending'),
          ]),
          const SizedBox(height: 8),
          _ServiceTypePill(booking['service_type'] ?? ''),
          const Divider(color: Colors.white12, height: 24),
          _DetailRow('Cliente', booking['customer_name'] ?? ''),
          _DetailRow('Email', booking['customer_email'] ?? ''),
          _DetailRow('Teléfono', booking['customer_phone'] ?? ''),
          if (vehicle.isNotEmpty) _DetailRow('Vehículo', vehicle),
          _DetailRow('Fecha', booking['preferred_date'] ?? ''),
          if ((booking['preferred_time'] ?? '').isNotEmpty)
            _DetailRow('Hora', booking['preferred_time']),
          if ((booking['notes'] ?? '').isNotEmpty)
            _DetailRow('Notas', booking['notes']),
          _DetailRow('Creado', booking['created_at'] ?? ''),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.phone_rounded),
              label: Text('Llamar a ${booking['customer_name']}'),
              onPressed: () => launchUrl(Uri.parse('tel:${booking['customer_phone']}')),
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

class _ServiceTypePill extends StatelessWidget {
  final String type;
  const _ServiceTypePill(this.type);

  static const _labels = {
    'oil_change': ('Cambio de aceite', Color(0xFFF59E0B)),
    'brake_service': ('Frenos', Color(0xFFEF4444)),
    'diagnostics': ('Diagnóstico', Color(0xFF8B5CF6)),
    'tire_rotation': ('Neumáticos', Color(0xFF3B82F6)),
    'general_repair': ('Reparación general', Color(0xFF10B981)),
    'tow_followup': ('Seguimiento grúa', Color(0xFFD4AF37)),
    'other': ('Otro', Colors.white38),
  };

  @override
  Widget build(BuildContext context) {
    final (label, color) = _labels[type] ?? (type, Colors.white38);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
