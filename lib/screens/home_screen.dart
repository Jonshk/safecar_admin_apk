// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../services/api_service.dart';
import '../theme/sc_theme.dart';
import '../widgets/gauge_dial.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int) onNavigate;
  const HomeScreen({super.key, required this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;
  int _pendingTows = 0, _pendingBookings = 0, _pendingOrders = 0;
  List<Map<String, dynamic>> _recentActivity = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.getTowRequests(),
        ApiService.getBookings(),
        ApiService.getOrders(),
      ]);
      final tows = results[0] as List<Map<String, dynamic>>;
      final bookings = results[1] as List<Map<String, dynamic>>;
      final orders = results[2] as List<Map<String, dynamic>>;

      final activity = [...tows, ...bookings]
        ..sort((a, b) => (b['created_at'] ?? '').compareTo(a['created_at'] ?? ''));

      setState(() {
        _pendingTows = tows.where((t) => t['status'] == 'pending').length;
        _pendingBookings = bookings.where((b) => b['status'] == 'pending').length;
        _pendingOrders = orders
            .where((o) => o['payment_status'] == 'awaiting_verification')
            .length;
        _recentActivity = activity.take(5).toList();
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
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: SC.orange))
            : RefreshIndicator(
                color: SC.orange,
                backgroundColor: SC.surface,
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  children: [
                    _Header(onRefresh: _load),
                    const SizedBox(height: 24),
                    _DialRow(
                      pendingTows: _pendingTows,
                      pendingBookings: _pendingBookings,
                      pendingOrders: _pendingOrders,
                      onTapTows: () => widget.onNavigate(1),
                      onTapBookings: () => widget.onNavigate(2),
                      onTapOrders: () => widget.onNavigate(3),
                    ),
                    const SizedBox(height: 18),
                    const _LaneDivider(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'ACTIVIDAD RECIENTE',
                          style: SC.display(size: 12, color: SC.textSecondary)
                              .copyWith(letterSpacing: 1.5),
                        ),
                        const Spacer(),
                        Text(
                          _currentTime(),
                          style: SC.mono(size: 10, color: SC.textMuted, weight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_recentActivity.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'Sin actividad por ahora.',
                          style: SC.body(size: 12, color: SC.textMuted),
                        ),
                      )
                    else
                      ..._recentActivity.map((item) => _ActivityRow(item: item)),
                  ],
                ),
              ),
      ),
    );
  }

  String _currentTime() {
    final now = DateTime.now();
    final h = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final m = now.minute.toString().padLeft(2, '0');
    final suffix = now.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $suffix';
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onRefresh;
  const _Header({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SAFE CAR', style: SC.display(size: 20)),
              const SizedBox(height: 2),
              Text(
                'ADMIN CONSOLE',
                style: SC.body(size: 10, color: SC.textMuted)
                    .copyWith(letterSpacing: 2),
              ),
            ],
          ),
        ),
        _LivePill(),
        const SizedBox(width: 10),
        _IconButton(
          icon: HugeIcons.strokeRoundedRefresh,
          onTap: onRefresh,
        ),
      ],
    );
  }
}

class _LivePill extends StatefulWidget {
  @override
  State<_LivePill> createState() => _LivePillState();
}

class _LivePillState extends State<_LivePill> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: SC.surface,
        border: Border.all(color: SC.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: _controller,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(color: SC.cyan, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'LIVE',
            style: SC.mono(size: 10, color: SC.cyan, weight: FontWeight.w500)
                .copyWith(letterSpacing: 1),
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final dynamic icon;
  final VoidCallback onTap;
  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: SC.surface,
          border: Border.all(color: SC.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(child: HugeIcon(icon: icon, color: SC.orange, size: 18)),
      ),
    );
  }
}

class _DialRow extends StatelessWidget {
  final int pendingTows, pendingBookings, pendingOrders;
  final VoidCallback onTapTows, onTapBookings, onTapOrders;

  const _DialRow({
    required this.pendingTows,
    required this.pendingBookings,
    required this.pendingOrders,
    required this.onTapTows,
    required this.onTapBookings,
    required this.onTapOrders,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onTapTows,
            child: GaugeDial(
              value: pendingTows,
              label: 'grúas pend.',
              color: SC.orange,
              delay: const Duration(milliseconds: 100),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: onTapBookings,
            child: GaugeDial(
              value: pendingBookings,
              label: 'reservas',
              color: SC.cyan,
              delay: const Duration(milliseconds: 250),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: onTapOrders,
            child: GaugeDial(
              value: pendingOrders,
              label: 'por verificar',
              color: SC.textPrimary,
              delay: const Duration(milliseconds: 400),
            ),
          ),
        ),
      ],
    );
  }
}

class _LaneDivider extends StatelessWidget {
  const _LaneDivider();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 1),
      painter: _DashedLinePainter(),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = SC.border
      ..strokeWidth = 1;
    const dashWidth = 6.0;
    const dashSpace = 6.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ActivityRow extends StatelessWidget {
  final Map<String, dynamic> item;
  const _ActivityRow({required this.item});

  bool get _isTow => item.containsKey('pickup_address') || item.containsKey('vehicle_description');

  @override
  Widget build(BuildContext context) {
    final status = (item['status'] ?? 'pending') as String;
    final color = SC.statusColor(status);
    final title = _isTow
        ? (item['vehicle_description'] ?? 'Solicitud de grúa')
        : (item['service_type'] ?? 'Reserva de servicio');
    final ref = item['reference'] ?? item['id']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: SC.bg, width: 1)),
      ),
      child: Row(
        children: [
          Container(width: 3, height: 34, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: SC.body(size: 13)),
                const SizedBox(height: 2),
                Text(
                  '$ref · ${_statusLabel(status)}',
                  style: SC.mono(size: 10, color: SC.textMuted, weight: FontWeight.w500),
                ),
              ],
            ),
          ),
          HugeIcon(
            icon: _isTow ? HugeIcons.strokeRoundedTowTruck : HugeIcons.strokeRoundedWrench01,
            color: color,
            size: 18,
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'confirmed':
        return 'confirmado';
      case 'in_progress':
        return _isTow ? 'en camino' : 'en curso';
      case 'completed':
        return 'completado';
      case 'cancelled':
        return 'cancelado';
      case 'pending':
      default:
        return 'pendiente';
    }
  }
}