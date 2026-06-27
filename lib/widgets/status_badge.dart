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
      child: Text(label,
          style: GoogleFonts.inter(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          )),
    );
  }

  (Color, String) _resolve(String s) => switch (s) {
        'pending' => (const Color(0xFFF59E0B), 'Pendiente'),
        'confirmed' => (const Color(0xFF3B82F6), 'Confirmado'),
        'in_progress' => (const Color(0xFF8B5CF6), 'En curso'),
        'completed' => (const Color(0xFF10B981), 'Completado'),
        'cancelled' => (const Color(0xFFEF4444), 'Cancelado'),
        'paid' => (const Color(0xFF10B981), 'Pagado'),
        'awaiting_verification' => (const Color(0xFFF59E0B), 'Verificando'),
        'failed' => (const Color(0xFFEF4444), 'Fallido'),
        _ => (Colors.white38, s),
      };
}

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
    const labels = {
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
          const Text('Cambiar estado',
              style: TextStyle(
                color: Color(0xFFD4AF37),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              )),
          const SizedBox(height: 16),
          ...options.map((s) => ListTile(
                title: Text(labels[s] ?? s,
                    style: TextStyle(
                      color: s == currentStatus
                          ? const Color(0xFFD4AF37)
                          : Colors.white,
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

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const InfoRow(this.icon, this.text, {super.key});
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 14, color: Colors.white38),
        const SizedBox(width: 6),
        Expanded(
            child: Text(text,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis)),
      ]);
}

class ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const ActionBtn(
      {super.key,
      required this.icon,
      required this.label,
      required this.color,
      required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}

class FilterBar extends StatelessWidget {
  final String selected;
  final void Function(String) onChanged;
  const FilterBar({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const filters = [
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
        children: filters
            .map((f) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f.$2),
                    selected: selected == f.$1,
                    onSelected: (_) => onChanged(f.$1),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String msg;
  const EmptyState(this.msg, {super.key});
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.inbox_rounded, color: Colors.white24, size: 64),
          const SizedBox(height: 12),
          Text(msg, style: const TextStyle(color: Colors.white38)),
        ]),
      );
}
