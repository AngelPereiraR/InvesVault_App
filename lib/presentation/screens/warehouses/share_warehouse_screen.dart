import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/warehouse_user/warehouse_user_cubit.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_indicator.dart';
import '../../../core/utils/validators.dart';

class ShareWarehouseScreen extends StatefulWidget {
  final int warehouseId;
  const ShareWarehouseScreen({super.key, required this.warehouseId});

  @override
  State<ShareWarehouseScreen> createState() => _ShareWarehouseScreenState();
}

class _ShareWarehouseScreenState extends State<ShareWarehouseScreen> {
  final _userIdCtrl = TextEditingController();
  String _selectedRole = 'viewer';

  @override
  void initState() {
    super.initState();
    context.read<WarehouseUserCubit>().load(widget.warehouseId);
  }

  @override
  void dispose() {
    _userIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WarehouseUserCubit, WarehouseUserState>(
      listener: (context, state) {
        if (state is WarehouseUserActionSuccess) {
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
        return Scaffold(
          appBar: AppBar(title: const Text('Compartir almacén')),
          body: Column(
            children: [
              // Add user form
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Añadir usuario',
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _userIdCtrl,
                          label: 'ID de usuario',
                          keyboardType: TextInputType.number,
                          validator: Validators.positiveNumber,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _selectedRole,
                          decoration:
                              const InputDecoration(labelText: 'Rol'),
                          items: const [
                            DropdownMenuItem(
                                value: 'viewer', child: Text('Solo lectura')),
                            DropdownMenuItem(
                                value: 'editor', child: Text('Editor')),
                          ],
                          onChanged: (v) =>
                              setState(() => _selectedRole = v!),
                        ),
                        const SizedBox(height: 16),
                        AppButton(
                          label: 'Añadir',
                          loading: state is WarehouseUserLoading,
                          onPressed: () {
                            final id =
                                int.tryParse(_userIdCtrl.text.trim());
                            if (id == null) return;
                            context.read<WarehouseUserCubit>().addUser(
                                widget.warehouseId, id, _selectedRole);
                            _userIdCtrl.clear();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Users list
              Expanded(
                child: state is WarehouseUserLoading
                    ? const LoadingIndicator()
                    : state is WarehouseUserError
                        ? ErrorView(message: state.message)
                        : state is WarehouseUserLoaded &&
                                state.users.isEmpty
                            ? const EmptyView(
                                message: 'No hay usuarios compartidos')
                            : state is WarehouseUserLoaded
                                ? ListView.builder(
                                    itemCount: state.users.length,
                                    itemBuilder: (context, i) {
                                      final u = state.users[i];
                                      return ListTile(
                                        leading: const CircleAvatar(
                                            child: Icon(Icons.person)),
                                        title: Text(
                                            u.userName ?? 'Usuario ${u.userId}'),
                                        subtitle: Text(u.userEmail ?? ''),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
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
                                              onChanged: (role) {
                                                if (role != null) {
                                                  context
                                                      .read<WarehouseUserCubit>()
                                                      .updateRole(
                                                          widget.warehouseId,
                                                          u.userId,
                                                          role);
                                                }
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.person_remove,
                                                  color: Colors.red),
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
                                                      .read<
                                                          WarehouseUserCubit>()
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
          ),
        );
      },
    );
  }
}
