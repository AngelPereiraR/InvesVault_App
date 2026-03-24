import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/add_product_to_warehouse/add_product_to_warehouse_cubit.dart';
import '../cubits/add_product_to_warehouse/add_product_to_warehouse_state.dart';
import '../cubits/product_warehouses/product_warehouses_cubit.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/loading_indicator.dart';

class AddProductToWarehouseDialog extends StatefulWidget {
  final int productId;
  final String productName;

  const AddProductToWarehouseDialog({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  State<AddProductToWarehouseDialog> createState() =>
      _AddProductToWarehouseDialogState();
}

class _AddProductToWarehouseDialogState
    extends State<AddProductToWarehouseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _minStockCtrl = TextEditingController();

  int? _selectedWarehouseId;

  @override
  void initState() {
    super.initState();
    context.read<AddProductToWarehouseCubit>().init(widget.productId);
  }

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _priceCtrl.dispose();
    _minStockCtrl.dispose();
    super.dispose();
  }

  void _save(AddProductToWarehouseReady state) {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final quantity = int.parse(_quantityCtrl.text.trim());
    final price =
        _priceCtrl.text.isNotEmpty ? double.parse(_priceCtrl.text.trim()) : null;
    final minStock = int.parse(_minStockCtrl.text.trim());

    context.read<AddProductToWarehouseCubit>().addProductToWarehouse(
      warehouseId: _selectedWarehouseId!,
      productId: widget.productId,
      quantity: quantity,
      price: price,
      minStock: minStock,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddProductToWarehouseCubit,
        AddProductToWarehouseState>(
      listener: (context, state) {
        if (state is AddProductToWarehouseSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto agregado al almacén'),
            ),
          );
          Navigator.of(context).pop();
          // Refresh parent ProductWarehousesScreen
          context.read<ProductWarehousesCubit>().load(widget.productId);
        }
        if (state is AddProductToWarehouseError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        // Loading state
        if (state is AddProductToWarehouseInitial ||
            state is AddProductToWarehouseLoading) {
          return const AlertDialog(
            title: Text('Agregar a almacén'),
            content: SizedBox(
              height: 100,
              child: LoadingIndicator(),
            ),
          );
        }

        if (state is! AddProductToWarehouseReady) return const SizedBox();

        // Ready state - show form
        return AlertDialog(
          title: const Text('Agregar a almacén'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Warehouse dropdown
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    initialValue: _selectedWarehouseId,
                    decoration: const InputDecoration(
                      labelText: 'Almacén',
                    ),
                    validator: (v) => v == null ? 'Selecciona un almacén' : null,
                    items: state.warehouses
                        .map((w) => DropdownMenuItem(
                              value: w.id,
                              child: Text(w.name),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedWarehouseId = v),
                  ),
                  const SizedBox(height: 16),

                  // Quantity field
                  AppTextField(
                    controller: _quantityCtrl,
                    label: 'Cantidad inicial',
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'Requerido';
                      final qty = int.tryParse(v!);
                      if (qty == null) return 'Debe ser un número';
                      if (qty <= 0) return 'Debe ser mayor a 0';
                      return null;
                    },
                    onChanged: (_) => setState(() {}), // Trigger rebuild for alert
                  ),
                  const SizedBox(height: 16),

                  // Price field (optional)
                  AppTextField(
                    controller: _priceCtrl,
                    label: 'Precio (opcional)',
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v?.isEmpty ?? true) return null;
                      final price = double.tryParse(v!);
                      if (price == null) return 'Debe ser un número';
                      if (price < 0) return 'Debe ser positivo';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Min stock field
                  AppTextField(
                    controller: _minStockCtrl,
                    label: 'Stock mínimo',
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'Requerido';
                      final minStock = int.tryParse(v!);
                      if (minStock == null) return 'Debe ser un número';
                      return null;
                    },
                    onChanged: (_) => setState(() {}), // Trigger rebuild for alert
                  ),

                  // Dynamic alert if minStock > quantity
                  Builder(builder: (context) {
                    final qty = int.tryParse(_quantityCtrl.text) ?? 0;
                    final minStock = int.tryParse(_minStockCtrl.text) ?? 0;

                    if (minStock > qty && qty > 0) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning,
                              color: Theme.of(context).colorScheme.error,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Stock crítico: El mínimo ($minStock) es mayor que la cantidad inicial ($qty)',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox();
                  }),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.all(16),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                AppButton(
                  label: 'Agregar',
                  fullWidth: false,
                  loading: state is AddProductToWarehouseLoading,
                  onPressed: () => _save(state),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
