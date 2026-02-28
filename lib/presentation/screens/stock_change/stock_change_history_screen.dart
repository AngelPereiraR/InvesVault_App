import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../cubits/auth/auth_cubit.dart';
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

  @override
  void initState() {
    super.initState();
    context.read<WarehouseCubit>().load();
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      context.read<StockChangeCubit>().loadByUser(authState.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Warehouse filter
        BlocBuilder<WarehouseCubit, WarehouseState>(
          builder: (context, state) {
            if (state is! WarehouseLoaded) return const SizedBox();
            return Padding(
              padding: const EdgeInsets.all(16),
              child: DropdownButtonFormField<int?>(
                value: _selectedWarehouseId,
                decoration:
                    const InputDecoration(labelText: 'Filtrar por almacén'),
                items: [
                  const DropdownMenuItem(
                      value: null, child: Text('Todos')),
                  ...state.warehouses.map((w) => DropdownMenuItem(
                      value: w.id, child: Text(w.name))),
                ],
                onChanged: (id) {
                  setState(() => _selectedWarehouseId = id);
                  if (id != null) {
                    context
                        .read<StockChangeCubit>()
                        .loadByWarehouse(id);
                  } else {
                    final authState = context.read<AuthCubit>().state;
                    if (authState is AuthAuthenticated) {
                      context
                          .read<StockChangeCubit>()
                          .loadByUser(authState.userId);
                    }
                  }
                },
              ),
            );
          },
        ),

        Expanded(
          child: BlocBuilder<StockChangeCubit, StockChangeState>(
            builder: (context, state) {
              if (state is StockChangeLoading ||
                  state is StockChangeInitial) {
                return const LoadingIndicator();
              }
              if (state is StockChangeError) {
                return ErrorView(message: state.message);
              }
              if (state is StockChangeLoaded && state.changes.isEmpty) {
                return const EmptyView(
                    message: 'No hay cambios de stock registrados');
              }
              if (state is StockChangeLoaded) {
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  itemCount: state.changes.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, i) {
                    final c = state.changes[i];
                    final isEntry = c.changeType == 'inbound';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isEntry
                            ? Colors.green.withValues(alpha: 0.12)
                            : Colors.red.withValues(alpha: 0.12),
                        child: Icon(
                          isEntry
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color: isEntry ? Colors.green : Colors.red,
                        ),
                      ),
                      title: Text(
                          c.productName ?? 'Producto ${c.productId}'),
                      subtitle: Text(
                          '${isEntry ? '+' : '-'}${c.changeQuantity} · ${c.warehouseName ?? ''}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat('dd/MM/yy').format(
                                DateTime.tryParse(c.createdAt ?? '') ?? DateTime.now()),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          Text(
                            ' ${DateFormat('HH:mm').format(DateTime.tryParse(c.createdAt ?? '') ?? DateTime.now())}',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    );
                  },
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
