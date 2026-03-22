import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/router/app_router.dart';
import '../../cubits/dashboard/dashboard_cubit.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_indicator.dart';

class CriticalStockScreen extends StatelessWidget {
  const CriticalStockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock crítico'),
        elevation: 0,
      ),
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading || state is DashboardInitial) {
            return const LoadingIndicator(message: 'Cargando…');
          }
          if (state is DashboardError) {
            return ErrorView(
              message: state.message,
              onRetry: () => context.read<DashboardCubit>().load(),
            );
          }
          if (state is! DashboardLoaded) return const SizedBox();

          final items = state.allLowStockItems;

          if (items.isEmpty) {
            return const EmptyView(
              message: 'No hay productos en stock crítico',
              icon: Icons.check_circle_outline,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final cs = Theme.of(context).colorScheme;
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final item = items[index];
              return GestureDetector(
                onTap: () => context.openAuxiliaryRoute(
                  '/products/${item.id}/detail',
                  extra: {'warehouseId': item.warehouseId},
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? cs.errorContainer : const Color(0xFFFDE2E4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: isDark
                            ? cs.error.withValues(alpha: 0.3)
                            : const Color(0xFFFBD0D3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: cs.error, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.product?.name ??
                                  'Producto ${item.productId}',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface),
                            ),
                            Text(
                              'Stock: ${item.quantity.toInt()} / Mín: ${item.minQuantity?.toInt() ?? 0}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          color: cs.error.withValues(alpha: 0.6), size: 20),
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
