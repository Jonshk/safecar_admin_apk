// lib/widgets/search_filter_bar.dart
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../theme/sc_theme.dart';

/// Campo de búsqueda + fila de filtros de estado, en un solo bloque.
/// El degradado en los bordes de los filtros le avisa al usuario que
/// hay más opciones para scrollear (antes se veía "cortado").
class SearchFilterBar extends StatelessWidget {
  final String query;
  final ValueChanged<String> onQueryChanged;
  final String hint;
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;
  final List<(String, String)> filters;

  const SearchFilterBar({
    super.key,
    required this.query,
    required this.onQueryChanged,
    required this.selectedFilter,
    required this.onFilterChanged,
    this.hint = 'Buscar por referencia o cliente',
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: SC.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: SC.border),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                HugeIcon(
                    icon: HugeIcons.strokeRoundedSearch01,
                    color: SC.textMuted,
                    size: 17),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: onQueryChanged,
                    style: SC.body(size: 13.5),
                    cursorColor: SC.orange,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: hint,
                      hintStyle: SC.body(size: 13, color: SC.textMuted),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                if (query.isNotEmpty)
                  GestureDetector(
                    onTap: () => onQueryChanged(''),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(Icons.close_rounded, color: SC.textMuted, size: 16),
                    ),
                  )
                else
                  const SizedBox(width: 12),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: ShaderMask(
            shaderCallback: (rect) => LinearGradient(
              colors: const [
                Colors.transparent,
                Colors.white,
                Colors.white,
                Colors.transparent,
              ],
              stops: const [0.0, 0.03, 0.94, 1.0],
            ).createShader(rect),
            blendMode: BlendMode.dstIn,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final f in filters)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterPill(
                      label: f.$2,
                      selected: selectedFilter == f.$1,
                      onTap: () => onFilterChanged(f.$1),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterPill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? SC.orange : SC.surface,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: selected ? SC.orange : SC.border),
        ),
        child: Text(
          label,
          style: SC.body(
            size: 12,
            weight: FontWeight.w500,
            color: selected ? Colors.black : SC.textSecondary,
          ),
        ),
      ),
    );
  }
}