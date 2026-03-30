import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/router/app_router.dart';
import '../../../data/models/batch_model.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/batch/batch_cubit.dart';
import '../../cubits/notification/notification_cubit.dart';
import '../../cubits/product_detail/product_detail_cubit.dart';
import '../../cubits/stock_change/stock_change_cubit.dart';
import '../../dialogs/add_edit_batch_dialog.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/quantity_stepper.dart';

class ProductDetailScreen extends StatefulWidget {
  final int warehouseProductId;
  final int warehouseId;
  const ProductDetailScreen({
    super.key,
    required this.warehouseProductId,
    required this.warehouseId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  double _delta = 1.0;
  bool _isAdding = true;

  @override
  void initState() {
    super.initState();
    context
        .read<ProductDetailCubit>()
        .load(widget.warehouseId, widget.warehouseProductId);
    context
        .read<StockChangeCubit>()
        .loadByProduct(0); // will reload after first load
    context.read<BatchCubit>().load(widget.warehouseProductId);
  }

  void _applyDelta() {
    final authState = context.read<AuthCubit>().state;
    final userId = authState is AuthAuthenticated ? authState.userId : 0;
    context.read<ProductDetailCubit>().quickUpdate(
          delta: _isAdding ? _delta : -_delta,
          userId: userId,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de producto')),
      body: SafeArea(top: false, child: BlocConsumer<ProductDetailCubit, ProductDetailState>(
        listener: (context, state) {
          if (state is ProductDetailLoaded) {
            context
                .read<StockChangeCubit>()
                .loadByProduct(state.warehouseProduct.productId);
            // Refresh notification badge in case stock crossed below minimum
            context.read<NotificationCubit>().load();
          }
          if (state is ProductDetailError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error));
          }
        },
        builder: (context, state) {
          if (state is ProductDetailLoading || state is ProductDetailInitial) {
            return const LoadingIndicator();
          }
          if (state is ProductDetailError) {
            return ErrorView(message: state.message);
          }
          final wp = (state is ProductDetailLoaded)
              ? state.warehouseProduct
              : (state as ProductDetailUpdating).warehouseProduct;
          final product = wp.product;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product header
                if (product?.imageUrl != null)
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(product!.imageUrl!,
                          height: 160, fit: BoxFit.cover),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  product?.name ?? 'Producto ${wp.productId}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (product?.brand != null)
                  Text(product!.brand!.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 24),

                // Stock info
                _InfoCard(children: [
                  _InfoRow('Stock actual',
                      '${wp.quantity.toStringAsFixed(2)} ${product?.defaultUnit ?? ''}'),
                  if (wp.minQuantity != null)
                    _InfoRow('Cantidad mínima',
                        '${wp.minQuantity!.toStringAsFixed(2)} ${product?.defaultUnit ?? ''}'),
                  if (wp.pricePerUnit != null)
                    _InfoRow('Precio/unidad',
                        '${wp.pricePerUnit!.toStringAsFixed(2)} €'),
                  if (wp.store != null) _InfoRow('Tienda', wp.store!.name),
                  if (wp.observations != null && wp.observations!.isNotEmpty)
                    _InfoRow('Observaciones', wp.observations!),
                  _InfoRow('Código de barras',
                      product?.barcode ?? 'No especificado'),
                ]),

                if (wp.isLowStock) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Theme.of(context).colorScheme.onErrorContainer),
                        const SizedBox(width: 8),
                        Text(
                          'Stock bajo el mínimo',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Quick update
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text('Actualización rápida',
                                  style:
                                      Theme.of(context).textTheme.titleSmall),
                            ),
                            SegmentedButton<bool>(
                              segments: const [
                                ButtonSegment(
                                    value: true,
                                    label: Text('Entrada'),
                                    icon: Icon(Icons.add)),
                                ButtonSegment(
                                    value: false,
                                    label: Text('Salida'),
                                    icon: Icon(Icons.remove)),
                              ],
                              selected: {_isAdding},
                              onSelectionChanged: (s) =>
                                  setState(() => _isAdding = s.first),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon:
                                    Icon(_isAdding ? Icons.add : Icons.remove),
                                label: Text(
                                    '${_isAdding ? 'Añadir' : 'Quitar'} $_delta ${product?.defaultUnit ?? 'unidades'}'),
                                onPressed: state is ProductDetailUpdating
                                    ? null
                                    : _applyDelta,
                              ),
                            ),
                            const SizedBox(width: 12),
                            QuantityStepper(
                              value: _delta,
                              min: 1,
                              onChanged: (v) => setState(() => _delta = v),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Batch / expiry dates
                _BatchSection(
                  warehouseProductId: widget.warehouseProductId,
                  warehouseId: widget.warehouseId,
                  totalStock: wp.quantity,
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.openAuxiliaryRoute(
                      '/products/${wp.productId}/history',
                      extra: {'productName': product?.name ?? 'Producto'},
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Ver historial de cambios',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: () => context.openAuxiliaryRoute(
                          '/products/${wp.id}/warehouse-config',
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.tune),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Ajustes en almacén',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: () => context.openAuxiliaryRoute(
                          '/products/${wp.productId}/edit',
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Editar ficha del producto',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 80),
              ],
            ),
          );
        },
      )),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: children),
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(value,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.end),
            ),
          ],
        ),
      );
}

// ── Batch / expiry date section ────────────────────────────────────────────
class _BatchSection extends StatelessWidget {
  final int warehouseProductId;
  final int warehouseId;
  final double totalStock;
  const _BatchSection({
    required this.warehouseProductId,
    required this.warehouseId,
    required this.totalStock,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return BlocBuilder<BatchCubit, BatchState>(
      builder: (context, state) {
        final batches = state is BatchLoaded ? state.batches : <BatchModel>[];
        final totalBatched =
            batches.fold<double>(0.0, (s, b) => s + b.quantity);
        final addMaxQty = totalStock - totalBatched;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Fechas de caducidad',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (addMaxQty > 0)
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Asignar'),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => BlocProvider.value(
                        value: context.read<BatchCubit>(),
                        child: AddEditBatchDialog(
                          warehouseProductId: warehouseProductId,
                          maxQuantity: addMaxQty,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (state is BatchLoading || state is BatchMutating)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (state is BatchError)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(state.message,
                    style: TextStyle(color: cs.error)),
              )
            else if (batches.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Sin fechas asignadas',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant),
                ),
              )
            else
              Card(
                child: Column(
                  children: batches.map((b) {
                    final isExpiring = b.isExpiringSoon;
                    final qtyStr = b.quantity % 1 == 0
                        ? '${b.quantity.toInt()} uds'
                        : '${b.quantity} uds';
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        Icons.inventory_2_outlined,
                        size: 18,
                        color: isExpiring ? Colors.orange : cs.onSurfaceVariant,
                      ),
                      title: Row(
                        children: [
                          Text(qtyStr),
                          if (b.expiryDate != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              'vence ${b.expiryDate}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: isExpiring
                                          ? Colors.orange
                                          : null),
                            ),
                            if (isExpiring) ...[
                              const SizedBox(width: 4),
                              const Text('⚠️',
                                  style: TextStyle(fontSize: 12)),
                            ],
                          ] else
                            Text(
                              ' sin fecha',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                        ],
                      ),
                      subtitle: b.notes != null ? Text(b.notes!) : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon:
                                const Icon(Icons.edit_outlined, size: 18),
                            tooltip: 'Editar',
                            onPressed: () => showDialog(
                              context: context,
                              builder: (_) => BlocProvider.value(
                                value: context.read<BatchCubit>(),
                                child: AddEditBatchDialog(
                                  warehouseProductId: warehouseProductId,
                                  maxQuantity: addMaxQty + b.quantity,
                                  batch: BatchItem(
                                    id: b.id,
                                    quantity: b.quantity,
                                    expiryDate: b.expiryDate,
                                    notes: b.notes,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline,
                                size: 18, color: cs.error),
                            tooltip: 'Eliminar',
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (dialogCtx) => AlertDialog(
                                  title:
                                      const Text('Eliminar caducidad'),
                                  content: Text(
                                    'Se eliminarán $qtyStr con fecha '
                                    '${b.expiryDate ?? 'sin asignar'}. '
                                    'El stock se reducirá en la misma cantidad.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(dialogCtx)
                                              .pop(false),
                                      child: const Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(dialogCtx)
                                              .pop(true),
                                      child: Text(
                                        'Eliminar',
                                        style: TextStyle(
                                            color: Theme.of(dialogCtx)
                                                .colorScheme
                                                .error),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true && context.mounted) {
                                await context.read<BatchCubit>().deleteBatch(
                                      batchId: b.id,
                                      warehouseProductId: warehouseProductId,
                                    );
                                if (context.mounted) {
                                  context.read<ProductDetailCubit>().load(
                                        warehouseId,
                                        warehouseProductId,
                                      );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        );
      },
    );
  }
}

