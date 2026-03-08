import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/router/app_router.dart';
import '../../cubits/product_list/product_list_cubit.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_indicator.dart';

const _purple = Color(0xFF3C096C);
const _mint = Color(0xFFD8F3DC);
const _white = Color(0xFFFFFFFF);

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProductListCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductListCubit, ProductListState>(
      listenWhen: (_, curr) => curr is ProductListError,
      listener: (context, state) {
        if (state is ProductListError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      },
      buildWhen: (prev, curr) =>
          !(curr is ProductListError && prev is ProductListLoaded),
      builder: (context, state) {
        if (state is ProductListLoading || state is ProductListInitial) {
          return const LoadingIndicator();
        }
        if (state is ProductListError) {
          return ErrorView(
            message: state.message,
            onRetry: () => context.read<ProductListCubit>().load(),
          );
        }
        if (state is ProductListLoaded && state.products.isEmpty) {
          return EmptyView(
            message: 'No tienes productos creados',
            actionLabel: 'Crear producto',
            onAction: () async {
              await context.openAuxiliaryRoute('/products/new');
              if (context.mounted) context.read<ProductListCubit>().load();
            },
          );
        }
        if (state is ProductListLoaded) {
          return RefreshIndicator(
            onRefresh: () => context.read<ProductListCubit>().load(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.products.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final product = state.products[i];
                final brandName = product.brand?.name;
                final subtitle = [
                  if (brandName != null) brandName,
                  if (product.barcode != null) 'Cód: ${product.barcode}',
                  'Unidad: ${product.defaultUnit}',
                ].join('  ·  ');

                return Container(
                  decoration: BoxDecoration(
                    color: _white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: _mint,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.inventory_2_outlined,
                          color: _purple, size: 22),
                    ),
                    title: Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: _purple,
                      ),
                    ),
                    subtitle: subtitle.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              subtitle,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500),
                            ),
                          )
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit_outlined,
                              color: _purple.withValues(alpha: 0.6),
                              size: 20),
                          tooltip: 'Editar',
                          onPressed: () async {
                            await context
                                .push('/products/${product.id}/edit');
                            if (context.mounted) {
                              context.read<ProductListCubit>().load();
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline,
                              color: Colors.red.shade300, size: 20),
                          tooltip: 'Eliminar',
                          onPressed: () async {
                            final confirm = await showConfirmDialog(
                              context,
                              title: 'Eliminar producto',
                              message:
                                  '¿Eliminar "${product.name}"? Esta acción no se puede deshacer.',
                              confirmLabel: 'Eliminar',
                              isDangerous: true,
                            );
                            if (confirm == true && context.mounted) {
                              context
                                  .read<ProductListCubit>()
                                  .delete(product.id);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }
        return const SizedBox();
      },
    );
  }
}
