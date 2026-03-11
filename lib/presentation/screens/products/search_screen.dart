import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/router/app_router.dart';
import '../../cubits/product_form/product_form_cubit.dart';
import '../../../data/models/product_model.dart';

const _purple = Color(0xFF3C096C);
const _mint = Color(0xFFD8F3DC);
const _accentGreen = Color(0xFF52B788);

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    context.read<ProductFormCubit>().loadForPicker();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _purple,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        title: TextField(
          controller: _searchCtrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          decoration: const InputDecoration(
            hintText: 'Buscar productos…',
            hintStyle: TextStyle(color: Colors.white54),
            border: InputBorder.none,
            filled: false,
          ),
          onChanged: (v) => setState(() => _query = v.trim()),
        ),
        actions: [
          if (_searchCtrl.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchCtrl.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: SafeArea(top: false, child: BlocBuilder<ProductFormCubit, ProductFormState>(
        builder: (context, state) {
          if (state is ProductFormLoading || state is ProductFormInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ProductFormError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () =>
                        context.read<ProductFormCubit>().loadForPicker(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }
          if (state is! ProductFormReady) return const SizedBox();

          final results = _query.isEmpty
              ? state.allProducts
              : state.allProducts
                  .where((p) =>
                      p.name.toLowerCase().contains(_query.toLowerCase()) ||
                      (p.barcode?.contains(_query) ?? false) ||
                      (p.brand?.name
                              .toLowerCase()
                              .contains(_query.toLowerCase()) ??
                          false))
                  .toList();

          if (results.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(
                    _query.isEmpty
                        ? 'No hay productos en el catálogo'
                        : 'Sin resultados para "$_query"',
                    style: TextStyle(
                        fontSize: 15, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    icon: const Icon(Icons.add, color: _accentGreen),
                    label: const Text('Crear nuevo producto',
                        style: TextStyle(color: _accentGreen)),
                    onPressed: () =>
                        context.openAuxiliaryRoute('/products/new'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: results.length,
            itemBuilder: (context, i) {
              final product = results[i];
              return _ProductSearchTile(product: product);
            },
          );
        },
      )),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _accentGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Escanear'),
        onPressed: () => context.openAuxiliaryRoute(
          '/scanner',
          extra: <String, dynamic>{'onScanned': null},
        ),
      ),
    );
  }
}

class _ProductSearchTile extends StatelessWidget {
  final ProductModel product;
  const _ProductSearchTile({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: _mint,
            shape: BoxShape.circle,
          ),
          child: product.imageUrl != null
              ? ClipOval(
                  child: Image.network(product.imageUrl!,
                      fit: BoxFit.cover))
              : const Icon(Icons.inventory_2_outlined,
                  color: _purple, size: 22),
        ),
        title: Text(
          product.name,
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 15, color: _purple),
        ),
        subtitle: Text(
          [
            if (product.brand != null) product.brand!.name,
            product.defaultUnit,
            if (product.barcode != null) product.barcode!,
          ].join(' · '),
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        trailing: const Icon(Icons.chevron_right, color: _purple),
        onTap: () => _showProductInfo(context, product),
      ),
    );
  }

  void _showProductInfo(BuildContext context, ProductModel product) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(product.name,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _purple)),
            const SizedBox(height: 8),
            if (product.brand != null)
              _Row('Marca', product.brand!.name),
            _Row('Unidad', product.defaultUnit),
            if (product.barcode != null)
              _Row('Código de barras', product.barcode!),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar producto'),
                onPressed: () {
                  Navigator.of(context).pop();
                  context.openAuxiliaryRoute('/products/${product.id}/edit');
                },
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Text('$label: ',
                style: const TextStyle(
                    color: Colors.grey, fontSize: 13)),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 13)),
          ],
        ),
      );
}
