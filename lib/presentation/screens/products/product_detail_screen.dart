import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/notification/notification_cubit.dart';
import '../../cubits/product_detail/product_detail_cubit.dart';
import '../../cubits/stock_change/stock_change_cubit.dart';
import '../../cubits/store/store_cubit.dart';
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
  String _historyFilter = 'all'; // 'all' | 'inbound' | 'outbound' | 'adjustment'

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

                // ── Editar detalles del almacén ──────────────────────
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _WarehouseDetailsEditor(
                      wp: wp,
                      product: product,
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

                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _HistoryTypeChip(
                        label: 'Todos',
                        selected: _historyFilter == 'all',
                        color: const Color(0xFF3C096C),
                        onTap: () => setState(() => _historyFilter = 'all'),
                      ),
                      const SizedBox(width: 6),
                      _HistoryTypeChip(
                        label: 'Entradas',
                        selected: _historyFilter == 'inbound',
                        color: Colors.green,
                        onTap: () => setState(() => _historyFilter = 'inbound'),
                      ),
                      const SizedBox(width: 6),
                      _HistoryTypeChip(
                        label: 'Salidas',
                        selected: _historyFilter == 'outbound',
                        color: Colors.red,
                        onTap: () => setState(() => _historyFilter = 'outbound'),
                      ),
                      const SizedBox(width: 6),
                      _HistoryTypeChip(
                        label: 'Ajustes',
                        selected: _historyFilter == 'adjustment',
                        color: Colors.orange,
                        onTap: () =>
                            setState(() => _historyFilter = 'adjustment'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                BlocBuilder<StockChangeCubit, StockChangeState>(
                  builder: (context, state) {
                    if (state is StockChangeLoading) {
                      return const LoadingIndicator();
                    }
                    if (state is StockChangeLoaded) {
                      final filtered = _historyFilter == 'all'
                          ? state.changes
                          : state.changes
                              .where((c) => c.changeType == _historyFilter)
                              .toList();

                      if (filtered.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text(
                              'Sin movimientos',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.grey),
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 6),
                        itemBuilder: (context, i) {
                          final c = filtered[i];
                          final isInbound = c.changeType == 'inbound';
                          final isAdjustment = c.changeType == 'adjustment';
                          final iconColor = isInbound
                              ? Colors.green
                              : isAdjustment
                                  ? Colors.orange
                                  : Colors.red;
                          final icon = isInbound
                              ? Icons.arrow_circle_down_rounded
                              : isAdjustment
                                  ? Icons.tune_rounded
                                  : Icons.arrow_circle_up_rounded;
                          final sign = isInbound ? '+' : isAdjustment ? '±' : '-';
                          final dateStr = DateFormat('dd/MM/yy HH:mm').format(
                              DateTime.tryParse(c.createdAt ?? '') ??
                                  DateTime.now());

                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: iconColor.withAlpha(30),
                                    child: Icon(icon,
                                        color: iconColor, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: iconColor.withAlpha(30),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                '$sign${c.changeQuantity}',
                                                style: TextStyle(
                                                  color: iconColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                            if (c.reason != null &&
                                                c.reason!.isNotEmpty) ...[
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  c.reason!,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.person_outline,
                                                size: 12,
                                                color: Colors.grey),
                                            const SizedBox(width: 3),
                                            Text(
                                              c.userName ?? 'Sistema',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                      color: Colors.grey[600]),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(Icons.access_time,
                                                size: 12,
                                                color: Colors.grey),
                                            const SizedBox(width: 3),
                                            Text(
                                              dateStr,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                      color: Colors.grey[600]),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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

// ── Editar detalles del warehouse-product ──────────────────────────────────
class _WarehouseDetailsEditor extends StatefulWidget {
  final dynamic wp;
  final dynamic product;
  const _WarehouseDetailsEditor({required this.wp, required this.product});

  @override
  State<_WarehouseDetailsEditor> createState() =>
      _WarehouseDetailsEditorState();
}

class _WarehouseDetailsEditorState extends State<_WarehouseDetailsEditor> {
  late final TextEditingController _minQtyCtrl;
  late final TextEditingController _priceCtrl;
  int? _storeId;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    final wp = widget.wp;
    _minQtyCtrl = TextEditingController(
        text: wp.minQuantity != null
            ? wp.minQuantity.toStringAsFixed(2)
            : '');
    _priceCtrl = TextEditingController(
        text: wp.pricePerUnit != null
            ? wp.pricePerUnit.toStringAsFixed(2)
            : '');
    _storeId = wp.storeId as int?;
  }

  @override
  void dispose() {
    _minQtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final data = <String, dynamic>{};
    if (_minQtyCtrl.text.isNotEmpty) {
      data['min_quantity'] = double.tryParse(_minQtyCtrl.text) ?? 0;
    }
    if (_priceCtrl.text.isNotEmpty) {
      data['price_per_unit'] = double.tryParse(_priceCtrl.text) ?? 0;
    }
    if (_storeId != null) data['store_id'] = _storeId;
    if (data.isEmpty) return;
    context.read<ProductDetailCubit>().updateDetails(data);
    setState(() => _expanded = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Configuración del almacén',
                style: theme.textTheme.titleSmall),
            const Spacer(),
            TextButton.icon(
              icon: Icon(_expanded ? Icons.expand_less : Icons.edit_outlined,
                  size: 18),
              label: Text(_expanded ? 'Cancelar' : 'Editar'),
              onPressed: () => setState(() => _expanded = !_expanded),
            ),
          ],
        ),
        if (_expanded) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _minQtyCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Cantidad mínima (alerta)',
              prefixIcon: Icon(Icons.warning_amber_outlined),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _priceCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Precio por unidad (€)',
              prefixIcon: Icon(Icons.euro_outlined),
            ),
          ),
          const SizedBox(height: 10),
          BlocBuilder<StoreCubit, StoreState>(
            builder: (context, state) {
              if (state is! StoreLoaded) {
                context.read<StoreCubit>().load();
                return const SizedBox();
              }
              return DropdownButtonFormField<int?>(
                value: _storeId,
                decoration: const InputDecoration(
                  labelText: 'Tienda (última compra)',
                  prefixIcon: Icon(Icons.store_outlined),
                ),
                items: [
                  const DropdownMenuItem(
                      value: null, child: Text('Sin tienda')),
                  ...state.stores.map((s) =>
                      DropdownMenuItem(value: s.id, child: Text(s.name))),
                ],
                onChanged: (v) => setState(() => _storeId = v),
              );
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              child: const Text('Guardar cambios'),
            ),
          ),
        ],
      ],
    );
  }
}

// ── History type filter chip ───────────────────────────────────────────────
class _HistoryTypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _HistoryTypeChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : color.withAlpha(20),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 1.4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : color,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
