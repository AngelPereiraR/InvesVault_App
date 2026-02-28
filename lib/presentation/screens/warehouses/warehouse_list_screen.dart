import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../cubits/warehouse/warehouse_cubit.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/warehouse_card.dart';

class WarehouseListScreen extends StatefulWidget {
  const WarehouseListScreen({super.key});

  @override
  State<WarehouseListScreen> createState() => _WarehouseListScreenState();
}

class _WarehouseListScreenState extends State<WarehouseListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<WarehouseCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/warehouses/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo almacén'),
      ),
      body: BlocConsumer<WarehouseCubit, WarehouseState>(
        listener: (context, state) {
          if (state is WarehouseActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
          if (state is WarehouseError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message),
                  backgroundColor: Theme.of(context).colorScheme.error),
            );
          }
        },
        builder: (context, state) {
          if (state is WarehouseLoading || state is WarehouseInitial) {
            return const LoadingIndicator();
          }
          if (state is WarehouseError) {
            return ErrorView(
              message: state.message,
              onRetry: () => context.read<WarehouseCubit>().load(),
            );
          }
          if (state is WarehouseLoaded && state.warehouses.isEmpty) {
            return EmptyView(
              message: 'No tienes almacenes aún',
              actionLabel: 'Crear almacén',
              onAction: () => context.push('/warehouses/new'),
            );
          }
          if (state is WarehouseLoaded) {
            return RefreshIndicator(
              onRefresh: () => context.read<WarehouseCubit>().load(),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.warehouses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final w = state.warehouses[i];
                  return WarehouseCard(
                    warehouse: w,
                    onTap: () =>
                        context.push('/warehouses/${w.id}/detail'),
                    onEdit: () =>
                        context.push('/warehouses/${w.id}/edit'),
                    onDelete: () async {
                      final confirm = await showConfirmDialog(
                        context,
                        title: 'Eliminar almacén',
                        message:
                            '¿Estás seguro de que quieres eliminar "${w.name}"? Esta acción no se puede deshacer.',
                        confirmLabel: 'Eliminar',
                        isDangerous: true,
                      );
                      if (confirm == true && context.mounted) {
                        context.read<WarehouseCubit>().delete(w.id);
                      }
                    },
                  );
                },
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}
