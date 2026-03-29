import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/category/category_cubit.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/delete_mode_bar.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_indicator.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  bool _deleteMode = false;
  final Set<int> _selected = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CategoryCubit>().load();
    });
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
      title: 'Eliminar categorías',
      message:
          '¿Eliminar $count ${count == 1 ? 'categoría' : 'categorías'}? Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      isDangerous: true,
    );
    if (confirm != true || !mounted) return;
    final ids = List<int>.from(_selected);
    setState(() {
      _deleteMode = false;
      _selected.clear();
    });
    context.read<CategoryCubit>().deleteItems(ids);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return BlocConsumer<CategoryCubit, CategoryState>(
      listenWhen: (_, curr) => curr is CategoryError,
      listener: (context, state) {
        if (state is CategoryError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: cs.error,
            ),
          );
        }
      },
      buildWhen: (prev, curr) => !(curr is CategoryError && prev is CategoryLoaded),
      builder: (context, state) {
        if (state is CategoryDeleting) {
          return const LoadingIndicator(message: 'Eliminando…');
        }
        if (state is CategoryLoading || state is CategoryInitial) {
          return const LoadingIndicator();
        }
        if (state is CategoryError) {
          return ErrorView(
            message: state.message,
            onRetry: () => context.read<CategoryCubit>().load(),
          );
        }
        if (state is CategoryLoaded) {
          return Column(
            children: [
              // ── Toolbar ──
              if (_deleteMode)
                DeleteModeBar(
                  count: _selected.length,
                  onCancel: _exitDeleteMode,
                  onDelete: _selected.isEmpty ? null : _deleteSelected,
                  emptyLabel: 'Selecciona categorías',
                  selectedSingular: 'categoría seleccionada',
                  selectedPlural: 'categorías seleccionadas',
                )
              else
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: Icon(Icons.checklist_rounded,
                        color: cs.onSurfaceVariant),
                    tooltip: 'Seleccionar para borrar',
                    onPressed: () => setState(() => _deleteMode = true),
                  ),
                ),
              // ── List ──
              Expanded(
                child: state.categories.isEmpty
                    ? EmptyView(
                        message: 'No hay categorías creadas',
                        actionLabel: 'Añadir categoría',
                        onAction: () => showCategoryDialog(context),
                      )
                    : RefreshIndicator(
                        onRefresh: () => context.read<CategoryCubit>().load(),
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: state.categories.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final cat = state.categories[i];
                            final isSelected = _selected.contains(cat.id);
                            return GestureDetector(
                              onTap: _deleteMode
                                  ? () => _toggleSelect(cat.id)
                                  : null,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected && _deleteMode
                                      ? cs.errorContainer
                                      : cs.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(16),
                                  border: isSelected && _deleteMode
                                      ? Border.all(
                                          color: cs.error, width: 1.5)
                                      : null,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.05),
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
                                    decoration: BoxDecoration(
                                      color: cs.primaryContainer,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.category_outlined,
                                        color: cs.secondary, size: 22),
                                  ),
                                  title: Text(
                                    cat.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: cs.secondary,
                                    ),
                                  ),
                                  trailing: _deleteMode
                                      ? Icon(
                                          isSelected
                                              ? Icons.check_circle
                                              : Icons.radio_button_unchecked,
                                          color: isSelected
                                              ? cs.error
                                              : cs.onSurfaceVariant,
                                        )
                                      : Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: Icon(Icons.edit_outlined,
                                                  color: cs.secondary
                                                      .withValues(alpha: 0.6),
                                                  size: 20),
                                              tooltip: 'Editar',
                                              onPressed: () =>
                                                  showCategoryDialog(context,
                                                      category: cat),
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.delete_outline,
                                                  color: cs.error, size: 20),
                                              tooltip: 'Eliminar',
                                              onPressed: () async {
                                                final confirm =
                                                    await showConfirmDialog(
                                                  context,
                                                  title: 'Eliminar categoría',
                                                  message:
                                                      '¿Eliminar "${cat.name}"? Esta acción no se puede deshacer.',
                                                  confirmLabel: 'Eliminar',
                                                  isDangerous: true,
                                                );
                                                if (confirm == true &&
                                                    context.mounted) {
                                                  context
                                                      .read<CategoryCubit>()
                                                      .delete(cat.id);
                                                }
                                              },
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
            ],
          );
        }
        return const SizedBox();
      },
    );
  }
}

// ─── Create / Edit dialog ─────────────────────────────────────────────────────
Future<void> showCategoryDialog(
  BuildContext context, {
  dynamic category,
}) async {
  final nameCtrl =
      TextEditingController(text: category?.name as String? ?? '');
  final formKey = GlobalKey<FormState>();

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      return Dialog(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category == null ? 'Añadir categoría' : 'Editar categoría',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: cs.secondary,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nombre de la categoría',
                    labelStyle: TextStyle(
                        color: cs.secondary.withValues(alpha: 0.7),
                        fontSize: 14),
                    prefixIcon: Icon(Icons.category_outlined,
                        color: cs.secondary.withValues(alpha: 0.6), size: 20),
                    filled: true,
                    fillColor: cs.primaryContainer,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: cs.secondary, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.error, width: 1.5),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.error, width: 1.5),
                    ),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Campo obligatorio'
                          : null,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: cs.secondary,
                          side: BorderSide(color: cs.secondary),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          if (formKey.currentState?.validate() != true) {
                            return;
                          }
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty) return;
                          Navigator.of(ctx).pop();
                          if (!context.mounted) return;
                          if (category == null) {
                            context.read<CategoryCubit>().create(name);
                          } else {
                            context
                                .read<CategoryCubit>()
                                .update(category.id as int, name);
                          }
                        },
                        child: const Text('Guardar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
