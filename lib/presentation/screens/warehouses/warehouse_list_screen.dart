import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/warehouse/warehouse_cubit.dart';
import '../../cubits/warehouse_user/warehouse_user_cubit.dart';
import '../../../data/models/warehouse_user_model.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/warehouse_card.dart';
import '../../../core/utils/validators.dart';

const _purple = Color(0xFF3C096C);

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
                  color: _purple,
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          isEdit ? 'Editar almacén' : 'Nuevo almacén',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                // ── Tabs ──────────────────────────────────────────────
                Theme(
                  data: Theme.of(context).copyWith(
                    tabBarTheme: const TabBarThemeData(
                      labelColor: _purple,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: _purple,
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
                                  color: Colors.grey.shade400),
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
                                        backgroundColor: _purple),
                                    child: loading
                                        ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white))
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
                                      color: Colors.grey.shade500),
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
    if (activeWarehouseId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline,
                  size: 40, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                'Crea el almacén primero para gestionar colaboradores.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return BlocBuilder<WarehouseUserCubit, WarehouseUserState>(
      builder: (context, state) {
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
                        style: const TextStyle(
                            fontSize: 13, color: _purple),
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
                            backgroundColor: _purple,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14)),
                        onPressed: state is WarehouseUserLoaded &&
                                state.isAdding
                            ? null
                            : () => _doAdd(context, state),
                        child: state is WarehouseUserLoaded &&
                                state.isAdding
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
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
                              size: 15, color: Colors.red.shade400),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(state.addError!,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red.shade400)),
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
                  style: TextStyle(color: Colors.grey.shade500),
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
                        backgroundColor: _purple.withOpacity(0.12),
                        child: Text(
                          (u.userName ?? '#${u.userId}')
                              .substring(0, 1)
                              .toUpperCase(),
                          style: const TextStyle(
                              color: _purple, fontWeight: FontWeight.w600),
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
                                color: _purple.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('Admin',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: _purple,
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
                                      ? _purple
                                      : Colors.grey.shade600),
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
                              color: Colors.red.shade400,
                              tooltip: 'Eliminar',
                              onPressed: () => ctx
                                  .read<WarehouseUserCubit>()
                                  .removeUser(activeWarehouseId!, u.userId),
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
  @override
  void initState() {
    super.initState();
    context.read<WarehouseCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showWarehouseDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo almacén'),
      ),
      body: BlocConsumer<WarehouseCubit, WarehouseState>(
        listener: (context, state) {
          if (state is WarehouseActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
          if (state is WarehouseCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('"${state.warehouse.name}" creado correctamente')),
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
          if (state is WarehouseLoading || state is WarehouseInitial) {
            return const LoadingIndicator();
          }
          if (state is WarehouseError) {
            return ErrorView(
              message: state.message,
              onRetry: () => context.read<WarehouseCubit>().load(),
            );
          }
          if (state is WarehouseLoaded && state.warehouses.isEmpty) {
            return EmptyView(
              message: 'No tienes almacenes aún',
              actionLabel: 'Crear almacén',
              onAction: () => showWarehouseDialog(context),
            );
          }
          if (state is WarehouseLoaded) {
            final authState = context.read<AuthCubit>().state;
            final currentUserId =
                authState is AuthAuthenticated ? authState.userId : -1;
            return RefreshIndicator(
              onRefresh: () => context.read<WarehouseCubit>().load(),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.warehouses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final w = state.warehouses[i];
                  final isOwner = w.ownerId == currentUserId;
                  return WarehouseCard(
                    warehouse: w,
                    onTap: () =>
                        context.push('/warehouses/${w.id}/detail'),
                    onEdit: isOwner
                        ? () => showWarehouseDialog(context, warehouseId: w.id)
                        : null,
                    onDelete: isOwner
                        ? () async {
                            final confirm = await showConfirmDialog(
                              context,
                              title: 'Eliminar almacén',
                              message:
                                  '¿Estás seguro de que quieres eliminar "${w.name}"? Esta acción no se puede deshacer.',
                              confirmLabel: 'Eliminar',
                              isDangerous: true,
                            );
                            if (confirm == true && context.mounted) {
                              context.read<WarehouseCubit>().delete(w.id);
                            }
                          }
                        : null,
                  );
                },
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}
