import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/warehouse_detail/warehouse_detail_cubit.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/low_stock_badge.dart';
import '../../widgets/product_list_tile.dart';

class WarehouseDetailScreen extends StatefulWidget {
  final int warehouseId;
  const WarehouseDetailScreen({super.key, required this.warehouseId});

  @override
  State<WarehouseDetailScreen> createState() =>
      _WarehouseDetailScreenState();
}

class _WarehouseDetailScreenState extends State<WarehouseDetailScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<WarehouseDetailCubit>().load(widget.warehouseId);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final userId =
        authState is AuthAuthenticated ? authState.userId : 0;

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
                .load(widget.warehouseId),
          );
        }
        if (state is! WarehouseDetailLoaded) return const SizedBox();

        final lowCount = state.products.where((p) => p.isLowStock).length;

        return Column(
          children: [
            // ── Header actions bar ─
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  LowStockBadge(count: lowCount),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => context
                        .push('/warehouses/${widget.warehouseId}/share'),
                    icon: const Icon(Icons.share),
                    label: const Text('Compartir'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    tooltip: 'Añadir producto',
                    onPressed: () =>
                        context.push('/products/new'),
                  ),
                ],
              ),
            ),

            // ── Search ─
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
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
              child: state.filtered.isEmpty
                  ? EmptyView(
                      message: 'No hay productos en este almacén',
                      actionLabel: 'Añadir producto',
                      onAction: () => context.push('/products/new'),
                    )
                  : RefreshIndicator(
                      onRefresh: () => context
                          .read<WarehouseDetailCubit>()
                          .load(widget.warehouseId),
                      child: ListView.separated(
                        itemCount: state.filtered.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, i) {
                          final item = state.filtered[i];
                          return ProductListTile(
                            warehouseProduct: item,
                            onTap: () => context.push(
                                '/products/${item.id}/detail',
                                extra: {
                                  'warehouseId': widget.warehouseId
                                }),
                            onAdd: () =>
                                context
                                    .read<WarehouseDetailCubit>()
                                    .quickUpdate(
                                      warehouseProductId: item.id,
                                      productId: item.productId,
                                      warehouseId: widget.warehouseId,
                                      userId: userId,
                                      delta: 1.0,
                                    ),
                            onRemove: () async {
                              if ((item.quantity - 1) < 0) return;
                              context
                                  .read<WarehouseDetailCubit>()
                                  .quickUpdate(
                                    warehouseProductId: item.id,
                                    productId: item.productId,
                                    warehouseId: widget.warehouseId,
                                    userId: userId,
                                    delta: -1.0,
                                  );
                            },
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
