import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/router/app_router.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/warehouse/warehouse_cubit.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/warehouse_model.dart';

class WarehouseFormScreen extends StatefulWidget {
  final int? warehouseId;
  const WarehouseFormScreen({super.key, this.warehouseId});

  @override
  State<WarehouseFormScreen> createState() => _WarehouseFormScreenState();
}

class _WarehouseFormScreenState extends State<WarehouseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  bool _isShared = false;
  WarehouseModel? _existing;

  bool get isEdit => widget.warehouseId != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final state = context.read<WarehouseCubit>().state;
      if (state is WarehouseLoaded) {
        _existing = state.warehouses
            .firstWhere((w) => w.id == widget.warehouseId);
        _nameCtrl.text = _existing?.name ?? '';
        _isShared = _existing?.isShared ?? false;
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final authState = context.read<AuthCubit>().state;
    final userId =
        authState is AuthAuthenticated ? authState.userId : 0;

    if (isEdit) {
      context.read<WarehouseCubit>().update(
          widget.warehouseId!, {'name': _nameCtrl.text.trim(), 'is_shared': _isShared});
    } else {
      context
          .read<WarehouseCubit>()
          .create(name: _nameCtrl.text.trim(), ownerId: userId, isShared: _isShared);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WarehouseCubit, WarehouseState>(
      listener: (context, state) {
        if (state is WarehouseActionSuccess) context.pop();
        if (state is WarehouseError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
            title: Text(isEdit ? 'Editar almacén' : 'Nuevo almacén')),
        body: SafeArea(
          top: false,
          child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                AppTextField(
                  controller: _nameCtrl,
                  label: 'Nombre del almacén',
                    validator: Validators.required,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Almacén compartido'),
                  subtitle: const Text(
                      'Permite que otros usuarios accedan a este almacén'),
                  value: _isShared,
                  onChanged: (v) => setState(() => _isShared = v),
                ),
                const SizedBox(height: 32),
                BlocBuilder<WarehouseCubit, WarehouseState>(
                  builder: (context, state) => AppButton(
                    label: isEdit ? 'Guardar cambios' : 'Crear almacén',
                    loading: state is WarehouseLoading,
                    onPressed: _save,
                  ),
                ),
              ],
            ),
          ),
        )),
      ),
    );
  }
}
