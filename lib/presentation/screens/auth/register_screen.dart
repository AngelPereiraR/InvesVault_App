import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/router/app_router.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../widgets/confirm_dialog.dart';
import '../../../core/utils/validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _acceptTerms = false;

  @override
  void initState() {
    super.initState();
    BackButtonInterceptor.add(_onBackPressed, context: context);
  }

  @override
  void dispose() {
    BackButtonInterceptor.remove(_onBackPressed);
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<bool> _onBackPressed(bool stopDefaultButtonEvent, RouteInfo info) async {
    if (!mounted || stopDefaultButtonEvent) return false;
    if (info.ifRouteChanged(context)) return false;
    final shouldGoBack = await showConfirmDialog(
      context,
      title: 'Volver al login',
      message: '¿Quieres volver a la pantalla de acceso?',
      confirmLabel: 'Volver',
    );
    if (shouldGoBack == true && mounted) {
      replaceWithAuthRoute(context, '/login');
    }
    return true;
  }

  void _submit() {
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes aceptar los términos y condiciones'),
        ),
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<AuthCubit>().register(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          enterMainShell(context);
        }
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: cs.error,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: cs.surface,
        body: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        color: cs.secondary,
                        size: 20,
                      ),
                      onPressed: () => replaceWithAuthRoute(context, '/login'),
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child:
                          Image.asset('assets/logo.png', width: 80, height: 80),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'InvesVault',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: cs.secondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Card(
                      color: cs.surface,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Column(
                                  children: [
                                    Text(
                                      'Crear cuenta',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: cs.secondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Únete a InvesVault hoy mismo',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: cs.secondary.withValues(alpha: 0.6),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                ),
                              ),
                              _Field(
                                controller: _nameCtrl,
                                label: 'Nombre completo',
                                icon: Icons.person_outlined,
                                validator: Validators.required,
                              ),
                              const SizedBox(height: 14),
                              _Field(
                                controller: _emailCtrl,
                                label: 'Correo electrónico',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: Validators.email,
                              ),
                              const SizedBox(height: 14),
                              _Field(
                                controller: _passwordCtrl,
                                label: 'Contraseña',
                                icon: Icons.lock_outlined,
                                obscureText: _obscurePass,
                                validator: Validators.password,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscurePass
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: cs.secondary.withValues(alpha: 0.6),
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePass = !_obscurePass,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _Field(
                                controller: _confirmCtrl,
                                label: 'Confirmar contraseña',
                                icon: Icons.lock_outlined,
                                obscureText: _obscureConfirm,
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Campo obligatorio';
                                  }
                                  if (v != _passwordCtrl.text) {
                                    return 'Las contraseñas no coinciden';
                                  }
                                  return null;
                                },
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscureConfirm
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: cs.secondary.withValues(alpha: 0.6),
                                  ),
                                  onPressed: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Checkbox(
                                    value: _acceptTerms,
                                    activeColor: cs.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    onChanged: (v) => setState(
                                      () => _acceptTerms = v ?? false,
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(
                                        () => _acceptTerms = !_acceptTerms,
                                      ),
                                      child: Text(
                                        'Acepto los términos y condiciones',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: cs.secondary.withValues(alpha: 0.8),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              BlocBuilder<AuthCubit, AuthState>(
                                builder: (context, state) {
                                  final cs = Theme.of(context).colorScheme;
                                  return SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: cs.secondary,
                                        foregroundColor: cs.onPrimary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        elevation: 0,
                                        textStyle: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      onPressed:
                                          state is AuthLoading ? null : _submit,
                                      child: state is AuthLoading
                                          ? SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: cs.onPrimary,
                                              ),
                                            )
                                          : const Text('Registrar'),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        style: TextButton.styleFrom(foregroundColor: cs.secondary),
                        onPressed: () =>
                            replaceWithAuthRoute(context, '/login'),
                        child: const Text(
                          '¿Ya tienes cuenta? Inicia sesión',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4, right: 4),
                  child: IconButton(
                    icon: Icon(
                      Icons.settings_outlined,
                      color: cs.secondary.withValues(alpha: 0.7),
                    ),
                    tooltip: 'Ajustes',
                    onPressed: () {},
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable field widget ────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final Widget? suffix;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.validator,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: TextStyle(color: cs.secondary, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: cs.secondary.withValues(alpha: 0.7), fontSize: 14),
        filled: true,
        fillColor: cs.primaryContainer,
        prefixIcon: Icon(icon, color: cs.secondary.withValues(alpha: 0.7), size: 22),
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.secondary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.error, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }
}
