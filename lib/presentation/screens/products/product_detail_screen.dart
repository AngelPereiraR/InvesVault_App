import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/product_detail/product_detail_cubit.dart';
import '../../cubits/stock_change/stock_change_cubit.dart';
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
  }

  void _applyDelta() {
    final authState = context.read<AuthCubit>().state;
    final userId =
        authState is AuthAuthenticated ? authState.userId : 0;
    context.read<ProductDetailCubit>().quickUpdate(
          delta: _isAdding ? _delta : -_delta,
          userId: userId,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de producto')),
      body: BlocConsumer<ProductDetailCubit, ProductDetailState>(
        listener: (context, state) {
          if (state is ProductDetailLoaded) {
            context
                .read<StockChangeCubit>()
                .loadByProduct(state.warehouseProduct.productId);
          }
          if (state is ProductDetailError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error));
          }
        },
        builder: (context, state) {
          if (state is ProductDetailLoading ||
              state is ProductDetailInitial) {
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
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant)),
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
                  if (wp.store != null)
                    _InfoRow('Tienda', wp.store!.name),
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
                            color: Theme.of(context).colorScheme.error),
                        const SizedBox(width: 8),
                        Text(
                          'Stock bajo el mínimo',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
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
                        Text('Actualización rápida',
                            style:
                                Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 12),
                        Row(
                          children: [
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
                        QuantityStepper(
                          value: _delta,
                          min: 1,
                          onChanged: (v) => setState(() => _delta = v),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: Icon(_isAdding ? Icons.add : Icons.remove),
                            label: Text(
                                '${_isAdding ? 'Añadir' : 'Quitar'} $_delta ${product?.defaultUnit ?? 'unidades'}'),
                            onPressed: state is ProductDetailUpdating
                                ? null
                                : _applyDelta,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Edit button
                OutlinedButton.icon(
                  onPressed: () => context
                      .push('/products/${wp.productId}/edit'),
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar información del producto'),
                ),

                const SizedBox(height: 32),

                // Stock history
                Text('Historial de cambios',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                BlocBuilder<StockChangeCubit, StockChangeState>(
                  builder: (context, state) {
                    if (state is StockChangeLoading) {
                      return const LoadingIndicator();
                    }
                    if (state is StockChangeLoaded &&
                        state.changes.isEmpty) {
                      return const Text('Sin historial');
                    }
                    if (state is StockChangeLoaded) {
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.changes.length,
                        itemBuilder: (context, i) {
                          final c = state.changes[i];
                          final isEntry = c.changeType == 'entrada';
                          return ListTile(
                            leading: Icon(
                              isEntry
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color: isEntry ? Colors.green : Colors.red,
                            ),
                            title: Text(
                                '${isEntry ? '+' : '-'}${c.changeQuantity}'),
                            subtitle: Text(c.reason ?? c.changeType),
                            trailing: Text(
                              DateFormat('dd/MM/yy HH:mm')
                                  .format(DateTime.tryParse(c.createdAt ?? '') ?? DateTime.now()),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall,
                            ),
                          );
                        },
                      );
                    }
                    return const SizedBox();
                  },
                ),

                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
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
          children: [
            Text(label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant)),
            Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
}
