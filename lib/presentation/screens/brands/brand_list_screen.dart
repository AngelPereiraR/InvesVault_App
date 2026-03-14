import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/brand/brand_cubit.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/delete_mode_bar.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_indicator.dart';

const _purple = Color(0xFF3C096C);
const _mint = Color(0xFFD8F3DC);
const _accentGreen = Color(0xFF52B788);
const _white = Color(0xFFFFFFFF);

class BrandListScreen extends StatefulWidget {
  const BrandListScreen({super.key});

  @override
  State<BrandListScreen> createState() => _BrandListScreenState();
}

class _BrandListScreenState extends State<BrandListScreen> {
  bool _deleteMode = false;
  final Set<int> _selected = {};

  @override
  void initState() {
    super.initState();
    context.read<BrandCubit>().load();
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
      title: 'Eliminar marcas',
      message:
          '¿Eliminar $count ${count == 1 ? 'marca' : 'marcas'}? Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      isDangerous: true,
    );
    if (confirm != true || !mounted) return;
    final ids = List<int>.from(_selected);
    setState(() {
      _deleteMode = false;
      _selected.clear();
    });
    context.read<BrandCubit>().deleteItems(ids);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BrandCubit, BrandState>(
      listenWhen: (_, curr) => curr is BrandError,
      listener: (context, state) {
        if (state is BrandError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      },
      buildWhen: (prev, curr) => !(curr is BrandError && prev is BrandLoaded),
      builder: (context, state) {
        if (state is BrandDeleting) {
          return const LoadingIndicator(message: 'Eliminando…');
        }
        if (state is BrandLoading || state is BrandInitial) {
          return const LoadingIndicator();
        }
        if (state is BrandError) {
          return ErrorView(
            message: state.message,
            onRetry: () => context.read<BrandCubit>().load(),
          );
        }
        if (state is BrandLoaded && state.brands.isEmpty) {
          return EmptyView(
            message: 'No tienes marcas registradas',
            actionLabel: 'Añadir marca',
            onAction: () => showBrandDialog(context),
          );
        }
        if (state is BrandLoaded) {
          return Column(
            children: [
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
              // ── List ──
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => context.read<BrandCubit>().load(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: state.brands.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final brand = state.brands[i];
                      final isSelected = _selected.contains(brand.id);
                      return GestureDetector(
                        onTap: _deleteMode
                            ? () => _toggleSelect(brand.id)
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
                              child: const Icon(Icons.label_outlined,
                                  color: _purple, size: 22),
                            ),
                            title: Text(
                              brand.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: _purple,
                              ),
                            ),
                            trailing: _deleteMode
                                ? Icon(
                                    isSelected
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color: isSelected
                                        ? Colors.red.shade600
                                        : Colors.grey.shade400,
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit_outlined,
                                            color: _purple.withValues(
                                                alpha: 0.6),
                                            size: 20),
                                        tooltip: 'Editar',
                                        onPressed: () => showBrandDialog(
                                            context,
                                            brand: brand),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete_outline,
                                            color: Colors.red.shade300,
                                            size: 20),
                                        tooltip: 'Eliminar',
                                        onPressed: () async {
                                          final confirm =
                                              await showConfirmDialog(
                                            context,
                                            title: 'Eliminar marca',
                                            message:
                                                '¿Eliminar "${brand.name}"? Esta acción no se puede deshacer.',
                                            confirmLabel: 'Eliminar',
                                            isDangerous: true,
                                          );
                                          if (confirm == true &&
                                              context.mounted) {
                                            context
                                                .read<BrandCubit>()
                                                .delete(brand.id);
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

// ─── Create / Edit dialog (public so AppShell can invoke it) ─────────────────
Future<void> showBrandDialog(
  BuildContext context, {
  dynamic brand,
}) async {
  final nameCtrl = TextEditingController(text: brand?.name ?? '');
  final formKey = GlobalKey<FormState>();

  await showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
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
                brand == null ? 'Añadir marca' : 'Editar marca',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _purple,
                ),
              ),
              const SizedBox(height: 20),

              // Name
              TextFormField(
                controller: nameCtrl,
                decoration: _fieldDecoration(
                    'Nombre de la marca', Icons.label_outlined),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty)
                        ? 'Campo obligatorio'
                        : null,
              ),
              const SizedBox(height: 24),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _purple,
                        side: const BorderSide(color: _purple),
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
                        backgroundColor: _accentGreen,
                        foregroundColor: _white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        if (formKey.currentState?.validate() != true) return;
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) return;
                        Navigator.of(ctx).pop();
                        if (!context.mounted) return;
                        if (brand == null) {
                          context.read<BrandCubit>().create(name);
                        } else {
                          context
                              .read<BrandCubit>()
                              .update(brand.id as int, name);
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
    ),
  );
}

InputDecoration _fieldDecoration(String label, IconData icon) =>
    InputDecoration(
      labelText: label,
      labelStyle:
          TextStyle(color: _purple.withOpacity(0.7), fontSize: 14),
      prefixIcon: Icon(icon, color: _purple.withOpacity(0.6), size: 20),
      filled: true,
      fillColor: _mint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _purple, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade700, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade700, width: 1.5),
      ),
    );
