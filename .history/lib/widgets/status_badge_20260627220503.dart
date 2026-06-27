// lib/widgets/status_badge.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final (color, label) = _resolve(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: color, fontSize: 11, fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  (Color, String) _resolve(String s) => switch (s) {
    'pending'      => (const Color(0xFFF59E0B), 'Pendiente'),
    'confirmed'    => (const Color(0xFF3B82F6), 'Confirmado'),
    'in_progress'  => (const Color(0xFF8B5CF6), 'En curso'),
    'completed'    => (const Color(0xFF10B981), 'Completado'),
    'cancelled'    => (const Color(0xFFEF4444), 'Cancelado'),
    'paid'         => (const Color(0xFF10B981), 'Pagado'),
    'awaiting_verification' => (const Color(0xFFF59E0B), 'Verificando'),
    'failed'       => (const Color(0xFFEF4444), 'Fallido'),
    _              => (Colors.white38, s),
  };
}

// ── Tarjeta base reutilizable ─────────────────────────────
class AdminCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const AdminCard({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: child,
      ),
    );
  }
}

// ── Selector de estado (bottom sheet) ────────────────────
class StatusSelectorSheet extends StatelessWidget {
  final String currentStatus;
  final List<String> options;
  final void Function(String) onSelected;

  const StatusSelectorSheet({
    super.key,
    required this.currentStatus,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final labels = {
      'pending': 'Pendiente',
      'confirmed': 'Confirmado',
      'in_progress': 'En curso',
      'completed': 'Completado',
      'cancelled': 'Cancelado',
    };
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cambiar estado', style: TextStyle(
            color: Color(0xFFD4AF37), fontSize: 16, fontWeight: FontWeight.bold,
          )),
          const SizedBox(height: 16),
          ...options.map((s) => ListTile(
            title: Text(labels[s] ?? s, style: TextStyle(
              color: s == currentStatus ? const Color(0xFFD4AF37) : Colors.white,
            )),
            leading: StatusBadge(s),
            trailing: s == currentStatus
                ? const Icon(Icons.check, color: Color(0xFFD4AF37))
                : null,
            onTap: () {
              Navigator.pop(context);
              onSelected(s);
            },
          )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
