import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/notification/notification_cubit.dart';
import '../../cubits/product_form/product_form_cubit.dart';
import '../../cubits/shopping_list/shopping_list_cubit.dart';
import '../../cubits/stock_change/stock_change_cubit.dart';
import '../../cubits/warehouse/warehouse_cubit.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_indicator.dart';

const _purple = Color(0xFF3C096C);
const _mint = Color(0xFFD8F3DC);
const _accentGreen = Color(0xFF52B788);
const _white = Color(0xFFFFFFFF);

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  // 0 = Tiendas (default), 1 = Almacenes
  int _tabIndex = 0;

  //  Tiendas tab state 
  int? _selectedStoreFilter; // null = all stores shown (-1 = "Sin tienda")
  final Map<int, int> _stPlanned = {};
  final Map<int, int> _stBuyQty = {};
  final Set<int> _stChecked = {};

  //  Almacenes tab state 
  int? _selectedWarehouseId;
  final Map<int, int> _whPlanned = {};
  final Map<int, int> _whBuyQty = {};
  final Set<int> _whChecked = {};

  //  Active-tab getters 
  Map<int, int> get _planned => _tabIndex == 0 ? _stPlanned : _whPlanned;
  Map<int, int> get _buyQtyMap => _tabIndex == 0 ? _stBuyQty : _whBuyQty;
  Set<int> get _checkedSet => _tabIndex == 0 ? _stChecked : _whChecked;

  @override
  void initState() {
    super.initState();
    context.read<WarehouseCubit>().load();
    context.read<ShoppingListCubit>().loadAll();
  }

  void _onTabChanged(int index) {
    if (_tabIndex == index) return;
    setState(() => _tabIndex = index);
    if (index == 0) {
      context.read<ShoppingListCubit>().loadAll();
    }
    // index 1: warehouse selector triggers load() when user picks one
  }

  //  Qty helpers 
  int _getPlanned(dynamic item) =>
      _planned[item.id as int] ??
      (item.suggestedQty as double).toInt().clamp(1, 999);

  int _getBuyNow(dynamic item) =>
      _buyQtyMap[item.id as int] ?? _getPlanned(item);

  void _setPlanned(int itemId, int delta, {required int current}) {
    setState(() {
      final next = (current + delta).clamp(1, 999);
      _planned[itemId] = next;
      if ((_buyQtyMap[itemId] ?? next) > next) _buyQtyMap[itemId] = next;
    });
  }

  void _setBuyNow(int itemId, int delta,
      {required int current, required int max}) {
    setState(() => _buyQtyMap[itemId] = (current + delta).clamp(1, max));
  }

  //  Warehouse name helper (client-side fallback when API omits it) 
  String? _warehouseNameFor(int warehouseId) {
    final state = context.read<WarehouseCubit>().state;
    if (state is WarehouseLoaded) {
      try {
        return state.warehouses.firstWhere((w) => w.id == warehouseId).name;
      } catch (_) {}
    }
    return null;
  }

  //  Buy logic 
  Future<void> _buy(List items) async {
    final toProcess = List.of(_checkedSet);
    for (final id in toProcess) {
      final idx = items.indexWhere((i) => i.id == id);
      if (idx < 0) continue;
      final item = items[idx];
      final planned = _getPlanned(item);
      final buyNow = _getBuyNow(item);

      await context.read<StockChangeCubit>().create(
            warehouseId: item.warehouseId,
            productId: item.productId,
            changeQuantity: buyNow,
            changeType: 'inbound',
            reason: 'Compra desde lista de la compra',
          );

      if (buyNow >= planned) {
        await context
            .read<ShoppingListCubit>()
            .removeItem(id, item.warehouseId as int);
      } else {
        await context.read<ShoppingListCubit>().updateItem(
              id,
              (planned - buyNow).toDouble(),
              item.warehouseId as int,
            );
      }
    }

    setState(() {
      for (final id in toProcess) {
        _checkedSet.remove(id);
        _buyQtyMap.remove(id);
        _planned.remove(id);
      }
    });

    if (context.mounted) context.read<NotificationCubit>().load();
  }

  //  Build 
  @override
  Widget build(BuildContext context) {
    // Re-render item cards when warehouse names become available
    return BlocListener<WarehouseCubit, WarehouseState>(
      listenWhen: (prev, curr) =>
          curr is WarehouseLoaded && prev is! WarehouseLoaded,
      listener: (_, __) => setState(() {}),
      child: Column(
        children: [
          _SlidingTabHeader(
            selectedIndex: _tabIndex,
            tabs: const ['Tiendas', 'Almacenes'],
            onTabChanged: _onTabChanged,
          ),
          Expanded(
            child: IndexedStack(
              index: _tabIndex,
              children: [
                _buildTiendasTab(),
                _buildAlmacenesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //  Tiendas tab 
  Widget _buildTiendasTab() {
    return BlocConsumer<ShoppingListCubit, ShoppingListState>(
      listenWhen: (_, curr) => curr is ShoppingListError,
      listener: (context, state) {
        if (state is ShoppingListError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: Colors.red.shade700,
          ));
        }
      },
      buildWhen: (prev, curr) =>
          !(curr is ShoppingListError && prev is ShoppingListLoaded),
      builder: (context, state) {
        // Derive data for the toolbar (always present)
        final List items =
            state is ShoppingListLoaded ? state.items : const [];
        final storeMap = <int?, String?>{};
        for (final item in items) {
          storeMap[item.storeId] = item.storeName;
        }
        final storeIds = storeMap.keys.whereType<int>().toList()..sort();
        final hasNoStore = storeMap.containsKey(null);
        final filteredItems = items.isEmpty
            ? items
            : (_selectedStoreFilter == null
                ? items
                : (_selectedStoreFilter == -1
                    ? items.where((i) => i.storeId == null).toList()
                    : items
                        .where((i) => i.storeId == _selectedStoreFilter)
                        .toList()));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //  Store filter chips + action buttons (always visible) 
            Container(
              color: _white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _StoreChip(
                            label: 'Todas',
                            selected: _selectedStoreFilter == null,
                            onTap: () =>
                                setState(() => _selectedStoreFilter = null),
                          ),
                          if (hasNoStore)
                            _StoreChip(
                              label: 'Sin tienda',
                              selected: _selectedStoreFilter == -1,
                              onTap: () =>
                                  setState(() => _selectedStoreFilter = -1),
                            ),
                          for (final sid in storeIds)
                            _StoreChip(
                              label: storeMap[sid] ?? 'Tienda $sid',
                              selected: _selectedStoreFilter == sid,
                              onTap: () =>
                                  setState(() => _selectedStoreFilter = sid),
                            ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.auto_awesome, color: _accentGreen),
                    tooltip: 'Generar automáticamente',
                    onPressed: () => _showGenerateDialog(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: _purple),
                    tooltip: 'Añadir producto',
                    onPressed: () =>
                        _showAddDialogWithWarehouseSelection(context),
                  ),
                ],
              ),
            ),

            //  Content area 
            Expanded(
              child: () {
                if (state is ShoppingListLoading ||
                    state is ShoppingListInitial) {
                  return const LoadingIndicator();
                }
                if (state is ShoppingListError) {
                  return ErrorView(
                    message: state.message,
                    onRetry: () =>
                        context.read<ShoppingListCubit>().loadAll(),
                  );
                }
                if (filteredItems.isEmpty) {
                  return EmptyView(
                    message: items.isEmpty
                        ? 'No hay productos en ninguna lista de compra.\nPulsa ✨ para generarla automáticamente.'
                        : 'No hay productos en esta tienda',
                    icon: Icons.store_outlined,
                  );
                }
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ...filteredItems.map(
                        (item) => _buildItemCard(item, showWarehouse: true)),
                    const SizedBox(height: 12),
                    _buildBuyButton(filteredItems),
                  ],
                );
              }(),
            ),
          ],
        );
      },
    );
  }

  //  Almacenes tab 
  Widget _buildAlmacenesTab() {
    return Column(
      children: [
        Container(
          color: _white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: BlocBuilder<WarehouseCubit, WarehouseState>(
            builder: (context, state) {
              if (state is! WarehouseLoaded) return const LoadingIndicator();
              return Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      isExpanded: true,
                      value: _selectedWarehouseId,
                      decoration: InputDecoration(
                        labelText: 'Almacén',
                        prefixIcon: const Icon(Icons.warehouse_outlined,
                            color: _purple),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: _mint,
                        labelStyle: const TextStyle(color: _purple),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                      items: state.warehouses
                          .map((w) => DropdownMenuItem(
                              value: w.id, child: Text(w.name)))
                          .toList(),
                      onChanged: (id) {
                        setState(() {
                          _selectedWarehouseId = id;
                          _whPlanned.clear();
                          _whBuyQty.clear();
                          _whChecked.clear();
                        });
                        if (id != null) {
                          context.read<ShoppingListCubit>().load(id);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Generate all warehouses (always visible)
                  IconButton(
                    icon: const Icon(Icons.auto_awesome_mosaic,
                        color: _accentGreen),
                    tooltip: 'Generar todos los almacenes',
                    onPressed: () async {
                      await context
                          .read<ShoppingListCubit>()
                          .generateAll();
                      if (_selectedWarehouseId != null &&
                          context.mounted) {
                        context
                            .read<ShoppingListCubit>()
                            .load(_selectedWarehouseId!);
                      }
                    },
                  ),
                  if (_selectedWarehouseId != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline,
                          color: _purple),
                      tooltip: 'Añadir producto',
                      onPressed: () => _showAddDialog(context),
                    ),
                    IconButton(
                      icon: const Icon(Icons.auto_awesome,
                          color: _accentGreen),
                      tooltip: 'Generar automáticamente',
                      onPressed: () => context
                          .read<ShoppingListCubit>()
                          .generate(_selectedWarehouseId!),
                    ),
                    IconButton(
                      icon:
                          Icon(Icons.delete_sweep, color: Colors.red.shade400),
                      tooltip: 'Limpiar lista',
                      onPressed: () async {
                        final confirm = await showConfirmDialog(
                          context,
                          title: 'Limpiar lista',
                          message:
                              '¿Eliminar todos los elementos de la lista de compra?',
                          confirmLabel: 'Limpiar',
                          isDangerous: true,
                        );
                        if (confirm == true && context.mounted) {
                          setState(() {
                            _whPlanned.clear();
                            _whBuyQty.clear();
                            _whChecked.clear();
                          });
                          context
                              .read<ShoppingListCubit>()
                              .clearList(_selectedWarehouseId!);
                        }
                      },
                    ),
                  ],
                ],
              );
            },
          ),
        ),
        Expanded(
          child: _selectedWarehouseId == null
              ? const EmptyView(
                  message:
                      'Selecciona un almacén para ver su lista de compra',
                  icon: Icons.shopping_cart_outlined,
                )
              : BlocConsumer<ShoppingListCubit, ShoppingListState>(
                  listenWhen: (_, curr) => curr is ShoppingListError,
                  listener: (context, state) {
                    if (state is ShoppingListError) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.red.shade700,
                      ));
                    }
                  },
                  buildWhen: (prev, curr) =>
                      !(curr is ShoppingListError &&
                          prev is ShoppingListLoaded),
                  builder: (context, state) {
                    if (state is ShoppingListLoading ||
                        state is ShoppingListInitial) {
                      return const LoadingIndicator();
                    }
                    if (state is ShoppingListError) {
                      return ErrorView(
                        message: state.message,
                        onRetry: () => context
                            .read<ShoppingListCubit>()
                            .load(_selectedWarehouseId!),
                      );
                    }
                    if (state is ShoppingListLoaded && state.items.isEmpty) {
                      return EmptyView(
                        message: 'La lista de compra está vacía',
                        actionLabel: 'Generar automáticamente',
                        onAction: () => context
                            .read<ShoppingListCubit>()
                            .generate(_selectedWarehouseId!),
                      );
                    }
                    if (state is ShoppingListLoaded) {
                      final items = state.items;
                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          ...items.map((item) =>
                              _buildItemCard(item, showWarehouse: false)),
                          const SizedBox(height: 12),
                          _buildBuyButton(items),
                        ],
                      );
                    }
                    return const SizedBox();
                  },
                ),
        ),
      ],
    );
  }

  //  Shared item card 
  Widget _buildItemCard(dynamic item, {required bool showWarehouse}) {
    final isChecked = _checkedSet.contains(item.id as int);
    final planned = _getPlanned(item);
    final buyNow = _getBuyNow(item);
    final alertGap = item.alertGap as double;
    final coverMin = alertGap <= 0 || buyNow >= alertGap;
    final buyAll = buyNow >= planned;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isChecked
            ? (buyAll ? Colors.green.shade50 : Colors.orange.shade50)
            : _white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Checkbox(
            value: isChecked,
            activeColor: _accentGreen,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            onChanged: (v) => setState(() {
              if (v == true) {
                _checkedSet.add(item.id as int);
                _buyQtyMap[item.id as int] ??= planned;
              } else {
                _checkedSet.remove(item.id as int);
                _buyQtyMap.remove(item.id as int);
              }
            }),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product?.name ?? 'Producto ${item.productId}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isChecked ? Colors.grey.shade600 : _purple,
                      decoration: (isChecked && buyAll)
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (showWarehouse) ...[
                    const SizedBox(height: 2),
                    Text(
                      (item.warehouseName as String?) ??
                          _warehouseNameFor(item.warehouseId as int) ??
                          'Almacén ${item.warehouseId}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11,
                          color: _purple.withValues(alpha: 0.55),
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                  if (alertGap > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Mínimo sugerido: ${alertGap.toStringAsFixed(0)}'
                      '${item.product?.defaultUnit != null ? ' ${item.product!.defaultUnit}' : ''}',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                  if (isChecked) ...[
                    const SizedBox(height: 2),
                    Text(
                      buyAll
                          ? (coverMin
                              ? ' Cubre el mínimo · se eliminará de la lista'
                              : ' Compra completa · se eliminará de la lista')
                          : (coverMin
                              ? 'Compra parcial · quedarán ${planned - buyNow} pendientes (cubre el mínimo)'
                              : 'Compra parcial · quedarán ${planned - buyNow} pendientes'),
                      style: TextStyle(
                          fontSize: 11,
                          color: buyAll
                              ? Colors.green.shade600
                              : Colors.orange.shade700),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Planned qty
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('A comprar',
                  style:
                      TextStyle(fontSize: 10, color: Colors.grey.shade500)),
              const SizedBox(height: 2),
              _QtySelector(
                qty: planned,
                onDecrement: () =>
                    _setPlanned(item.id as int, -1, current: planned),
                onIncrement: () =>
                    _setPlanned(item.id as int, 1, current: planned),
              ),
            ],
          ),
          // Buy-now qty (only when checked)
          if (isChecked) ...[
            const SizedBox(width: 6),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Ahora',
                    style: TextStyle(fontSize: 10, color: _accentGreen)),
                const SizedBox(height: 2),
                _QtySelector(
                  qty: buyNow,
                  onDecrement: () => _setBuyNow(item.id as int, -1,
                      current: buyNow, max: planned),
                  onIncrement: () => _setBuyNow(item.id as int, 1,
                      current: buyNow, max: planned),
                ),
              ],
            ),
          ],
          const SizedBox(width: 4),
          // Delete
          IconButton(
            icon: Icon(Icons.delete_outline,
                color: Colors.red.shade300, size: 20),
            onPressed: () async {
              final confirm = await showConfirmDialog(
                context,
                title: 'Eliminar producto',
                message:
                    '¿Eliminar "${item.product?.name ?? 'este producto'}" de la lista?',
                confirmLabel: 'Eliminar',
                isDangerous: true,
              );
              if (confirm != true || !context.mounted) return;
              setState(() {
                _checkedSet.remove(item.id as int);
                _planned.remove(item.id as int);
                _buyQtyMap.remove(item.id as int);
              });
              context
                  .read<ShoppingListCubit>()
                  .removeItem(item.id as int, item.warehouseId as int);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBuyButton(List items) {
    final count = _checkedSet.length;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentGreen,
          foregroundColor: _white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        icon: const Icon(Icons.shopping_cart_checkout),
        label: Text(count == 0
            ? 'Marca productos para comprar'
            : 'Comprar ($count marcado${count == 1 ? '' : 's'})'),
        onPressed: count == 0 ? null : () => _buy(items),
      ),
    );
  }

  //  Generate dialog – Tiendas tab 
  Future<void> _showGenerateDialog(BuildContext outerCtx) async {
    final warehouseState = outerCtx.read<WarehouseCubit>().state;
    if (warehouseState is! WarehouseLoaded ||
        warehouseState.warehouses.isEmpty) {
      ScaffoldMessenger.of(outerCtx).showSnackBar(const SnackBar(
          content: Text('No hay almacenes disponibles'),
          duration: Duration(seconds: 2)));
      return;
    }

    int? selectedWarehouseId;

    await showDialog<void>(
      context: outerCtx,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => Dialog(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20))),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Generar lista automáticamente',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _purple),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Selecciona el almacén para generar la lista basándose en el stock bajo.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  value: selectedWarehouseId,
                  decoration:
                      _fieldDeco('Almacén', Icons.warehouse_outlined),
                  items: [
                    const DropdownMenuItem<int>(
                      value: -1,
                      child: Row(
                        children: [
                          Icon(Icons.all_inclusive, color: _accentGreen, size: 18),
                          SizedBox(width: 8),
                          Text('Todos los almacenes'),
                        ],
                      ),
                    ),
                    ...warehouseState.warehouses
                        .map((w) => DropdownMenuItem<int>(
                            value: w.id, child: Text(w.name)))
                        .toList(),
                  ],
                  onChanged: (v) =>
                      setInner(() => selectedWarehouseId = v),
                ),
                const SizedBox(height: 24),
                _dialogButtons(
                  ctx: ctx,
                  outerCtx: outerCtx,
                  enabled: selectedWarehouseId != null,
                  confirmLabel: 'Generar',
                  onConfirm: () async {
                    if (selectedWarehouseId == -1) {
                      await outerCtx
                          .read<ShoppingListCubit>()
                          .generateAll();
                    } else {
                      await outerCtx
                          .read<ShoppingListCubit>()
                          .generate(selectedWarehouseId!);
                      if (outerCtx.mounted) {
                        await outerCtx
                            .read<ShoppingListCubit>()
                            .loadAll();
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  //  Add dialog  Almacenes tab 
  Future<void> _showAddDialog(BuildContext outerCtx) async {
    outerCtx.read<ProductFormCubit>().loadForPicker();
    final shoppingState = outerCtx.read<ShoppingListCubit>().state;
    final alreadyInList = shoppingState is ShoppingListLoaded
        ? shoppingState.items.map((i) => i.productId).toSet()
        : <int>{};

    int? selectedProductId;
    int qty = 1;

    await showDialog<void>(
      context: outerCtx,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => BlocBuilder<ProductFormCubit, ProductFormState>(
          builder: (_, formState) {
            final products = formState is ProductFormReady
                ? formState.allProducts
                    .where((p) => !alreadyInList.contains(p.id))
                    .toList()
                : <dynamic>[];
            return Dialog(
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20))),
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Añadir producto',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _purple)),
                    const SizedBox(height: 20),
                    if (formState is ProductFormLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (products.isEmpty)
                      const Text('Todos los productos ya están en la lista.',
                          style: TextStyle(color: Colors.grey))
                    else
                      DropdownButtonFormField<int>(
                        isExpanded: true,
                        value: selectedProductId,
                        decoration: _fieldDeco(
                            'Producto', Icons.inventory_2_outlined),
                        items: products
                            .map((p) => DropdownMenuItem<int>(
                                value: p.id as int,
                                child: Text(p.name as String)))
                            .toList(),
                        onChanged: (v) =>
                            setInner(() => selectedProductId = v),
                      ),
                    const SizedBox(height: 16),
                    _qtyRow(qty, setInner),
                    const SizedBox(height: 24),
                    _dialogButtons(
                      ctx: ctx,
                      outerCtx: outerCtx,
                      enabled: selectedProductId != null,
                      onConfirm: () => outerCtx
                          .read<ShoppingListCubit>()
                          .addItem(_selectedWarehouseId!, selectedProductId!,
                              qty.toDouble()),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  //  Add dialog with warehouse selection  Tiendas tab 
  Future<void> _showAddDialogWithWarehouseSelection(
      BuildContext outerCtx) async {
    final warehouseState = outerCtx.read<WarehouseCubit>().state;
    if (warehouseState is! WarehouseLoaded ||
        warehouseState.warehouses.isEmpty) {
      ScaffoldMessenger.of(outerCtx).showSnackBar(const SnackBar(
          content: Text('No hay almacenes disponibles'),
          duration: Duration(seconds: 2)));
      return;
    }

    outerCtx.read<ProductFormCubit>().loadForPicker();
    final shoppingState = outerCtx.read<ShoppingListCubit>().state;
    final alreadyInList = shoppingState is ShoppingListLoaded
        ? shoppingState.items.map((i) => i.productId).toSet()
        : <int>{};

    int? selectedWarehouseId;
    int? selectedProductId;
    int qty = 1;

    await showDialog<void>(
      context: outerCtx,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => BlocBuilder<ProductFormCubit, ProductFormState>(
          builder: (_, formState) {
            final products = formState is ProductFormReady
                ? formState.allProducts
                    .where((p) => !alreadyInList.contains(p.id))
                    .toList()
                : <dynamic>[];
            return Dialog(
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20))),
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Añadir producto',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _purple)),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<int>(
                      isExpanded: true,
                      value: selectedWarehouseId,
                      decoration:
                          _fieldDeco('Almacén', Icons.warehouse_outlined),
                      items: warehouseState.warehouses
                          .map((w) => DropdownMenuItem<int>(
                              value: w.id, child: Text(w.name)))
                          .toList(),
                      onChanged: (v) =>
                          setInner(() => selectedWarehouseId = v),
                    ),
                    const SizedBox(height: 16),
                    if (formState is ProductFormLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (products.isEmpty)
                      const Text('Todos los productos ya están en la lista.',
                          style: TextStyle(color: Colors.grey))
                    else
                      DropdownButtonFormField<int>(
                        isExpanded: true,
                        value: selectedProductId,
                        decoration: _fieldDeco(
                            'Producto', Icons.inventory_2_outlined),
                        items: products
                            .map((p) => DropdownMenuItem<int>(
                                value: p.id as int,
                                child: Text(p.name as String)))
                            .toList(),
                        onChanged: (v) =>
                            setInner(() => selectedProductId = v),
                      ),
                    const SizedBox(height: 16),
                    _qtyRow(qty, setInner),
                    const SizedBox(height: 24),
                    _dialogButtons(
                      ctx: ctx,
                      outerCtx: outerCtx,
                      enabled: selectedWarehouseId != null &&
                          selectedProductId != null,
                      onConfirm: () => outerCtx
                          .read<ShoppingListCubit>()
                          .addItem(selectedWarehouseId!, selectedProductId!,
                              qty.toDouble()),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  //  Dialog helpers 
  InputDecoration _fieldDeco(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _purple),
        filled: true,
        fillColor: _mint,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _purple, width: 1.5)),
        labelStyle: const TextStyle(color: _purple),
      );

  Widget _qtyRow(int qty, StateSetter setInner) => Row(
        children: [
          const Text('Cantidad:',
              style: TextStyle(
                  color: _purple, fontWeight: FontWeight.w600)),
          const Spacer(),
          _QtySelector(
            qty: qty,
            onDecrement: () =>
                setInner(() => qty = (qty - 1).clamp(1, 999)),
            onIncrement: () =>
                setInner(() => qty = (qty + 1).clamp(1, 999)),
          ),
        ],
      );

  Widget _dialogButtons({
    required BuildContext ctx,
    required BuildContext outerCtx,
    required bool enabled,
    required VoidCallback onConfirm,
    String confirmLabel = 'Añadir',
  }) =>
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: _purple,
                side: const BorderSide(color: _purple),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentGreen,
                foregroundColor: _white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: enabled
                  ? () {
                      Navigator.of(ctx).pop();
                      if (!outerCtx.mounted) return;
                      onConfirm();
                    }
                  : null,
              child: Text(confirmLabel),
            ),
          ),
        ],
      );
}

//  Sliding tab header 
class _SlidingTabHeader extends StatelessWidget {
  final int selectedIndex;
  final List<String> tabs;
  final ValueChanged<int> onTabChanged;

  const _SlidingTabHeader({
    required this.selectedIndex,
    required this.tabs,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _purple,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabCount = tabs.length;
          final pillWidth = (constraints.maxWidth - 32) / tabCount;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: List.generate(tabCount, (i) {
                  final isSelected = selectedIndex == i;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onTabChanged(i),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          tabs[i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: isSelected
                                ? _white
                                : _white.withValues(alpha: 0.55),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              SizedBox(
                height: 3,
                child: Stack(
                  children: [
                    Container(color: _white.withValues(alpha: 0.15)),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      left: selectedIndex * pillWidth,
                      width: pillWidth,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _accentGreen,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

//  Store filter chip 
class _StoreChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StoreChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? _purple : _mint,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected
                  ? _purple
                  : _accentGreen.withValues(alpha: 0.4),
              width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? _white : _purple,
          ),
        ),
      ),
    );
  }
}

//  Quantity selector 
class _QtySelector extends StatelessWidget {
  final int qty;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _QtySelector({
    required this.qty,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _mint,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyBtn(icon: Icons.remove, onTap: onDecrement),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '$qty',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _purple),
            ),
          ),
          _QtyBtn(icon: Icons.add, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: _accentGreen,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: _white, size: 16),
      ),
    );
  }
}