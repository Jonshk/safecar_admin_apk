// lib/screens/orders_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/status_badge.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _orders = [];
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getOrders();
      setState(() {
        _orders = _filter == 'all'
            ? data
            : data.where((o) => o['payment_status'] == _filter).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filters = [
      ('all', 'Todos'),
      ('awaiting_verification', 'Por verificar'),
      ('paid', 'Pagados'),
      ('pending', 'Pendiente'),
      ('failed', 'Fallidos'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos de Productos'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: filters.map((f) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(f.$2),
                  selected: _filter == f.$1,
                  onSelected: (_) {
                    setState(() => _filter = f.$1);
                    _load();
                  },
                ),
              )).toList(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
                : _orders.isEmpty
                    ? const _Empty()
                    : RefreshIndicator(
                        color: const Color(0xFFD4AF37),
                        onRefresh: _load,
                        child: ListView.builder(
                          itemCount: _orders.length,
                          itemBuilder: (_, i) => _OrderCard(order: _orders[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final items = (order['items'] as List?) ?? [];
    final total = (order['total'] ?? 0.0).toDouble();

    return AdminCard(
      onTap: () => _showDetail(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(
                order['reference'] ?? '',
                style: const TextStyle(
                    color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
              ),
            ),
            StatusBadge(order['payment_status'] ?? 'pending'),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.person_rounded, size: 14, color: Colors.white38),
            const SizedBox(width: 6),
            Expanded(child: Text(order['customer_name'] ?? '',
                style: const TextStyle(color: Colors.white70, fontSize: 13))),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.inventory_2_rounded, size: 14, color: Colors.white38),
            const SizedBox(width: 6),
            Text('${items.length} producto(s)',
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const Spacer(),
            Text('\$${total.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 15)),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.payment_rounded, size: 14, color: Colors.white38),
            const SizedBox(width: 6),
            Text(_paymentLabel(order['payment_method'] ?? ''),
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ]),
        ]),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final items = (order['items'] as List?) ?? [];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        builder: (_, sc) => SingleChildScrollView(
          controller: sc,
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(order['reference'] ?? '',
                  style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.bold))),
              StatusBadge(order['payment_status'] ?? 'pending'),
            ]),
            const Divider(color: Colors.white12, height: 24),
            _DR('Cliente', order['customer_name'] ?? ''),
            _DR('Email', order['customer_email'] ?? ''),
            _DR('Teléfono', order['customer_phone'] ?? ''),
            _DR('Dirección', order['shipping_address'] ?? ''),
            _DR('Método pago', _paymentLabel(order['payment_method'] ?? '')),
            _DR('Total', '\$${(order['total'] ?? 0.0).toStringAsFixed(2)}'),
            _DR('Fecha', order['created_at'] ?? ''),
            const SizedBox(height: 16),
            const Text('Productos', style: TextStyle(
                color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Expanded(child: Text(
                  '${item['quantity']}x ${item['part_name']}',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                )),
                Text('\$${(item['subtotal'] ?? 0.0).toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white54, fontSize: 13)),
              ]),
            )),
            if ((order['confirmation_note'] ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              _DR('Nota confirmación', order['confirmation_note']),
            ],
          ]),
        ),
      ),
    );
  }

  String _paymentLabel(String method) => switch (method) {
    'card' => 'Tarjeta',
    'zelle' => 'Zelle',
    'bank_transfer' => 'Transferencia',
    _ => method,
  };
}

class _DR extends StatelessWidget {
  final String label;
  final String value;
  const _DR(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 110,
          child: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12))),
      Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 14))),
    ]),
  );
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.inbox_rounded, color: Colors.white24, size: 64),
      SizedBox(height: 12),
      Text('No hay pedidos', style: TextStyle(color: Colors.white38)),
    ]),
  );
}
