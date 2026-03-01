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
  int? _selectedWarehouseId;
  // Planned qty to buy per item id (always visible, user-editable)
  final Map<int, int> _plannedQty = {};
  // Qty being purchased right now per item id (shown when checked, <= plannedQty)
  final Map<int, int> _buyQty = {};
  // Checked items
  final Set<int> _checked = {};

  @override
  void initState() {
    super.initState();
    context.read<WarehouseCubit>().load();
  }

  int _getPlanned(dynamic item) =>
      _plannedQty[item.id as int] ??
      (item.suggestedQty as double).toInt().clamp(1, 999);

  int _getBuyNow(dynamic item) =>
      _buyQty[item.id as int] ?? _getPlanned(item);

  void _setPlanned(int itemId, int delta, {required int current}) {
    setState(() {
      final next = (current + delta).clamp(1, 999);
      _plannedQty[itemId] = next;
      // cap buyQty so it never exceeds planned
      if ((_buyQty[itemId] ?? next) > next) {
        _buyQty[itemId] = next;
      }
    });
  }

  void _setBuyNow(int itemId, int delta,
      {required int current, required int max}) {
    setState(() {
      _buyQty[itemId] = (current + delta).clamp(1, max);
    });
  }

  // Buy logic:
  //  - buyNow >= plannedQty  → register inbound + remove from list
  //  - buyNow <  plannedQty  → register inbound + keep remaining in list
  Future<void> _buy(List items) async {
    final toProcess = List.of(_checked);

    for (final id in toProcess) {
      final idx = items.indexWhere((i) => i.id == id);
      if (idx < 0) continue;
      final item = items[idx];
      final planned = _getPlanned(item);
      final buyNow = _getBuyNow(item);

      // 1. Register the stock inbound
      await context.read<StockChangeCubit>().create(
            warehouseId: item.warehouseId,
            productId: item.productId,
            changeQuantity: buyNow,
            changeType: 'inbound',
            reason: 'Compra desde lista de la compra',
          );

      // 2. Remove or keep remaining in list
      if (buyNow >= planned) {
        await context
            .read<ShoppingListCubit>()
            .removeItem(id, _selectedWarehouseId!);
      } else {
        final remaining = planned - buyNow;
        await context
            .read<ShoppingListCubit>()
            .updateItem(id, remaining.toDouble(), _selectedWarehouseId!);
      }
    }

    setState(() {
      for (final id in toProcess) {
        _checked.remove(id);
        _buyQty.remove(id);
        // Clear so partial-buy items re-read the updated suggestedQty from server
        _plannedQty.remove(id);
      }
    });

    // Refresh notification badge — buying stock may have resolved low-stock alerts
    // or outbound changes elsewhere may have triggered new ones
    if (context.mounted) {
      context.read<NotificationCubit>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Warehouse selector ──────────────────────────────────────────
        Container(
          color: _white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: BlocBuilder<WarehouseCubit, WarehouseState>(
            builder: (context, state) {
              if (state is! WarehouseLoaded) {
                return const LoadingIndicator();
              }
              return Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int?>(
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
                          _plannedQty.clear();
                          _buyQty.clear();
                          _checked.clear();
                        });
                        if (id != null) {
                          context.read<ShoppingListCubit>().load(id);
                        }
                      },
                    ),
                  ),
                  if (_selectedWarehouseId != null) ...[
                    const SizedBox(width: 8),
                    // Manual add
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline,
                          color: _purple),
                      tooltip: 'Añadir producto',
                      onPressed: () => _showAddDialog(context),
                    ),
                    // Auto-generate
                    IconButton(
                      icon: const Icon(Icons.auto_awesome, color: _accentGreen),
                      tooltip: 'Generar automáticamente',
                      onPressed: () => context
                          .read<ShoppingListCubit>()
                          .generate(_selectedWarehouseId!),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_sweep,
                          color: Colors.red.shade400),
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
                            _plannedQty.clear();
                            _buyQty.clear();
                            _checked.clear();
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

        // ── List ────────────────────────────────────────────────────────
        Expanded(
          child: _selectedWarehouseId == null
              ? const EmptyView(
                  message: 'Selecciona un almacén para ver su lista de compra',
                  icon: Icons.shopping_cart_outlined,
                )
              : BlocConsumer<ShoppingListCubit, ShoppingListState>(
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
                          // Items
                          ...items.map((item) {
                            final isChecked = _checked.contains(item.id);
                            final planned = _getPlanned(item);
                            final buyNow = _getBuyNow(item);
                            final alertGap = item.alertGap;
                            final coverMin = alertGap <= 0 || buyNow >= alertGap;
                            final buyAll = buyNow >= planned;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: isChecked
                                    ? (buyAll
                                        ? Colors.green.shade50
                                        : Colors.orange.shade50)
                                    : _white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.04),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2)),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Checkbox
                                  Checkbox(
                                    value: isChecked,
                                    activeColor: _accentGreen,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(4)),
                                    onChanged: (v) => setState(() {
                                      if (v == true) {
                                        _checked.add(item.id);
                                        // default buyNow = planned
                                        _buyQty[item.id] ??= planned;
                                      } else {
                                        _checked.remove(item.id);
                                        _buyQty.remove(item.id);
                                      }
                                    }),
                                  ),

                                  // Name + info
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.product?.name ??
                                                'Producto ${item.productId}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: isChecked
                                                  ? Colors.grey.shade600
                                                  : _purple,
                                              decoration: (isChecked && buyAll)
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                            ),
                                          ),
                                          if (item.alertGap > 0) ...[  
                                            const SizedBox(height: 2),
                                            Text(
                                              'Mínimo sugerido: ${item.alertGap.toStringAsFixed(0)}'
                                              '${item.product?.defaultUnit != null ? ' ${item.product!.defaultUnit}' : ''}',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade500),
                                            ),
                                          ],
                                          if (isChecked) ...[  
                                            const SizedBox(height: 2),
                                            Text(
                                              buyAll
                                                  ? (coverMin
                                                      ? '✓ Cubre el mínimo · se eliminará de la lista'
                                                      : '✓ Compra completa · se eliminará de la lista')
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

                                  // Planned qty (always visible)
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'A comprar',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey.shade500),
                                      ),
                                      const SizedBox(height: 2),
                                      _QtySelector(
                                        qty: planned,
                                        onDecrement: () => _setPlanned(
                                            item.id, -1,
                                            current: planned),
                                        onIncrement: () => _setPlanned(
                                            item.id, 1,
                                            current: planned),
                                      ),
                                    ],
                                  ),
                                  // Buy-now qty (only when checked)
                                  if (isChecked) ...[  
                                    const SizedBox(width: 6),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Ahora',
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: _accentGreen),
                                        ),
                                        const SizedBox(height: 2),
                                        _QtySelector(
                                          qty: buyNow,
                                          onDecrement: () => _setBuyNow(
                                              item.id, -1,
                                              current: buyNow,
                                              max: planned),
                                          onIncrement: () => _setBuyNow(
                                              item.id, 1,
                                              current: buyNow,
                                              max: planned),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(width: 4),

                                  // Delete
                                  IconButton(
                                    icon: Icon(Icons.delete_outline,
                                        color: Colors.red.shade300,
                                        size: 20),
                                    onPressed: () {
                                      setState(() {
                                        _checked.remove(item.id);
                                        _plannedQty.remove(item.id);
                                        _buyQty.remove(item.id);
                                      });
                                      context
                                          .read<ShoppingListCubit>()
                                          .removeItem(
                                              item.id,
                                              _selectedWarehouseId!);
                                    },
                                  ),
                                ],
                              ),
                            );
                          }),

                          const SizedBox(height: 12),

                          // Comprar button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accentGreen,
                                foregroundColor: _white,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(14)),
                                elevation: 0,
                                textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700),
                              ),
                              icon: const Icon(
                                  Icons.shopping_cart_checkout),
                              label: Text(_checked.isEmpty
                                  ? 'Marca productos para comprar'
                                  : 'Comprar (${_checked.length} marcado${_checked.length == 1 ? '' : 's'})'),
                              onPressed: _checked.isEmpty
                                  ? null
                                  : () => _buy(items),
                            ),
                          ),
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

  // ── Manual add dialog ────────────────────────────────────────────────────
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
        builder: (ctx, setInnerState) {
          return BlocBuilder<ProductFormCubit, ProductFormState>(
            builder: (bCtx, formState) {
              final products = formState is ProductFormReady
                  ? formState.allProducts
                      .where((p) => !alreadyInList.contains(p.id))
                      .toList()
                  : <dynamic>[];

              return Dialog(
                shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.all(Radius.circular(20))),
                insetPadding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 40),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Añadir producto',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _purple),
                      ),
                      const SizedBox(height: 20),
                      if (formState is ProductFormLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (products.isEmpty)
                        const Text(
                          'Todos los productos ya están en la lista.',
                          style: TextStyle(color: Colors.grey),
                        )
                      else
                        DropdownButtonFormField<int>(
                          value: selectedProductId,
                          decoration: InputDecoration(
                            labelText: 'Producto',
                            prefixIcon: const Icon(
                                Icons.inventory_2_outlined,
                                color: _purple),
                            filled: true,
                            fillColor: _mint,
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: _purple, width: 1.5)),
                            labelStyle:
                                const TextStyle(color: _purple),
                          ),
                          items: products
                              .map((p) => DropdownMenuItem<int>(
                                  value: p.id as int,
                                  child: Text(p.name as String)))
                              .toList(),
                          onChanged: (v) => setInnerState(
                              () => selectedProductId = v),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text('Cantidad:',
                              style: TextStyle(
                                  color: _purple,
                                  fontWeight: FontWeight.w600)),
                          const Spacer(),
                          _QtySelector(
                            qty: qty,
                            onDecrement: () => setInnerState(
                                () =>
                                    qty = (qty - 1).clamp(1, 999)),
                            onIncrement: () => setInnerState(
                                () =>
                                    qty = (qty + 1).clamp(1, 999)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _purple,
                                side: const BorderSide(
                                    color: _purple),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12)),
                                padding:
                                    const EdgeInsets.symmetric(
                                        vertical: 14),
                              ),
                              onPressed: () =>
                                  Navigator.of(ctx).pop(),
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
                                    borderRadius:
                                        BorderRadius.circular(12)),
                                padding:
                                    const EdgeInsets.symmetric(
                                        vertical: 14),
                              ),
                              onPressed: selectedProductId == null
                                  ? null
                                  : () {
                                      Navigator.of(ctx).pop();
                                      if (!outerCtx.mounted) return;
                                      outerCtx
                                          .read<ShoppingListCubit>()
                                          .addItem(
                                              _selectedWarehouseId!,
                                              selectedProductId!,
                                              qty.toDouble());
                                    },
                              child: const Text('Añadir'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Quantity selector ─────────────────────────────────────────────────────────
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
