import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/models/filter_params.dart';
import '../../../core/theme/app_colors.dart';
import '../../cubits/stock_change/stock_change_cubit.dart';
import '../../cubits/warehouse/warehouse_cubit.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_indicator.dart';

class StockChangeHistoryScreen extends StatefulWidget {
  const StockChangeHistoryScreen({super.key});

  @override
  State<StockChangeHistoryScreen> createState() =>
      _StockChangeHistoryScreenState();
}

class _StockChangeHistoryScreenState
    extends State<StockChangeHistoryScreen> {
  int? _selectedWarehouseId;
  String _typeFilter = 'all'; // 'all' | 'inbound' | 'outbound' | 'adjustment'
  late final ScrollController _scrollController;
  int _pageLimit = 20;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    context.read<WarehouseCubit>().load();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initPageLimit());
  }

  void _initPageLimit() {
    if (!mounted) return;
    final h = MediaQuery.of(context).size.height;
    _pageLimit = (h / 92).ceil() + 3;
  }

  void _loadChanges(int warehouseId) {
    context
        .read<StockChangeCubit>()
        .loadByWarehouse(warehouseId, FilterParams(limit: _pageLimit));
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      context.read<StockChangeCubit>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        // ── Warehouse selector ──────────────────────────────────────────
        Container(
          color: cs.surface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: BlocBuilder<WarehouseCubit, WarehouseState>(
            builder: (context, state) {
              if (state is! WarehouseLoaded) return const LoadingIndicator();
              return DropdownButtonFormField<int?>(
                value: _selectedWarehouseId,
                decoration: InputDecoration(
                  labelText: 'Almacén',
                  prefixIcon:
                      Icon(Icons.warehouse_outlined, color: cs.secondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: cs.primaryContainer,
                  labelStyle: TextStyle(color: cs.secondary),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                ),
                items: state.warehouses
                    .map((w) =>
                        DropdownMenuItem(value: w.id, child: Text(w.name)))
                    .toList(),
                onChanged: (id) {
                  setState(() {
                    _selectedWarehouseId = id;
                    _typeFilter = 'all';
                  });
                  if (id != null) {
                    _loadChanges(id);
                  }
                },
              );
            },
          ),
        ),

        // ── Type chips ──────────────────────────────────────────────────
        if (_selectedWarehouseId != null)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _TypeChip(
                      label: 'Todos',
                      color: Theme.of(context).colorScheme.secondary,
                      selected: _typeFilter == 'all',
                      onTap: () => setState(() => _typeFilter = 'all')),
                  const SizedBox(width: 8),
                  _TypeChip(
                      label: 'Entradas',
                      color: AppColors.success,
                      selected: _typeFilter == 'inbound',
                      onTap: () =>
                          setState(() => _typeFilter = 'inbound')),
                  const SizedBox(width: 8),
                  _TypeChip(
                      label: 'Salidas',
                      color: cs.error,
                      selected: _typeFilter == 'outbound',
                      onTap: () =>
                          setState(() => _typeFilter = 'outbound')),
                  const SizedBox(width: 8),
                  _TypeChip(
                      label: 'Ajustes',
                      color: AppColors.warning,
                      selected: _typeFilter == 'adjustment',
                      onTap: () =>
                          setState(() => _typeFilter = 'adjustment')),
                ],
              ),
            ),
          ),

        // ── List ────────────────────────────────────────────────────────
        Expanded(
          child: _selectedWarehouseId == null
              ? const EmptyView(
                  message:
                      'Selecciona un almacén para ver su historial',
                  icon: Icons.history,
                )
              : BlocConsumer<StockChangeCubit, StockChangeState>(
                  listenWhen: (_, curr) => curr is StockChangeError,
                  listener: (context, state) {
                    if (state is StockChangeError) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(state.message),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ));
                    }
                  },
                  buildWhen: (prev, curr) =>
                      !(curr is StockChangeError &&
                          prev is StockChangeLoaded),
                  builder: (context, state) {
                    if (state is StockChangeLoading ||
                        state is StockChangeInitial) {
                      return const LoadingIndicator();
                    }
                    if (state is StockChangeError) {
                      return ErrorView(
                        message: state.message,
                        onRetry: () =>
                            _loadChanges(_selectedWarehouseId!),
                      );
                    }
                    if (state is StockChangeLoaded) {
                      final items = _typeFilter == 'all'
                          ? state.changes
                          : state.changes
                              .where((c) => c.changeType == _typeFilter)
                              .toList();

                      if (items.isEmpty) {
                        return const EmptyView(
                          message: 'No hay movimientos registrados',
                          icon: Icons.history_toggle_off_outlined,
                        );
                      }

                      return Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          final cs = Theme.of(context).colorScheme;
                          final c = items[i];
                          final isEntry = c.changeType == 'inbound';
                          final isAdjust = c.changeType == 'adjustment';
                          final color = isAdjust
                              ? AppColors.warning
                              : isEntry
                                  ? AppColors.success
                                  : cs.error;
                          final icon = isAdjust
                              ? Icons.tune
                              : isEntry
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward;
                          final sign = isAdjust ? '=' : isEntry ? '+' : '-';

                          final dt = DateTime.tryParse(c.createdAt ?? '');
                          final dateStr = dt != null
                              ? DateFormat('dd/MM/yy HH:mm').format(dt)
                              : '—';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: cs.surface,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 4),
                              leading: CircleAvatar(
                                backgroundColor:
                                    color.withValues(alpha: 0.12),
                                child: Icon(icon, color: color, size: 20),
                              ),
                              title: Text(
                                c.productName ??
                                    'Producto ${c.productId}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: cs.secondary,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2),
                                        decoration: BoxDecoration(
                                          color: color
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '$sign${c.changeQuantity}',
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: color),
                                        ),
                                      ),
                                      if (c.reason != null &&
                                          c.reason!.isNotEmpty) ...[  
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            c.reason!,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: cs.onSurfaceVariant,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(Icons.person_outline,
                                          size: 11,
                                          color: cs.onSurfaceVariant),
                                      const SizedBox(width: 3),
                                      Text(
                                        c.userName ?? 'Sistema',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: cs.onSurfaceVariant),
                                      ),
                                      const SizedBox(width: 10),
                                      Icon(Icons.access_time,
                                          size: 11,
                                          color: cs.onSurfaceVariant),
                                      const SizedBox(width: 3),
                                      Text(
                                        dateStr,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: cs.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                          ),
                          if (state.isLoadingMore)
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: Center(child: CircularProgressIndicator()),
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

// ─── Type filter chip ─────────────────────────────────────────────────────────
class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? cs.onPrimary : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
