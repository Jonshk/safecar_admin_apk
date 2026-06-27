// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;
  int _pendingTows = 0;
  int _pendingBookings = 0;
  int _pendingOrders = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.getTowRequests(status: 'pending'),
        ApiService.getBookings(status: 'pending'),
        ApiService.getOrders(),
      ]);
      final pendingOrders = (results[2] as List)
          .where((o) => o['payment_status'] == 'awaiting_verification')
          .length;
      setState(() {
        _pendingTows = (results[0] as List).length;
        _pendingBookings = (results[1] as List).length;
        _pendingOrders = pendingOrders;
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
        title: const Text('Safe Car Admin'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : RefreshIndicator(
              color: const Color(0xFFD4AF37),
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text('Panel de control',
                      style: GoogleFonts.playfairDisplay(
                          color: const Color(0xFFD4AF37),
                          fontSize: 28,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  _SummaryCard(
                      icon: Icons.local_shipping_rounded,
                      label: 'Grúas pendientes',
                      count: _pendingTows,
                      color: const Color(0xFFF59E0B)),
                  const SizedBox(height: 12),
                  _SummaryCard(
                      icon: Icons.build_circle_rounded,
                      label: 'Reservas pendientes',
                      count: _pendingBookings,
                      color: const Color(0xFF3B82F6)),
                  const SizedBox(height: 12),
                  _SummaryCard(
                      icon: Icons.shopping_bag_rounded,
                      label: 'Pedidos por verificar',
                      count: _pendingOrders,
                      color: const Color(0xFF10B981)),
                ],
              ),
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  const _SummaryCard(
      {required this.icon,
      required this.label,
      required this.count,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(width: 16),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 4),
          Text('$count',
              style: GoogleFonts.inter(
                color: color,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              )),
        ])),
        if (count > 0)
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      ]),
    );
  }
}
