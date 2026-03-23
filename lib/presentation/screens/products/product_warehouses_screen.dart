import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/router/app_router.dart';
import '../../../data/models/warehouse_product_model.dart';
import '../../cubits/product_warehouses/product_warehouses_cubit.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_indicator.dart';

class ProductWarehousesScreen extends StatefulWidget {
  final int productId;
  final String productName;

  const ProductWarehousesScreen({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  State<ProductWarehousesScreen> createState() =>
      _ProductWarehousesScreenState();
}

class _ProductWarehousesScreenState extends State<ProductWarehousesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProductWarehousesCubit>().load(widget.productId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Almacenes con este producto'),
            if (widget.productName.isNotEmpty)
              Text(
                widget.productName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
              ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: BlocBuilder<ProductWarehousesCubit, ProductWarehousesState>(
          builder: (context, state) {
            if (state is ProductWarehousesLoading ||
                state is ProductWarehousesInitial) {
              return const LoadingIndicator();
            }
            if (state is ProductWarehousesError) {
              return ErrorView(
                message: state.message,
                onRetry: () =>
                    context.read<ProductWarehousesCubit>().load(widget.productId),
              );
            }
            if (state is ProductWarehousesLoaded) {
              if (state.items.isEmpty) {
                return const EmptyView(
                  message: 'Este producto no está en ningún almacén',
                );
              }
              return RefreshIndicator(
                onRefresh: () => context
                    .read<ProductWarehousesCubit>()
                    .load(widget.productId),
                child: ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: state.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    return _WarehouseTile(
                      wp: state.items[i],
                    );
                  },
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}

class _WarehouseTile extends StatelessWidget {
  final WarehouseProductModel wp;

  const _WarehouseTile({required this.wp});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final unit = wp.product?.defaultUnit ?? '';

    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: cs.primaryContainer,
          child: Icon(Icons.warehouse_outlined, color: cs.primary, size: 20),
        ),
        title: Text(
          wp.warehouseName ?? 'Almacén #${wp.warehouseId}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Stock: ${wp.quantity.toStringAsFixed(2)} $unit',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (wp.isLowStock) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: cs.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Stock bajo',
                      style: TextStyle(
                        fontSize: 10,
                        color: cs.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (wp.minQuantity != null)
              Text(
                'Mínimo: ${wp.minQuantity!.toStringAsFixed(2)} $unit',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
            if (wp.pricePerUnit != null)
              Text(
                'Precio: ${wp.pricePerUnit!.toStringAsFixed(2)} €/ud',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
            if (wp.store != null)
              Text(
                'Tienda: ${wp.store!.name}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.openAuxiliaryRoute(
          '/products/${wp.id}/detail',
          extra: {'warehouseId': wp.warehouseId},
        ),
      ),
    );
  }
}
