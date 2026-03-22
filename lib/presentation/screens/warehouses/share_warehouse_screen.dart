import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/warehouse_user/warehouse_user_cubit.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_indicator.dart';

class ShareWarehouseScreen extends StatefulWidget {
  final int warehouseId;
  const ShareWarehouseScreen({super.key, required this.warehouseId});

  @override
  State<ShareWarehouseScreen> createState() => _ShareWarehouseScreenState();
}

class _ShareWarehouseScreenState extends State<ShareWarehouseScreen> {
  final _emailCtrl = TextEditingController();
  String _selectedRole = 'viewer';

  @override
  void initState() {
    super.initState();
    context.read<WarehouseUserCubit>().load(widget.warehouseId);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _add() {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    context
        .read<WarehouseUserCubit>()
        .addUserByEmail(widget.warehouseId, email, _selectedRole);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WarehouseUserCubit, WarehouseUserState>(
      listener: (context, state) {
        if (state is WarehouseUserActionSuccess) {
          _emailCtrl.clear();
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
        if (state is WarehouseUserError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error));
        }
      },
      builder: (context, state) {
        final loaded =
            state is WarehouseUserLoaded ? state : null;

        // Determine if the current user is admin of this warehouse.
        // This comes directly from the loaded user list – no dependency
        // on WarehouseCubit (which may not be populated when arriving
        // from the Dashboard).
        final authState = context.read<AuthCubit>().state;
        final currentUserId =
            authState is AuthAuthenticated ? authState.userId : -1;
        final isAdmin = loaded != null &&
            loaded.users.any(
                (u) => u.userId == currentUserId && u.role == 'admin');

        final cs = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(title: const Text('Compartir almacén')),
          body: SafeArea(top: false, child: Column(
            children: [
// ── Add by email (admin only) ──
              if (isAdmin)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Añadir colaborador',
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: _emailCtrl,
                                label: 'Email del usuario',
                                keyboardType: TextInputType.emailAddress,
                                onFieldSubmitted: (_) => _add(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            DropdownButton<String>(
                              value: _selectedRole,
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
                              onChanged: (v) =>
                                  setState(() => _selectedRole = v ?? 'viewer'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                  backgroundColor: cs.secondary,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 14)),
                              onPressed:
                                  loaded.isAdding ? null : _add,
                              child: loaded.isAdding
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: cs.onPrimary))
                                  : const Icon(
                                      Icons.person_add_outlined, size: 18),
                            ),
                          ],
                        ),
                        if (loaded.addError != null) ...[  
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 15, color: cs.error),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  loaded.addError!,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: cs.error),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // ── Users list ──
              Expanded(
                child: state is WarehouseUserLoading
                    ? const LoadingIndicator()
                    : state is WarehouseUserError
                        ? ErrorView(message: state.message)
                        : loaded != null && loaded.users.isEmpty
                            ? const EmptyView(
                                message: 'No hay usuarios compartidos')
                            : loaded != null
                                ? ListView.builder(
                                    itemCount: loaded.users.length,
                                    itemBuilder: (context, i) {
                                      final u = loaded.users[i];
                                      return ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor:
                                              cs.secondary.withValues(alpha: 0.12),
                                          child: Text(
                                            (u.userName ?? '#${u.userId}')
                                                .substring(0, 1)
                                                .toUpperCase(),
                                            style: TextStyle(
                                                color: cs.secondary,
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                        title: Text(
                                            u.userName ?? 'Usuario ${u.userId}'),
                                        subtitle: Text(u.userEmail ?? ''),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (u.role == 'admin')
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: cs.secondary.withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text('Admin',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color: cs.secondary,
                                                        fontWeight:
                                                            FontWeight.w600)),
                                              )
                                            else
                                              DropdownButton<String>(
                                                value: u.role,
                                                underline: const SizedBox(),
                                                items: const [
                                                  DropdownMenuItem(
                                                      value: 'viewer',
                                                      child: Text('Lector')),
                                                  DropdownMenuItem(
                                                      value: 'editor',
                                                      child: Text('Editor')),
                                                ],
                                                onChanged: isAdmin ? (role) {
                                                  if (role != null) {
                                                    context
                                                        .read<WarehouseUserCubit>()
                                                        .updateRole(
                                                            widget.warehouseId,
                                                            u.userId,
                                                            role);
                                                  }
                                                } : null,
                                              ),
                                            if (u.role != 'admin' && isAdmin)
                                              IconButton(
                                                icon: Icon(
                                                    Icons.person_remove,
                                                    color: cs.error),
                                                onPressed: () async {
                                                  final confirm =
                                                      await showConfirmDialog(
                                                    context,
                                                    title: 'Eliminar usuario',
                                                    message:
                                                        '¿Eliminar acceso de ${u.userName ?? 'este usuario'}?',
                                                    confirmLabel: 'Eliminar',
                                                    isDangerous: true,
                                                  );
                                                  if (confirm == true &&
                                                      context.mounted) {
                                                    context
                                                        .read<WarehouseUserCubit>()
                                                        .removeUser(
                                                            widget.warehouseId,
                                                            u.userId);
                                                  }
                                                },
                                              ),
                                          ],
                                        ),
                                      );
                                    },
                                  )
                                : const SizedBox(),
              ),
            ],
          )),
        );
      },
    );
  }
}

