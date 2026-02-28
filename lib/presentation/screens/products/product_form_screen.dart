import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../cubits/product_form/product_form_cubit.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/loading_indicator.dart';
import '../../../core/utils/validators.dart';

class ProductFormScreen extends StatefulWidget {
  final int? productId;
  const ProductFormScreen({super.key, this.productId});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  int? _selectedBrandId;
  String _unit = 'unidad';

  bool get isEdit => widget.productId != null;

  @override
  void initState() {
    super.initState();
    context
        .read<ProductFormCubit>()
        .init(productId: widget.productId);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _barcodeCtrl.dispose();
    super.dispose();
  }

  void _prefillFromState(ProductFormReady state) {
    if (state.existingProduct != null && _nameCtrl.text.isEmpty) {
      final p = state.existingProduct!;
      _nameCtrl.text = p.name;
      _barcodeCtrl.text = p.barcode ?? '';
      _selectedBrandId = p.brandId;
      _unit = p.defaultUnit;
    }
  }

  void _save(ProductFormReady readyState) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final data = {
      'name': _nameCtrl.text.trim(),
      if (_barcodeCtrl.text.isNotEmpty) 'barcode': _barcodeCtrl.text.trim(),
      if (_selectedBrandId != null) 'brand_id': _selectedBrandId,
      'default_unit': _unit,
    };
    context.read<ProductFormCubit>().save(data, productId: widget.productId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductFormCubit, ProductFormState>(
      listener: (context, state) {
        if (state is ProductFormSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Producto guardado correctamente')));
          context.pop();
        }
        if (state is ProductFormError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error));
        }
      },
      builder: (context, state) {
        if (state is ProductFormLoading || state is ProductFormInitial) {
          return Scaffold(
            appBar: AppBar(
                title:
                    Text(isEdit ? 'Editar producto' : 'Nuevo producto')),
            body: const LoadingIndicator(),
          );
        }
        if (state is! ProductFormReady) return const SizedBox();
        _prefillFromState(state);

        return Scaffold(
          appBar: AppBar(
              title: Text(isEdit ? 'Editar producto' : 'Nuevo producto')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    controller: _nameCtrl,
                    label: 'Nombre del producto',
                    validator: Validators.required,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _barcodeCtrl,
                          label: 'Código de barras (opcional)',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        icon: const Icon(Icons.qr_code_scanner),
                        onPressed: () => context.push('/scanner', extra: {
                          'onScanned': (String code) {
                            _barcodeCtrl.text = code;
                          }
                        }),
                        tooltip: 'Escanear',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _selectedBrandId,
                    decoration:
                        const InputDecoration(labelText: 'Marca (opcional)'),
                    items: state.brands
                        .map((b) => DropdownMenuItem(
                            value: b.id, child: Text(b.name)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedBrandId = v),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _unit,
                    decoration:
                        const InputDecoration(labelText: 'Unidad por defecto'),
                    items: const ['unidad', 'kg', 'g', 'l', 'ml', 'caja', 'paquete']
                        .map((u) =>
                            DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (v) => setState(() => _unit = v!),
                  ),
                  const SizedBox(height: 32),
                  AppButton(
                    label: isEdit ? 'Guardar cambios' : 'Crear producto',
                    loading: state is ProductFormLoading,
                    onPressed: () => _save(state),
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
