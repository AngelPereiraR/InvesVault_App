import 'package:flutter/material.dart';

/// Red action bar shown in multi-select delete mode.
/// Shared across Brands, Stores, Products, Warehouses and Warehouse Detail.
class DeleteModeBar extends StatelessWidget {
  final int count;
  final VoidCallback onCancel;
  /// Null → Eliminar button is disabled (nothing selected yet).
  final VoidCallback? onDelete;
  /// Text shown when count == 0 (e.g. 'Selecciona marcas').
  final String emptyLabel;
  /// Full label after the count when count == 1 (e.g. 'marca seleccionada').
  final String selectedSingular;
  /// Full label after the count when count != 1 (e.g. 'marcas seleccionadas').
  final String selectedPlural;

  const DeleteModeBar({
    super.key,
    required this.count,
    required this.onCancel,
    this.onDelete,
    this.emptyLabel = 'Selecciona elementos',
    this.selectedSingular = 'elemento seleccionado',
    this.selectedPlural = 'elementos seleccionados',
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.errorContainer,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            color: cs.error,
            tooltip: 'Cancelar selección',
            onPressed: onCancel,
          ),
          Expanded(
            child: Text(
              count == 0
                  ? emptyLabel
                  : '$count ${count == 1 ? selectedSingular : selectedPlural}',
              style: TextStyle(
                color: cs.error,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          TextButton(
            onPressed: onDelete,
            style: TextButton.styleFrom(
              foregroundColor: cs.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
