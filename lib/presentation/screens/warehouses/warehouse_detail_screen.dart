import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/router/app_router.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/product_form/product_form_cubit.dart';
import '../../cubits/store/store_cubit.dart';
import '../../cubits/warehouse_detail/warehouse_detail_cubit.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/delete_mode_bar.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/low_stock_badge.dart';
import '../../widgets/product_list_tile.dart';

class WarehouseDetailScreen extends StatefulWidget {
  final int warehouseId;
  const WarehouseDetailScreen({super.key, required this.warehouseId});

  @override
  State<WarehouseDetailScreen> createState() => _WarehouseDetailScreenState();
}

class _WarehouseDetailScreenState extends State<WarehouseDetailScreen> {
  final _searchCtrl = TextEditingController();
  bool _deleteMode = false;
  final Set<int> _selected = {};

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    final userId = authState is AuthAuthenticated ? authState.userId : 0;
    context
        .read<WarehouseDetailCubit>()
        .load(widget.warehouseId, userId: userId);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _exitDeleteMode() => setState(() {
        _deleteMode = false;
        _selected.clear();
      });

  void _toggleSelect(int id) => setState(() {
        if (_selected.contains(id)) {
          _selected.remove(id);
          if (_selected.isEmpty) _deleteMode = false;
        } else {
          _selected.add(id);
        }
      });

  Future<void> _deleteSelected() async {
    final count = _selected.length;
    final confirm = await showConfirmDialog(
      context,
      title: 'Eliminar productos',
      message:
          '¿Eliminar $count ${count == 1 ? 'producto' : 'productos'} del almacén? Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      isDangerous: true,
    );
    if (confirm != true || !mounted) return;
    final ids = List<int>.from(_selected);
    setState(() {
      _deleteMode = false;
      _selected.clear();
    });
    context
        .read<WarehouseDetailCubit>()
        .removeProducts(ids, widget.warehouseId);
  }

  void _showAddProductSheet() {
    context.read<ProductFormCubit>().loadForPicker();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => BlocProvider.value(
        value: context.read<ProductFormCubit>(),
        child: SafeArea(
          top: false,
          child: _AddProductSheet(warehouseId: widget.warehouseId),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final userId = authState is AuthAuthenticated ? authState.userId : 0;

    return BlocBuilder<WarehouseDetailCubit, WarehouseDetailState>(
      builder: (context, state) {
        if (state is WarehouseDetailLoading ||
            state is WarehouseDetailInitial) {
          return const LoadingIndicator();
        }
        if (state is WarehouseDetailError) {
          return ErrorView(
            message: state.message,
            onRetry: () => context
                .read<WarehouseDetailCubit>()
                .load(widget.warehouseId, userId: userId),
          );
        }
        if (state is! WarehouseDetailLoaded) return const SizedBox();

        final lowCount = state.products.where((p) => p.isLowStock).length;

        return Column(
          children: [
            // ── Header actions bar ─
            if (_deleteMode)
              DeleteModeBar(
                count: _selected.length,
                onCancel: _exitDeleteMode,
                onDelete: _selected.isEmpty ? null : _deleteSelected,
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    LowStockBadge(count: lowCount),
                    const Spacer(),
                    if (state.isAdmin)
                      TextButton.icon(
                        onPressed: () => context
                            .push('/warehouses/${widget.warehouseId}/share'),
                        icon: const Icon(Icons.share),
                        label: const Text('Compartir'),
                      ),
                    if (state.canEdit) ...[
                      IconButton(
                        icon: const Icon(Icons.add),
                        tooltip: 'Añadir producto',
                        onPressed: _showAddProductSheet,
                      ),
                      IconButton(
                        icon: Icon(Icons.checklist_rounded,
                            color: Colors.grey.shade500),
                        tooltip: 'Seleccionar para borrar',
                        onPressed: () => setState(() => _deleteMode = true),
                      ),
                    ],
                  ],
                ),
              ),

            // ── Search (hidden in delete mode) ─
            if (!_deleteMode)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Buscar producto…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              context
                                  .read<WarehouseDetailCubit>()
                                  .search('');
                            },
                          )
                        : null,
                  ),
                  onChanged: (q) =>
                      context.read<WarehouseDetailCubit>().search(q),
                ),
              ),

            // ── Product list ─
            Expanded(
              child: state.isDeleting
                  ? const LoadingIndicator(message: 'Eliminando…')
                  : state.filtered.isEmpty
                      ? EmptyView(
                          message: 'No hay productos en este almacén',
                          actionLabel:
                              state.canEdit ? 'Añadir producto' : null,
                          onAction:
                              state.canEdit ? _showAddProductSheet : null,
                        )
                      : RefreshIndicator(
                          onRefresh: () => context
                              .read<WarehouseDetailCubit>()
                              .load(widget.warehouseId, userId: userId),
                          child: ListView.separated(
                            itemCount: state.filtered.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (context, i) {
                              final item = state.filtered[i];
                              final isUpdating =
                                  state.updatingProductIds.contains(item.id);
                              final isSelected = _selected.contains(item.id);
                              return GestureDetector(
                                onTap: _deleteMode
                                    ? () => _toggleSelect(item.id)
                                    : null,
                                child: ColoredBox(
                                  color: isSelected && _deleteMode
                                      ? Colors.red.shade50
                                      : Colors.transparent,
                                  child: ProductListTile(
                                    warehouseProduct: item,
                                    isUpdating: isUpdating,
                                    // In delete mode show checkbox, disable actions
                                    onTap: _deleteMode
                                        ? null
                                        : () => context.openAuxiliaryRoute(
                                            '/products/${item.id}/detail',
                                            extra: {
                                              'warehouseId': widget.warehouseId
                                            }),
                                    onAdd: _deleteMode ||
                                            !state.canEdit ||
                                            isUpdating
                                        ? null
                                        : () => context
                                            .read<WarehouseDetailCubit>()
                                            .quickUpdate(
                                              warehouseProductId: item.id,
                                              productId: item.productId,
                                              warehouseId: widget.warehouseId,
                                              userId: userId,
                                              delta: 1.0,
                                            ),
                                    onRemove: _deleteMode ||
                                            !state.canEdit ||
                                            isUpdating
                                        ? null
                                        : () async {
                                            if ((item.quantity - 1) < 0) {
                                              return;
                                            }
                                            context
                                                .read<WarehouseDetailCubit>()
                                                .quickUpdate(
                                                  warehouseProductId: item.id,
                                                  productId: item.productId,
                                                  warehouseId:
                                                      widget.warehouseId,
                                                  userId: userId,
                                                  delta: -1.0,
                                                );
                                          },
                                    onDelete: _deleteMode ||
                                            !state.canEdit ||
                                            isUpdating
                                        ? null
                                        : () async {
                                            final confirm =
                                                await showConfirmDialog(
                                              context,
                                              title: 'Eliminar producto',
                                              message:
                                                  '¿Quieres eliminar "${item.product?.name ?? 'este producto'}" de este almacén?',
                                              confirmLabel: 'Eliminar',
                                              isDangerous: true,
                                            );
                                            if (confirm == true &&
                                                context.mounted) {
                                              context
                                                  .read<WarehouseDetailCubit>()
                                                  .removeProduct(
                                                    item.id,
                                                    widget.warehouseId,
                                                  );
                                            }
                                          },
                                    // Selection indicator suffix
                                    trailing: _deleteMode
                                        ? Icon(
                                            isSelected
                                                ? Icons.check_circle
                                                : Icons
                                                    .radio_button_unchecked,
                                            color: isSelected
                                                ? Colors.red.shade600
                                                : Colors.grey.shade400,
                                          )
                                        : null,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        );
      },
    );
  }
}

// ── Bottom sheet: añadir producto al almacén ──────────────────────────────
class _AddProductSheet extends StatefulWidget {
  final int warehouseId;
  const _AddProductSheet({required this.warehouseId});

  @override
  State<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<_AddProductSheet> {
  int? _selectedProductId;
  final _qtyCtrl = TextEditingController(text: '1');
  final _minQtyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  int? _storeId;
  String _query = '';

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _minQtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _submit(BuildContext ctx) {
    if (_selectedProductId == null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Selecciona un producto')),
      );
      return;
    }
    final qty = double.tryParse(_qtyCtrl.text) ?? 1;
    final data = <String, dynamic>{
      'warehouse_id': widget.warehouseId,
      'product_id': _selectedProductId,
      'quantity': qty,
      if (_minQtyCtrl.text.isNotEmpty)
        'min_quantity': double.tryParse(_minQtyCtrl.text),
      if (_priceCtrl.text.isNotEmpty)
        'price_per_unit': double.tryParse(_priceCtrl.text),
      if (_storeId != null) 'store_id': _storeId,
    };
    ctx.read<WarehouseDetailCubit>().addProduct(data);
    Navigator.of(ctx).pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductFormCubit, ProductFormState>(
      listener: (context, state) {
        if (state is ProductFormError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.75,
            maxChildSize: 0.95,
            builder: (_, controller) => SingleChildScrollView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Añadir producto al almacén',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  TextButton.icon(
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('Crear nuevo producto'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.openAuxiliaryRoute('/products/new');
                    },
                  ),
                  const Divider(),
                  const SizedBox(height: 8),

                  if (state is ProductFormLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (state is ProductFormReady) ...[
                    // Product search
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Buscar producto existente',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                    const SizedBox(height: 8),
                    Builder(builder: (_) {
                      final filtered = state.allProducts
                          .where((p) =>
                              _query.isEmpty ||
                              p.name
                                  .toLowerCase()
                                  .contains(_query.toLowerCase()))
                          .toList();
                      if (filtered.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('Sin resultados'),
                        );
                      }
                      return DropdownButtonFormField<int>(
                        value: _selectedProductId,
                        decoration:
                            const InputDecoration(labelText: 'Producto'),
                        items: filtered
                            .map((p) => DropdownMenuItem(
                                value: p.id, child: Text(p.name)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedProductId = v),
                      );
                    }),
                    const SizedBox(height: 14),

                    // Qty
                    TextField(
                      controller: _qtyCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Cantidad inicial',
                        prefixIcon: Icon(Icons.inventory_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Min qty
                    TextField(
                      controller: _minQtyCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Cantidad mínima (alerta, opcional)',
                        prefixIcon: Icon(Icons.warning_amber_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Price
                    TextField(
                      controller: _priceCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Precio por unidad (€, opcional)',
                        prefixIcon: Icon(Icons.euro_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Store
                    BlocProvider.value(
                      value: context.read<StoreCubit>(),
                      child: BlocBuilder<StoreCubit, StoreState>(
                        builder: (context, storeState) {
                          if (storeState is! StoreLoaded) {
                            context.read<StoreCubit>().load();
                            return const SizedBox();
                          }
                          return DropdownButtonFormField<int?>(
                            value: _storeId,
                            decoration: const InputDecoration(
                              labelText: 'Tienda (opcional)',
                              prefixIcon: Icon(Icons.store_outlined),
                            ),
                            items: [
                              const DropdownMenuItem(
                                  value: null, child: Text('Sin tienda')),
                              ...storeState.stores.map((s) => DropdownMenuItem(
                                  value: s.id, child: Text(s.name))),
                            ],
                            onChanged: (v) => setState(() => _storeId = v),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _submit(context),
                        child: const Text('Añadir al almacén'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
