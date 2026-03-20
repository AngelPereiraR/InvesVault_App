import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/auth/auth_cubit.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../../core/utils/validators.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      _nameCtrl.text = authState.name;
      _emailCtrl.text = authState.email;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return;
    context.read<AuthCubit>().updateUser({
      'name': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perfil actualizado')),
          );
        }
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error),
          );
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Perfil de usuario',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  AppTextField(
                    controller: _nameCtrl,
                    label: 'Nombre',
                    prefixIcon: const Icon(Icons.person_outlined),
                    validator: Validators.required,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _emailCtrl,
                    label: 'Correo electrónico',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined),
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 24),
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) => AppButton(
                      label: 'Guardar cambios',
                      loading: state is AuthLoading,
                      onPressed: _saveProfile,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // About
            Text('Acerca de',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('InvesVault'),
              subtitle: Text('Versión 1.0.6'),
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            AppButton(
              label: 'Cerrar sesión',
              variant: AppButtonVariant.danger,
              icon: Icons.logout,
              onPressed: () => context.read<AuthCubit>().logout(),
            ),
          ],
        ),
      ),
    );
  }
}
