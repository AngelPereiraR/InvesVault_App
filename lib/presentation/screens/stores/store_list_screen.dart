import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/store/store_cubit.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/delete_mode_bar.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_indicator.dart';

const _purple = Color(0xFF3C096C);
const _mint = Color(0xFFD8F3DC);
const _accentGreen = Color(0xFF52B788);
const _white = Color(0xFFFFFFFF);

class StoreListScreen extends StatefulWidget {
  const StoreListScreen({super.key});

  @override
  State<StoreListScreen> createState() => _StoreListScreenState();
}

class _StoreListScreenState extends State<StoreListScreen> {
  bool _deleteMode = false;
  final Set<int> _selected = {};

  @override
  void initState() {
    super.initState();
    context.read<StoreCubit>().load();
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
      title: 'Eliminar tiendas',
      message:
          '¿Eliminar $count ${count == 1 ? 'tienda' : 'tiendas'}? Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      isDangerous: true,
    );
    if (confirm != true || !mounted) return;
    final ids = List<int>.from(_selected);
    setState(() {
      _deleteMode = false;
      _selected.clear();
    });
    context.read<StoreCubit>().deleteItems(ids);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StoreCubit, StoreState>(
      listenWhen: (_, curr) => curr is StoreError,
      listener: (context, state) {
        if (state is StoreError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      },
      buildWhen: (prev, curr) => !(curr is StoreError && prev is StoreLoaded),
      builder: (context, state) {
        if (state is StoreDeleting) {
          return const LoadingIndicator(message: 'Eliminando…');
        }
        if (state is StoreLoading || state is StoreInitial) {
          return const LoadingIndicator();
        }
        if (state is StoreError) {
          return ErrorView(
            message: state.message,
            onRetry: () => context.read<StoreCubit>().load(),
          );
        }
        if (state is StoreLoaded && state.stores.isEmpty) {
          return EmptyView(
            message: 'No tienes tiendas registradas',
            actionLabel: 'Añadir tienda',
            onAction: () => showStoreDialog(context),
          );
        }
        if (state is StoreLoaded) {
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
                  onRefresh: () => context.read<StoreCubit>().load(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: state.stores.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final store = state.stores[i];
                      final isSelected = _selected.contains(store.id);
                      return GestureDetector(
                        onTap: _deleteMode
                            ? () => _toggleSelect(store.id)
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
                              child: const Icon(Icons.store_outlined,
                                  color: _purple, size: 22),
                            ),
                            title: Text(
                              store.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: _purple,
                              ),
                            ),
                            subtitle: store.location != null
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      store.location!,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade500),
                                    ),
                                  )
                                : null,
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
                                        onPressed: () => showStoreDialog(
                                            context,
                                            store: store),
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
                                            title: 'Eliminar tienda',
                                            message:
                                                '¿Eliminar "${store.name}"? Esta acción no se puede deshacer.',
                                            confirmLabel: 'Eliminar',
                                            isDangerous: true,
                                          );
                                          if (confirm == true &&
                                              context.mounted) {
                                            context
                                                .read<StoreCubit>()
                                                .delete(store.id);
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
Future<void> showStoreDialog(
  BuildContext context, {
  dynamic store,
}) async {
  final nameCtrl =
      TextEditingController(text: store?.name ?? '');
  final locationCtrl =
      TextEditingController(text: store?.location ?? '');
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
                store == null ? 'Añadir tienda' : 'Editar tienda',
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
                decoration: _fieldDecoration('Nombre de la tienda',
                    Icons.store_outlined),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 14),

              // Location
              TextFormField(
                controller: locationCtrl,
                decoration: _fieldDecoration(
                    'Dirección (opcional)', Icons.location_on_outlined),
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
                        if (!formKey.currentState!.validate()) return;
                        final name = nameCtrl.text.trim();
                        final location =
                            locationCtrl.text.trim().isEmpty
                                ? null
                                : locationCtrl.text.trim();
                        Navigator.of(ctx).pop();
                        if (!context.mounted) return;
                        if (store == null) {
                          context
                              .read<StoreCubit>()
                              .create(name: name, location: location);
                        } else {
                          context.read<StoreCubit>().update(store.id, {
                            'name': name,
                            if (location != null) 'location': location,
                          });
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
