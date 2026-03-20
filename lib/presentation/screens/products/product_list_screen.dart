import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/filter_params.dart';
import '../../../core/router/app_router.dart';
import '../../cubits/product_list/product_list_cubit.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/delete_mode_bar.dart';
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
  bool _deleteMode = false;
  final Set<int> _selected = {};
  late final ScrollController _scrollController;
  final _searchCtrl = TextEditingController();
  int _pageLimit = 20;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initLoad());
  }

  void _initLoad() {
    if (!mounted) return;
    final h = MediaQuery.of(context).size.height;
    _pageLimit = ((h / 200).ceil() * 2) + 4;
    context.read<ProductListCubit>().load(FilterParams(limit: _pageLimit));
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      context.read<ProductListCubit>().loadMore();
    }
    if (pos.pixels <= 200) {
      context.read<ProductListCubit>().loadPrevious();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _exitDeleteMode() => setState(() {
        _deleteMode = false;
        _selected.clear();
      });

  void _toggleSelect(int id) => setState(() {
        if (_selected.contains(id)) {
          _selected.remove(id);
          if (_selected.isEmpty) _deleteMode = false;
        } else {
          _selected.add(id);
        }
      });

  Future<void> _deleteSelected() async {
    final count = _selected.length;
    final confirm = await showConfirmDialog(
      context,
      title: 'Eliminar productos',
      message:
          '¿Eliminar $count ${count == 1 ? 'producto' : 'productos'}? Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      isDangerous: true,
    );
    if (confirm != true || !mounted) return;
    final ids = List<int>.from(_selected);
    setState(() {
      _deleteMode = false;
      _selected.clear();
    });
    context.read<ProductListCubit>().deleteItems(ids);
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
        if (state is ProductListDeleting) {
          return const LoadingIndicator(message: 'Eliminando…');
        }
        if (state is ProductListLoading || state is ProductListInitial) {
          return const LoadingIndicator();
        }
        if (state is ProductListError) {
          return ErrorView(
            message: state.message,
            onRetry: () => context.read<ProductListCubit>().load(),
          );
        }
        if (state is ProductListLoaded) {
          return Column(
            children: [
              // ── Loading previous indicator ──
              if (state.isLoadingPrevious)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(child: CircularProgressIndicator()),
                ),
              // ── Search (hidden in delete mode) ──
              if (!_deleteMode) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
                                context.read<ProductListCubit>().search('');
                              },
                            )
                          : null,
                    ),
                    onChanged: (q) =>
                        context.read<ProductListCubit>().search(q),
                  ),
                ),
                if (state.isSearching)
                  const LinearProgressIndicator(minHeight: 2),
              ],
              // ── Toolbar ──
              if (_deleteMode)
                DeleteModeBar(
                  count: _selected.length,
                  onCancel: _exitDeleteMode,
                  onDelete: _selected.isEmpty ? null : _deleteSelected,
                )
              else
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: Icon(Icons.checklist_rounded,
                        color: Colors.grey.shade500),
                    tooltip: 'Seleccionar para borrar',
                    onPressed: () => setState(() => _deleteMode = true),
                  ),
                ),
              // ── Grid ──
              Expanded(
                child: state.products.isEmpty
                    ? EmptyView(
                        message: _searchCtrl.text.isNotEmpty
                            ? 'Sin resultados para "${_searchCtrl.text}"'
                            : 'No tienes productos creados',
                        actionLabel:
                            _searchCtrl.text.isEmpty ? 'Crear producto' : null,
                        onAction: _searchCtrl.text.isEmpty
                            ? () async {
                                await context
                                    .openAuxiliaryRoute('/products/new');
                                if (context.mounted) {
                                  context
                                      .read<ProductListCubit>()
                                      .load(FilterParams(limit: _pageLimit));
                                }
                              }
                            : null,
                      )
                    : RefreshIndicator(
                  onRefresh: () {
                    _searchCtrl.clear();
                    return context
                        .read<ProductListCubit>()
                        .load(FilterParams(limit: _pageLimit));
                  },
                  child: GridView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.2 /
                          MediaQuery.textScalerOf(context).scale(1.0).clamp(
                            (390.0 / MediaQuery.sizeOf(context).width)
                                .clamp(0.8, 2.5),
                            double.infinity,
                          ),
                    ),
                    itemCount: state.products.length,
                    itemBuilder: (context, i) {
                      final product = state.products[i];
                      final isSelected = _selected.contains(product.id);
                      final brandName = product.brand?.name;
                      final subtitle = [
                        if (brandName != null) brandName,
                        if (product.barcode != null)
                          'Cód: ${product.barcode}',
                        'Unidad: ${product.defaultUnit}',
                      ].join(' · ');

                      return GestureDetector(
                        onTap: _deleteMode
                            ? () => _toggleSelect(product.id)
                            : null,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected && _deleteMode
                                ? Colors.red.shade50
                                : _white,
                            borderRadius: BorderRadius.circular(16),
                            border: isSelected && _deleteMode
                                ? Border.all(
                                    color: Colors.red.shade300, width: 1.5)
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(10, 10, 10, 6),
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
                                      child: const Icon(
                                          Icons.inventory_2_outlined,
                                          color: _purple,
                                          size: 18),
                                    ),
                                    const Spacer(),
                                    if (_deleteMode)
                                      Icon(
                                        isSelected
                                            ? Icons.check_circle
                                            : Icons.radio_button_unchecked,
                                        color: isSelected
                                            ? Colors.red.shade600
                                            : Colors.grey.shade400,
                                        size: 20,
                                      )
                                    else
                                      _ProductPopupMenu(
                                        onEdit: () async {
                                          await context.push(
                                              '/products/${product.id}/edit');
                                          if (context.mounted) {
                                            context
                                                .read<ProductListCubit>()
                                                .load();
                                          }
                                        },
                                        onDelete: () async {
                                          final confirm =
                                              await showConfirmDialog(
                                            context,
                                            title: 'Eliminar producto',
                                            message:
                                                '¿Eliminar "${product.name}"? Esta acción no se puede deshacer.',
                                            confirmLabel: 'Eliminar',
                                            isDangerous: true,
                                          );
                                          if (confirm == true &&
                                              context.mounted) {
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
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (state.isLoadingMore)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
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
