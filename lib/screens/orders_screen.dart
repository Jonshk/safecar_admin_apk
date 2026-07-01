// lib/screens/orders_screen.dart
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../services/api_service.dart';
import '../widgets/status_badge.dart';
import '../widgets/search_filter_bar.dart';
import '../theme/sc_theme.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _orders = [];
  String _filter = 'all';
  String _query = '';

  List<Map<String, dynamic>> get _filteredOrders {
    if (_query.trim().isEmpty) return _orders;
    final q = _query.toLowerCase();
    return _orders.where((o) {
      final ref = (o['reference'] ?? '').toString().toLowerCase();
      final name = (o['customer_name'] ?? '').toString().toLowerCase();
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
    const filters = [
      ('all', 'Todos'),
      ('awaiting_verification', 'Por verificar'),
      ('paid', 'Pagados'),
      ('pending', 'Pendiente'),
      ('failed', 'Fallidos'),
    ];

    return Scaffold(
      backgroundColor: SC.bg,
      appBar: AppBar(
        title: const Text('Pedidos de productos'),
        actions: [
          IconButton(
            icon: HugeIcon(icon: HugeIcons.strokeRoundedRefresh, color: SC.orange, size: 19),
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        children: [
          SearchFilterBar(
            query: _query,
            onQueryChanged: (v) => setState(() => _query = v),
            selectedFilter: _filter,
            filters: filters,
            onFilterChanged: (f) {
              setState(() => _filter = f);
              _load();
            },
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: SC.orange))
                : _filteredOrders.isEmpty
                    ? const EmptyState('No hay pedidos')
                    : RefreshIndicator(
                        color: SC.orange,
                        backgroundColor: SC.surface,
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          itemCount: _filteredOrders.length,
                          itemBuilder: (_, i) => _OrderCard(order: _filteredOrders[i]),
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
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            HugeIcon(icon: HugeIcons.strokeRoundedPackage, color: SC.textPrimary, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(order['reference'] ?? '',
                  style: SC.mono(size: 12, color: SC.textSecondary)),
            ),
            StatusBadge(order['payment_status'] ?? 'pending'),
          ]),
          const SizedBox(height: 10),
          InfoRow(Icons.person_rounded, order['customer_name'] ?? ''),
          const SizedBox(height: 4),
          Row(children: [
            Icon(Icons.inventory_2_rounded, size: 13, color: SC.textMuted),
            const SizedBox(width: 6),
            Text('${items.length} producto(s)', style: SC.body(size: 12.5, color: SC.textSecondary)),
            const Spacer(),
            Text('\$${total.toStringAsFixed(2)}',
                style: SC.mono(size: 14, color: SC.orange)),
          ]),
          const SizedBox(height: 4),
          InfoRow(Icons.payment_rounded, _paymentLabel(order['payment_method'] ?? '')),
        ]),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final items = (order['items'] as List?) ?? [];
    showModalBottomSheet(
      context: context,
      backgroundColor: SC.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        builder: (_, sc) => SingleChildScrollView(
          controller: sc,
          padding: const EdgeInsets.all(22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(order['reference'] ?? '',
                  style: SC.mono(size: 15, color: SC.orange))),
              StatusBadge(order['payment_status'] ?? 'pending'),
            ]),
            const SizedBox(height: 16),
            _DR('Cliente', order['customer_name'] ?? ''),
            _DR('Email', order['customer_email'] ?? ''),
            _DR('Teléfono', order['customer_phone'] ?? ''),
            _DR('Dirección', order['shipping_address'] ?? ''),
            _DR('Método pago', _paymentLabel(order['payment_method'] ?? '')),
            _DR('Total', '\$${(order['total'] ?? 0.0).toStringAsFixed(2)}'),
            _DR('Fecha', order['created_at'] ?? ''),
            const SizedBox(height: 16),
            Text('PRODUCTOS',
                style: SC.display(size: 12, color: SC.orange).copyWith(letterSpacing: 1.2)),
            const SizedBox(height: 8),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Expanded(child: Text(
                  '${item['quantity']}x ${item['part_name']}',
                  style: SC.body(size: 13),
                )),
                Text('\$${(item['subtotal'] ?? 0.0).toStringAsFixed(2)}',
                    style: SC.mono(size: 12, color: SC.textMuted)),
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
          child: Text(label, style: SC.body(size: 11.5, color: SC.textMuted))),
      Expanded(child: Text(value, style: SC.body(size: 13))),
    ]),
  );
}