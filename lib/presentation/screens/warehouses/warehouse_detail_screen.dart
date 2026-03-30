import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/filter_params.dart';
import '../../../core/router/app_router.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/category/category_cubit.dart';
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
  late final ScrollController _scrollController;
  int _pageLimit = 20;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initLoad());
  }

  void _initLoad() {
    if (!mounted) return;
    final h = MediaQuery.of(context).size.height;
    _pageLimit = (h / 88).ceil() + 3;
    final authState = context.read<AuthCubit>().state;
    final userId = authState is AuthAuthenticated ? authState.userId : 0;
    context.read<CategoryCubit>().load();
    context.read<WarehouseDetailCubit>().load(
          widget.warehouseId,
          userId: userId,
          params: FilterParams(limit: _pageLimit),
        );
  }

  void _applyFilter(int userId, {int? categoryId, bool clear = false}) {
    setState(() => _selectedCategoryId = clear ? null : categoryId);
    context.read<WarehouseDetailCubit>().load(
          widget.warehouseId,
          userId: userId,
          params: FilterParams(
            limit: _pageLimit,
            categoryId: clear ? null : categoryId,
          ),
        );
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      context.read<WarehouseDetailCubit>().loadMore();
    }
    if (pos.pixels <= 200) {
      context.read<WarehouseDetailCubit>().loadPrevious();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollController.dispose();
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
    final cs = Theme.of(context).colorScheme;
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
                .load(widget.warehouseId,
                    userId: userId,
                    params: FilterParams(
                      limit: _pageLimit,
                      categoryId: _selectedCategoryId,
                    )),
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
                emptyLabel: 'Selecciona productos',
                selectedSingular: 'producto seleccionado',
                selectedPlural: 'productos seleccionados',
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
                            color: cs.onSurfaceVariant),
                        tooltip: 'Seleccionar para borrar',
                        onPressed: () => setState(() => _deleteMode = true),
                      ),
                    ],
                  ],
                ),
              ),

            // ── Search (hidden in delete mode) ─
            if (!_deleteMode) ...[
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
              if (state.isSearching)
                const LinearProgressIndicator(minHeight: 2),
              // ── Category chips ──
              BlocBuilder<CategoryCubit, CategoryState>(
                builder: (context, catState) {
                  if (catState is! CategoryLoaded || catState.categories.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return SizedBox(
                    height: 42,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: const Text('Todas'),
                            selected: _selectedCategoryId == null,
                            onSelected: (_) => _applyFilter(userId, clear: true),
                          ),
                        ),
                        ...catState.categories.map((cat) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: FilterChip(
                                label: Text(cat.name),
                                selected: _selectedCategoryId == cat.id,
                                onSelected: (_) =>
                                    _applyFilter(userId, categoryId: cat.id),
                              ),
                            )),
                      ],
                    ),
                  );
                },
              ),
            ],

            // ── Loading previous indicator ─
            if (state.isLoadingPrevious)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(child: CircularProgressIndicator()),
              ),

            // ── Product list ─
            Expanded(
              child: state.isDeleting
                  ? const LoadingIndicator(message: 'Eliminando…')
                  : state.filtered.isEmpty
                      ? EmptyView(
                          message: _searchCtrl.text.isNotEmpty
                              ? 'Sin resultados para "${_searchCtrl.text}"'
                              : 'No hay productos en este almacén',
                          actionLabel: _searchCtrl.text.isEmpty && state.canEdit
                              ? 'Añadir producto'
                              : null,
                          onAction: _searchCtrl.text.isEmpty && state.canEdit
                              ? _showAddProductSheet
                              : null,
                        )
                      : RefreshIndicator(
                          onRefresh: () {
                            _searchCtrl.clear();
                            return context
                                .read<WarehouseDetailCubit>()
                                .load(widget.warehouseId,
                                    userId: userId,
                                    params: FilterParams(
                                      limit: _pageLimit,
                                      categoryId: _selectedCategoryId,
                                    ));
                          },
                          child: ListView.separated(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
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
                                      ? cs.errorContainer
                                      : Colors.transparent,
                                  child: ProductListTile(
                                    warehouseProduct: item,
                                    isUpdating: isUpdating,
                                    onTap: _deleteMode
                                        ? null
                                        : () => context.openAuxiliaryRoute(
                                              '/products/${item.id}/detail',
                                              extra: {
                                                'warehouseId': widget.warehouseId,
                                              },
                                            ),
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
                                        : () {
                                            if ((item.quantity - 1) < 0) return;
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
                                    trailing: _deleteMode
                                        ? Icon(
                                            isSelected
                                                ? Icons.check_circle
                                                : Icons
                                                    .radio_button_unchecked,
                                            color: isSelected
                                                ? cs.error
                                                : cs.onSurfaceVariant,
                                          )
                                        : null,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
            if (state.isLoadingMore)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: CircularProgressIndicator()),
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
  final _obsCtrl = TextEditingController();
  int? _storeId;
  String _query = '';

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _minQtyCtrl.dispose();
    _priceCtrl.dispose();
    _obsCtrl.dispose();
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
      if (_obsCtrl.text.trim().isNotEmpty) 'observations': _obsCtrl.text.trim(),
    };
    ctx.read<WarehouseDetailCubit>().addProduct(data);
    Navigator.of(ctx).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
                        color: cs.outlineVariant,
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
                    const SizedBox(height: 10),

                    // Observations
                    TextField(
                      controller: _obsCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Observaciones (opcional)',
                        prefixIcon: Icon(Icons.notes_outlined),
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

