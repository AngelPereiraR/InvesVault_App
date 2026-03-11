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
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate:
                  SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.65 / MediaQuery.textScalerOf(context).scale(1.0),
              ),
              itemCount: state.products.length,
              itemBuilder: (context, i) {
                final product = state.products[i];
                final brandName = product.brand?.name;
                final subtitle = [
                  if (brandName != null) brandName,
                  if (product.barcode != null) 'Cód: ${product.barcode}',
                  'Unidad: ${product.defaultUnit}',
                ].join(' · ');

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
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: const BoxDecoration(
                                color: _mint,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.inventory_2_outlined,
                                  color: _purple, size: 18),
                            ),
                            const Spacer(),
                            _ProductPopupMenu(
                              onEdit: () async {
                                await context
                                    .push('/products/${product.id}/edit');
                                if (context.mounted) {
                                  context.read<ProductListCubit>().load();
                                }
                              },
                              onDelete: () async {
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
                        const SizedBox(height: 8),
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: _purple,
                          ),
                        ),
                        if (subtitle.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500),
                            ),
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

// ─── Product popup menu ───────────────────────────────────────────────────────
class _ProductPopupMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductPopupMenu({required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        iconSize: 18,
        onSelected: (v) {
          if (v == 'edit') onEdit();
          if (v == 'delete') onDelete();
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'edit', child: Text('Editar')),
          PopupMenuItem(value: 'delete', child: Text('Eliminar')),
        ],
      ),
    );
  }
}
