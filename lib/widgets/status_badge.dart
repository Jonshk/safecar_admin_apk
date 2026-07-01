// lib/widgets/status_badge.dart
import 'package:flutter/material.dart';
import '../theme/sc_theme.dart';

const _statusLabels = {
  'pending': 'Pendiente',
  'confirmed': 'Confirmado',
  'in_progress': 'En curso',
  'completed': 'Completado',
  'cancelled': 'Cancelado',
  'paid': 'Pagado',
  'awaiting_verification': 'Verificando',
  'failed': 'Fallido',
};

/// Badge de estado cuadrado (no pill), línea fina, color por estado
/// según SC.statusColor — consistente con el cluster de instrumentos.
/// [overrideLabel] permite mostrar "En camino" en vez de "En curso"
/// cuando el contexto es una grúa, sin tocar el estado interno.
class StatusBadge extends StatelessWidget {
  final String status;
  final String? overrideLabel;
  const StatusBadge(this.status, {super.key, this.overrideLabel});

  @override
  Widget build(BuildContext context) {
    final color = SC.statusColor(status);
    final bg = SC.statusBg(status);
    final label = overrideLabel ?? (_statusLabels[status] ?? status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label.toUpperCase(),
        style: SC.body(size: 9.5, weight: FontWeight.w500, color: color)
            .copyWith(letterSpacing: 0.6),
      ),
    );
  }
}

/// Card base del cluster: superficie oscura, borde fino, sin sombra,
/// sin radios exagerados — reemplaza el AdminCard anterior.
class AdminCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const AdminCard({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: SC.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: SC.border),
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
  final Map<String, String>? labelOverrides;

  const StatusSelectorSheet({
    super.key,
    required this.currentStatus,
    required this.options,
    required this.onSelected,
    this.labelOverrides,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: SC.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: SC.border)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 3,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: SC.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text('CAMBIAR ESTADO',
              style: SC.display(size: 13, color: SC.orange)
                  .copyWith(letterSpacing: 1.5)),
          const SizedBox(height: 14),
          ...options.map((s) {
            final label = labelOverrides?[s] ?? (_statusLabels[s] ?? s);
            final selected = s == currentStatus;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(label,
                  style: SC.body(
                    size: 14,
                    color: selected ? SC.orange : SC.textPrimary,
                  )),
              leading: StatusBadge(s, overrideLabel: label),
              trailing: selected
                  ? const Icon(Icons.check_rounded, color: SC.orange, size: 18)
                  : null,
              onTap: () {
                Navigator.pop(context);
                onSelected(s);
              },
            );
          }),
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
        Icon(icon, size: 13, color: SC.textMuted),
        const SizedBox(width: 6),
        Expanded(
            child: Text(text,
                style: SC.body(size: 12.5, color: SC.textSecondary),
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
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: SC.bg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(0.35)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(label,
                style: SC.body(size: 11.5, weight: FontWeight.w500, color: color)),
          ]),
        ),
      );
}

class FilterBar extends StatelessWidget {
  final String selected;
  final void Function(String) onChanged;
  final List<(String, String)> filters;
  const FilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
    this.filters = const [
      ('all', 'Todos'),
      ('pending', 'Pendiente'),
      ('confirmed', 'Confirmado'),
      ('in_progress', 'En curso'),
      ('completed', 'Completado'),
    ],
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: filters.map((f) {
          final isSelected = selected == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(f.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected ? SC.orangeBg : SC.surface,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                      color: isSelected ? SC.orange.withOpacity(0.5) : SC.border),
                ),
                child: Text(f.$2,
                    style: SC.body(
                      size: 12,
                      weight: FontWeight.w500,
                      color: isSelected ? SC.orange : SC.textSecondary,
                    )),
              ),
            ),
          );
        }).toList(),
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
          Icon(Icons.inbox_rounded, color: SC.border, size: 56),
          const SizedBox(height: 12),
          Text(msg, style: SC.body(size: 13, color: SC.textMuted)),
        ]),
      );
}