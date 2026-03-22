import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/filter_params.dart';
import '../../../core/router/app_router.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/warehouse/warehouse_cubit.dart';
import '../../cubits/warehouse_user/warehouse_user_cubit.dart';
import '../../../data/models/warehouse_model.dart';
import '../../../data/models/warehouse_user_model.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/delete_mode_bar.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_indicator.dart';
import '../../../core/utils/validators.dart';

/// Muestra un diálogo con dos pestañas: Información y Colaboradores.
/// Para nuevo almacén, la pestaña Colaboradores se activa tras la creación.
Future<void> showWarehouseDialog(BuildContext context,
    {int? warehouseId}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogCtx) => _WarehouseDialog(
      warehouseId: warehouseId,
      warehouseCubit: context.read<WarehouseCubit>(),
      warehouseUserCubit: context.read<WarehouseUserCubit>(),
      authCubit: context.read<AuthCubit>(),
      rootContext: context,
    ),
  );
}

// ── Dialog widget ───────────────────────────────────────────────────────────
class _WarehouseDialog extends StatefulWidget {
  final int? warehouseId;
  final WarehouseCubit warehouseCubit;
  final WarehouseUserCubit warehouseUserCubit;
  final AuthCubit authCubit;
  final BuildContext rootContext;

  const _WarehouseDialog({
    this.warehouseId,
    required this.warehouseCubit,
    required this.warehouseUserCubit,
    required this.authCubit,
    required this.rootContext,
  });

  @override
  State<_WarehouseDialog> createState() => _WarehouseDialogState();
}

class _WarehouseDialogState extends State<_WarehouseDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String _selectedRole = 'viewer';
  int? _activeWarehouseId;

  bool get isEdit => widget.warehouseId != null;
  bool get _collabEnabled => _activeWarehouseId != null;

  @override
  void initState() {
    super.initState();
    _activeWarehouseId = widget.warehouseId;
    _tabCtrl = TabController(length: 2, vsync: this);

    if (isEdit) {
      final state = widget.warehouseCubit.state;
      if (state is WarehouseLoaded) {
        try {
          final w =
              state.warehouses.firstWhere((w) => w.id == widget.warehouseId);
          _nameCtrl.text = w.name;
        } catch (_) {}
      }
      widget.warehouseUserCubit.load(_activeWarehouseId!);
    }

    _tabCtrl.addListener(() {
      if (_tabCtrl.indexIsChanging && _tabCtrl.index == 1 && !_collabEnabled) {
        _tabCtrl.animateTo(0);
      }
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _saveInfo() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final authState = widget.authCubit.state;
    final userId =
        authState is AuthAuthenticated ? authState.userId : 0;
    if (isEdit) {
      widget.warehouseCubit
          .update(widget.warehouseId!, {'name': _nameCtrl.text.trim()});
    } else {
      widget.warehouseCubit.create(
        name: _nameCtrl.text.trim(),
        ownerId: userId,
        isShared: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: widget.warehouseCubit),
        BlocProvider.value(value: widget.warehouseUserCubit),
      ],
      child: BlocListener<WarehouseCubit, WarehouseState>(
        listener: (ctx, state) {
          if (state is WarehouseCreated) {
            // New warehouse just created – unlock collaborators tab
            setState(() => _activeWarehouseId = state.warehouse.id);
            widget.warehouseUserCubit.load(state.warehouse.id);
            _tabCtrl.animateTo(1);
          } else if (state is WarehouseActionSuccess && isEdit) {
            ScaffoldMessenger.of(widget.rootContext).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            Navigator.of(context).pop();
          } else if (state is WarehouseError) {
            ScaffoldMessenger.of(widget.rootContext).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        child: Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Title bar ─────────────────────────────────────────
                Container(
                  color: cs.secondary,
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          isEdit ? 'Editar almacén' : 'Nuevo almacén',
                          style: TextStyle(
                              color: cs.onPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: cs.onPrimary.withValues(alpha: 0.7)),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                // ── Tabs ──────────────────────────────────────────────
                Theme(
                  data: Theme.of(context).copyWith(
                    tabBarTheme: TabBarThemeData(
                      labelColor: cs.secondary,
                      unselectedLabelColor: cs.onSurfaceVariant,
                      indicatorColor: cs.secondary,
                    ),
                  ),
                  child: TabBar(
                    controller: _tabCtrl,
                    tabs: [
                      const Tab(text: 'Información'),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Colaboradores'),
                            if (!_collabEnabled) ...[
                              const SizedBox(width: 4),
                              Icon(Icons.lock_outline,
                                  size: 13,
                                  color: cs.onSurfaceVariant),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Tab content ───────────────────────────────────────
                Flexible(
                  child: TabBarView(
                    controller: _tabCtrl,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      // ── Tab 0: Info ──
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AppTextField(
                                controller: _nameCtrl,
                                label: 'Nombre del almacén',
                                validator: Validators.required,
                              ),
                              const SizedBox(height: 20),
                              BlocBuilder<WarehouseCubit, WarehouseState>(
                                builder: (ctx2, state) {
                                  final loading = state is WarehouseLoading;
                                  return FilledButton(
                                    onPressed: loading ? null : _saveInfo,
                                    style: FilledButton.styleFrom(
                                        backgroundColor: cs.secondary),
                                    child: loading
                                        ? SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: cs.onPrimary))
                                        : Text(isEdit
                                            ? 'Guardar cambios'
                                            : 'Crear almacén'),
                                  );
                                },
                              ),
                              if (!isEdit) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'Tras crear el almacén podrás añadir colaboradores.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: cs.onSurfaceVariant),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      // ── Tab 1: Collaborators ──
                      _CollaboratorsTab(
                        activeWarehouseId: _activeWarehouseId,
                        emailCtrl: _emailCtrl,
                        selectedRole: _selectedRole,
                        onRoleChanged: (v) =>
                            setState(() => _selectedRole = v ?? 'viewer'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Collaborators tab body ──────────────────────────────────────────────────
class _CollaboratorsTab extends StatelessWidget {
  final int? activeWarehouseId;
  final TextEditingController emailCtrl;
  final String selectedRole;
  final ValueChanged<String?> onRoleChanged;

  const _CollaboratorsTab({
    required this.activeWarehouseId,
    required this.emailCtrl,
    required this.selectedRole,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (activeWarehouseId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline,
                  size: 40, color: cs.onSurfaceVariant),
              const SizedBox(height: 12),
              Text(
                'Crea el almacén primero para gestionar colaboradores.',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return BlocBuilder<WarehouseUserCubit, WarehouseUserState>(
      builder: (context, state) {
        final cs = Theme.of(context).colorScheme;
        final users = state is WarehouseUserLoaded
            ? state.users
            : <WarehouseUserModel>[];
        final isLoading = state is WarehouseUserLoading;

        return Column(
          children: [
            // ── Add by email ──
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: emailCtrl,
                          label: 'Email del usuario',
                          keyboardType: TextInputType.emailAddress,
                          onFieldSubmitted: (_) =>
                              _doAdd(context, state),
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: selectedRole,
                        underline: const SizedBox(),
                        isDense: true,
                        style: TextStyle(
                            fontSize: 13, color: cs.secondary),
                        items: const [
                          DropdownMenuItem(
                              value: 'viewer', child: Text('Lector')),
                          DropdownMenuItem(
                              value: 'editor', child: Text('Editor')),
                        ],
                        onChanged: onRoleChanged,
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: cs.secondary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14)),
                        onPressed: state is WarehouseUserLoaded &&
                                state.isAdding
                            ? null
                            : () => _doAdd(context, state),
                        child: state is WarehouseUserLoaded &&
                                state.isAdding
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: cs.onPrimary))
                            : const Icon(Icons.person_add_outlined,
                                size: 18),
                      ),
                    ],
                  ),
                  // ── Add error ──
                  if (state is WarehouseUserLoaded &&
                      state.addError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.error_outline,
                              size: 15, color: cs.error),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(state.addError!,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: cs.error)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            // ── User list ──
            if (isLoading && users.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              )
            else if (users.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Ningún colaborador aún.',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final u = users[i];
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: cs.secondary.withValues(alpha: 0.12),
                        child: Text(
                          (u.userName ?? '#${u.userId}')
                              .substring(0, 1)
                              .toUpperCase(),
                          style: TextStyle(
                              color: cs.secondary, fontWeight: FontWeight.w600),
                        ),
                      ),
                      title: Text(u.userName ?? 'Usuario ${u.userId}',
                          style: const TextStyle(fontSize: 13)),
                      subtitle: u.userEmail != null
                          ? Text(u.userEmail!,
                              style: const TextStyle(fontSize: 11))
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Role chip + change
                          if (u.role == 'admin')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: cs.secondary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('Admin',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: cs.secondary,
                                      fontWeight: FontWeight.w600)),
                            )
                          else
                            DropdownButton<String>(
                              value: u.role,
                              underline: const SizedBox(),
                              isDense: true,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: u.role == 'editor'
                                      ? cs.secondary
                                      : cs.onSurfaceVariant),
                              items: const [
                                DropdownMenuItem(
                                    value: 'viewer',
                                    child: Text('Lector')),
                                DropdownMenuItem(
                                    value: 'editor',
                                    child: Text('Editor')),
                              ],
                              onChanged: (newRole) {
                                if (newRole != null && newRole != u.role) {
                                  ctx.read<WarehouseUserCubit>().updateRole(
                                      activeWarehouseId!, u.userId, newRole);
                                }
                              },
                            ),
                          // Remove (only for non-admins)
                          if (u.role != 'admin')
                            IconButton(
                              icon: const Icon(Icons.person_remove_outlined,
                                  size: 18),
                              color: cs.error,
                              tooltip: 'Eliminar',
                              onPressed: () async {
                                final confirm = await showConfirmDialog(
                                  ctx,
                                  title: 'Eliminar colaborador',
                                  message:
                                      '¿Eliminar a "${u.userName ?? u.userEmail ?? 'este colaborador'}" del almacén?',
                                  confirmLabel: 'Eliminar',
                                  isDangerous: true,
                                );
                                if (confirm == true && ctx.mounted) {
                                  ctx
                                      .read<WarehouseUserCubit>()
                                      .removeUser(activeWarehouseId!, u.userId);
                                }
                              },
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  void _doAdd(BuildContext context, WarehouseUserState state) {
    final email = emailCtrl.text.trim();
    if (email.isEmpty) return;
    if (activeWarehouseId == null) return;
    context
        .read<WarehouseUserCubit>()
        .addUserByEmail(activeWarehouseId!, email, selectedRole);
  }
}

class WarehouseListScreen extends StatefulWidget {
  const WarehouseListScreen({super.key});

  @override
  State<WarehouseListScreen> createState() => _WarehouseListScreenState();
}

class _WarehouseListScreenState extends State<WarehouseListScreen> {
  double _fabRight = 16;
  double _fabBottom = 16;
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
    _pageLimit = ((h / 180).ceil() * 2) + 4;
    context.read<WarehouseCubit>().load(FilterParams(limit: _pageLimit));
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      context.read<WarehouseCubit>().loadMore();
    }
    if (pos.pixels <= 200) {
      context.read<WarehouseCubit>().loadPrevious();
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
      title: 'Eliminar almacenes',
      message:
          '¿Eliminar $count ${count == 1 ? 'almacén' : 'almacenes'}? Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      isDangerous: true,
    );
    if (confirm != true || !mounted) return;
    final ids = List<int>.from(_selected);
    setState(() {
      _deleteMode = false;
      _selected.clear();
    });
    context.read<WarehouseCubit>().deleteItems(ids);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Main content ─────────────────────────────────────────────────
          BlocConsumer<WarehouseCubit, WarehouseState>(
            listener: (context, state) {
              if (state is WarehouseActionSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              }
              if (state is WarehouseCreated) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          '"${state.warehouse.name}" creado correctamente')),
                );
              }
              if (state is WarehouseError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(state.message),
                      backgroundColor: Theme.of(context).colorScheme.error),
                );
              }
            },
            builder: (context, state) {
              if (state is WarehouseDeleting) {
                return const LoadingIndicator(message: 'Eliminando…');
              }
              if (state is WarehouseLoading || state is WarehouseInitial) {
                return const LoadingIndicator();
              }
              if (state is WarehouseError) {
                return ErrorView(
                  message: state.message,
                  onRetry: () => context.read<WarehouseCubit>().load(),
                );
              }
              if (state is WarehouseLoaded) {
                final cs = Theme.of(context).colorScheme;
                final authState = context.read<AuthCubit>().state;
                final currentUserId =
                    authState is AuthAuthenticated ? authState.userId : -1;
                final hasOwned = state.warehouses
                    .any((w) => w.ownerId == currentUserId);

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
                            hintText: 'Buscar almacén…',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchCtrl.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      context
                                          .read<WarehouseCubit>()
                                          .search('');
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (q) =>
                              context.read<WarehouseCubit>().search(q),
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
                        onDelete:
                            _selected.isEmpty ? null : _deleteSelected,
                        emptyLabel: 'Selecciona almacenes',
                        selectedSingular: 'almacén seleccionado',
                        selectedPlural: 'almacenes seleccionados',
                      )
                    else if (hasOwned)
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: Icon(Icons.checklist_rounded,
                              color: cs.onSurfaceVariant),
                          tooltip: 'Seleccionar para borrar',
                          onPressed: () =>
                              setState(() => _deleteMode = true),
                        ),
                      ),
                    // ── Grid ──
                    Expanded(
                      child: state.warehouses.isEmpty
                          ? EmptyView(
                              message: _searchCtrl.text.isNotEmpty
                                  ? 'Sin resultados para "${_searchCtrl.text}"'
                                  : 'No tienes almacenes aún',
                              actionLabel: _searchCtrl.text.isEmpty
                                  ? 'Crear almacén'
                                  : null,
                              onAction: _searchCtrl.text.isEmpty
                                  ? () => showWarehouseDialog(context)
                                  : null,
                            )
                          : RefreshIndicator(
                        onRefresh: () {
                          _searchCtrl.clear();
                          return context
                              .read<WarehouseCubit>()
                              .load(FilterParams(limit: _pageLimit));
                        },
                        child: GridView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding:
                              const EdgeInsets.fromLTRB(16, 4, 16, 96),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.2 /
                                MediaQuery.textScalerOf(context)
                                    .scale(1.0)
                                    .clamp(
                                      (390.0 /
                                              MediaQuery.sizeOf(context)
                                                  .width)
                                          .clamp(0.8, 2.5),
                                      double.infinity,
                                    ),
                          ),
                          itemCount: state.warehouses.length,
                          itemBuilder: (context, i) {
                            final w = state.warehouses[i];
                            final isOwner = w.ownerId == currentUserId;
                            final isSelected = _selected.contains(w.id);
                            return _WarehouseGridCard(
                              warehouse: w,
                              isSelected: isSelected && _deleteMode,
                              onTap: _deleteMode
                                  ? (isOwner
                                      ? () => _toggleSelect(w.id)
                                      : null)
                                  : () => context.openAuxiliaryRoute(
                                        '/warehouses/${w.id}/detail',
                                      ),
                              onEdit: _deleteMode || !isOwner
                                  ? null
                                  : () => showWarehouseDialog(context,
                                      warehouseId: w.id),
                              onDelete: _deleteMode || !isOwner
                                  ? null
                                  : () async {
                                      final confirm = await showConfirmDialog(
                                        context,
                                        title: 'Eliminar almacén',
                                        message:
                                            '¿Estás seguro de que quieres eliminar "${w.name}"? Esta acción no se puede deshacer.',
                                        confirmLabel: 'Eliminar',
                                        isDangerous: true,
                                      );
                                      if (confirm == true &&
                                          context.mounted) {
                                        context
                                            .read<WarehouseCubit>()
                                            .delete(w.id);
                                      }
                                    },
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
          ),

          // ── Draggable FAB ─────────────────────────────────────────────────
          if (!_deleteMode)
            Positioned(
              right: _fabRight,
              bottom: _fabBottom,
              child: GestureDetector(
                onPanUpdate: (details) {
                  final size = MediaQuery.sizeOf(context);
                  setState(() {
                    _fabRight = (_fabRight - details.delta.dx)
                        .clamp(0, size.width - 140);
                    _fabBottom = (_fabBottom - details.delta.dy)
                        .clamp(0, size.height - 60);
                  });
                },
                child: FloatingActionButton.extended(
                  heroTag: 'warehouse_fab',
                  onPressed: () => showWarehouseDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Crear'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Warehouse grid card ──────────────────────────────────────────────────────
class _WarehouseGridCard extends StatelessWidget {
  final WarehouseModel warehouse;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _WarehouseGridCard({
    required this.warehouse,
    this.isSelected = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.hardEdge,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: isSelected
            ? BorderSide(color: cs.error, width: 1.5)
            : BorderSide.none,
      ),
      color: isSelected ? cs.errorContainer : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: cs.primaryContainer, shape: BoxShape.circle),
                    child: Icon(Icons.warehouse_outlined,
                        color: cs.secondary, size: 20),
                  ),
                  const Spacer(),
                  if (isSelected)
                    Icon(Icons.check_circle,
                        color: cs.error, size: 20)
                  else if (onEdit != null || onDelete != null)
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        iconSize: 18,
                        onSelected: (v) {
                          if (v == 'edit') onEdit?.call();
                          if (v == 'delete') onDelete?.call();
                        },
                        itemBuilder: (_) => [
                          if (onEdit != null)
                            const PopupMenuItem(
                                value: 'edit', child: Text('Editar')),
                          if (onDelete != null)
                            const PopupMenuItem(
                                value: 'delete', child: Text('Eliminar')),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                warehouse.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.secondary),
              ),
              if (warehouse.productCount != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '${warehouse.productCount} ${warehouse.productCount == 1 ? 'producto' : 'productos'}',
                    style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                  ),
                ),
              if (warehouse.isShared)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Compartido',
                    style: TextStyle(
                        fontSize: 10,
                        color: cs.secondary,
                        fontWeight: FontWeight.w500),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
