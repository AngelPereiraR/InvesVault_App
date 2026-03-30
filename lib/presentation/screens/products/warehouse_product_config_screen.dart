import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/product_detail/product_detail_cubit.dart';
import '../../cubits/store/store_cubit.dart';

class WarehouseProductConfigScreen extends StatefulWidget {
  const WarehouseProductConfigScreen({super.key});

  @override
  State<WarehouseProductConfigScreen> createState() =>
      _WarehouseProductConfigScreenState();
}

class _WarehouseProductConfigScreenState
    extends State<WarehouseProductConfigScreen> {
  late final TextEditingController _minQtyCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _obsCtrl;
  int? _storeId;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _minQtyCtrl = TextEditingController();
    _priceCtrl = TextEditingController();
    _obsCtrl = TextEditingController();
    context.read<StoreCubit>().load();
  }

  void _initFromState(ProductDetailState state) {
    if (_initialized) return;
    final wp = state is ProductDetailLoaded
        ? state.warehouseProduct
        : state is ProductDetailUpdating
            ? state.warehouseProduct
            : null;
    if (wp == null) return;
    _minQtyCtrl.text =
        wp.minQuantity != null ? wp.minQuantity!.toStringAsFixed(2) : '';
    _priceCtrl.text =
        wp.pricePerUnit != null ? wp.pricePerUnit!.toStringAsFixed(2) : '';
    _obsCtrl.text = wp.observations ?? '';
    _storeId = wp.storeId;
    _initialized = true;
  }

  @override
  void dispose() {
    _minQtyCtrl.dispose();
    _priceCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final data = <String, dynamic>{
      'min_quantity': _minQtyCtrl.text.isEmpty
          ? null
          : (double.tryParse(_minQtyCtrl.text) ?? 0),
      'store_id': _storeId,
      'observations':
          _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
    };
    if (_priceCtrl.text.isNotEmpty) {
      data['price_per_unit'] = double.tryParse(_priceCtrl.text) ?? 0;
    }
    context.read<ProductDetailCubit>().updateDetails(data);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductDetailCubit, ProductDetailState>(
      listener: (context, state) {
        if (state is ProductDetailError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ));
        }
      },
      builder: (context, state) {
        _initFromState(state);
        return Scaffold(
          appBar: AppBar(title: const Text('Ajustes en almacén')),
          body: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _minQtyCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Cantidad mínima (alerta)',
                      prefixIcon: Icon(Icons.warning_amber_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _priceCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Precio por unidad (€)',
                      prefixIcon: Icon(Icons.euro_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  BlocBuilder<StoreCubit, StoreState>(
                    builder: (context, storeState) {
                      if (storeState is! StoreLoaded) {
                        return const SizedBox();
                      }
                      return DropdownButtonFormField<int?>(
                        value: _storeId,
                        decoration: const InputDecoration(
                          labelText: 'Tienda (última compra)',
                          prefixIcon: Icon(Icons.store_outlined),
                        ),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('Sin tienda')),
                          ...storeState.stores.map((s) =>
                              DropdownMenuItem(value: s.id, child: Text(s.name))),
                        ],
                        onChanged: (v) => setState(() => _storeId = v),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _obsCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Observaciones (opcional)',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _save,
                      child: const Text('Guardar cambios'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
