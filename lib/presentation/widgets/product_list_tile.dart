import 'package:flutter/material.dart';

import '../../data/models/warehouse_product_model.dart';

class ProductListTile extends StatelessWidget {
  final WarehouseProductModel warehouseProduct;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;
  final VoidCallback? onDelete;
  final bool isUpdating;
  /// When non-null, replaces the built-in trailing widget entirely.
  final Widget? trailing;

  const ProductListTile({
    super.key,
    required this.warehouseProduct,
    this.onTap,
    this.onAdd,
    this.onRemove,
    this.onDelete,
    this.isUpdating = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final product = warehouseProduct.product;
    final isLow = warehouseProduct.isLowStock;
    final isExpiring = warehouseProduct.hasExpiringBatch;

    return ListTile(
      onTap: isUpdating ? null : onTap,
      leading: product?.imageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                product!.imageUrl!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.image_not_supported),
              ),
            )
          : CircleAvatar(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              child: Icon(Icons.inventory_2,
                  color: theme.colorScheme.onSurfaceVariant),
            ),
      title: Text(product?.name ?? 'Producto ${warehouseProduct.productId}'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Stock: ${warehouseProduct.quantity.toStringAsFixed(2)} '
            '${product?.defaultUnit ?? ''}',
            style: isLow ? TextStyle(color: theme.colorScheme.error) : null,
          ),
          if (isExpiring)
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Chip(
                label: Text('Caduca pronto'),
                labelStyle: TextStyle(fontSize: 10, color: Colors.white),
                backgroundColor: Colors.orange,
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
      trailing: trailing ?? Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLow)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(Icons.warning_amber_rounded,
                  color: theme.colorScheme.error, size: 18),
            ),
          if (isUpdating)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            )
          else ...[
            if (onRemove != null)
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: onRemove,
                tooltip: 'Reducir stock',
              ),
            if (onAdd != null)
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: onAdd,
                tooltip: 'Aumentar stock',
              ),
            if (onDelete != null)
              PopupMenuButton<String>(
                tooltip: 'Más acciones',
                onSelected: (value) {
                  if (value == 'delete') {
                    onDelete?.call();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline,
                            color: Theme.of(context).colorScheme.error),
                        const SizedBox(width: 10),
                        const Text('Eliminar del almacén'),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}
