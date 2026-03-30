import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/models/filter_params.dart';
import '../../cubits/stock_change/stock_change_cubit.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_indicator.dart';

class ProductStockHistoryScreen extends StatefulWidget {
  final int productId;
  final String productName;

  const ProductStockHistoryScreen({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  State<ProductStockHistoryScreen> createState() =>
      _ProductStockHistoryScreenState();
}

class _ProductStockHistoryScreenState
    extends State<ProductStockHistoryScreen> {
  String _typeFilter = 'all';
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    context
        .read<StockChangeCubit>()
        .loadByProduct(widget.productId, const FilterParams(limit: 20));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<StockChangeCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Historial — ${widget.productName}')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _FilterBar(
              selected: _typeFilter,
              onChanged: (v) => setState(() => _typeFilter = v),
            ),
            Expanded(
              child: BlocBuilder<StockChangeCubit, StockChangeState>(
                builder: (context, state) {
                  if (state is StockChangeLoading) {
                    return const LoadingIndicator();
                  }
                  if (state is StockChangeError) {
                    return ErrorView(message: state.message);
                  }
                  if (state is StockChangeLoaded) {
                    final filtered = _typeFilter == 'all'
                        ? state.changes
                        : state.changes
                            .where((c) => c.changeType == _typeFilter)
                            .toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Text(
                          'Sin movimientos',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount:
                          filtered.length + (state.isLoadingMore ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, i) {
                        if (i >= filtered.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final c = filtered[i];
                        return _HistoryCard(change: c);
                      },
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _FilterBar({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _Chip(label: 'Todos', value: 'all', selected: selected, color: Theme.of(context).colorScheme.secondary, onTap: onChanged),
          const SizedBox(width: 6),
          _Chip(label: 'Entradas', value: 'inbound', selected: selected, color: Colors.green, onTap: onChanged),
          const SizedBox(width: 6),
          _Chip(label: 'Salidas', value: 'outbound', selected: selected, color: Colors.red, onTap: onChanged),
          const SizedBox(width: 6),
          _Chip(label: 'Ajustes', value: 'adjustment', selected: selected, color: Colors.orange, onTap: onChanged),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final Color color;
  final ValueChanged<String> onTap;

  const _Chip({
    required this.label,
    required this.value,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(40) : Colors.transparent,
          border: Border.all(color: isSelected ? color : Colors.grey.shade400),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final dynamic change;

  const _HistoryCard({required this.change});

  @override
  Widget build(BuildContext context) {
    final isInbound = change.changeType == 'inbound';
    final isAdjustment = change.changeType == 'adjustment';
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
        DateTime.tryParse(change.createdAt ?? '') ?? DateTime.now());

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: iconColor.withAlpha(30),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: iconColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$sign${change.changeQuantity}',
                          style: TextStyle(
                            color: iconColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (change.reason != null &&
                          (change.reason as String).isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            change.reason!,
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person_outline,
                          size: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant),
                      const SizedBox(width: 3),
                      Text(
                        change.userName ?? 'Sistema',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.access_time,
                          size: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant),
                      const SizedBox(width: 3),
                      Text(
                        dateStr,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant),
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
  }
}
