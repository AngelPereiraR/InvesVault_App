import 'package:flutter/material.dart';

/// Red action bar shown in multi-select delete mode.
/// Shared across Brands, Stores, Products, Warehouses and Warehouse Detail.
class DeleteModeBar extends StatelessWidget {
  final int count;
  final VoidCallback onCancel;
  /// Null → Eliminar button is disabled (nothing selected yet).
  final VoidCallback? onDelete;

  const DeleteModeBar({
    super.key,
    required this.count,
    required this.onCancel,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.red.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            color: Colors.red.shade700,
            tooltip: 'Cancelar selección',
            onPressed: onCancel,
          ),
          Expanded(
            child: Text(
              count == 0
                  ? 'Selecciona elementos'
                  : '$count ${count == 1 ? 'elemento seleccionado' : 'elementos seleccionados'}',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          TextButton(
            onPressed: onDelete,
            style: TextButton.styleFrom(
              foregroundColor: Colors.red.shade700,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
