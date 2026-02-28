import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/shopping_list/shopping_list_cubit.dart';
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
  // Local quantity overrides per item id
  final Map<int, int> _quantities = {};
  // Checked items
  final Set<int> _checked = {};

  @override
  void initState() {
    super.initState();
    context.read<WarehouseCubit>().load();
  }

  void _setQty(int itemId, int delta) {
    setState(() {
      final current = _quantities[itemId] ?? 1;
      final next = (current + delta).clamp(1, 999);
      _quantities[itemId] = next;
    });
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
                          _quantities.clear();
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
                          _quantities.clear();
                          _checked.clear();
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
              : BlocBuilder<ShoppingListCubit, ShoppingListState>(
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
                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Items
                          ...state.items.map((item) {
                            final qty = _quantities[item.id] ??
                                (item.suggestedQty.toInt().clamp(1, 999));
                            final isChecked = _checked.contains(item.id);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: isChecked
                                    ? Colors.green.shade50
                                    : _white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
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
                                        borderRadius: BorderRadius.circular(4)),
                                    onChanged: (v) => setState(() {
                                      if (v == true) {
                                        _checked.add(item.id);
                                      } else {
                                        _checked.remove(item.id);
                                      }
                                    }),
                                  ),

                                  // Name + suggested qty
                                  Expanded(
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.symmetric(vertical: 12),
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
                                                  ? Colors.grey
                                                  : _purple,
                                              decoration: isChecked
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                            ),
                                          ),
                                          Text(
                                            'Sugerido: ${item.suggestedQty.toStringAsFixed(0)}',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade500),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // ± qty selector
                                  _QtySelector(
                                    qty: qty,
                                    onDecrement: () => _setQty(item.id, -1),
                                    onIncrement: () => _setQty(item.id, 1),
                                  ),

                                  const SizedBox(width: 8),

                                  // Delete
                                  IconButton(
                                    icon: Icon(Icons.delete_outline,
                                        color: Colors.red.shade300, size: 20),
                                    onPressed: () => context
                                        .read<ShoppingListCubit>()
                                        .removeItem(
                                            item.id, _selectedWarehouseId!),
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
                                    borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                                textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700),
                              ),
                              icon: const Icon(Icons.shopping_cart_checkout),
                              label: Text(
                                  'Comprar (${_checked.length}/${state.items.length})'),
                              onPressed: _checked.isEmpty
                                  ? null
                                  : () {
                                      // Mark checked items as purchased
                                      for (final id in _checked.toList()) {
                                        context
                                            .read<ShoppingListCubit>()
                                            .removeItem(
                                                id, _selectedWarehouseId!);
                                      }
                                      _checked.clear();
                                      _quantities.clear();
                                    },
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
