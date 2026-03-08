import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/router/app_router.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/notification/notification_cubit.dart';
import '../../cubits/product_list/product_list_cubit.dart';
import '../../widgets/confirm_dialog.dart';
import '../brands/brand_list_screen.dart';
import '../stores/store_list_screen.dart';
import '../warehouses/warehouse_list_screen.dart';
import 'app_drawer.dart';

const _appBarBg = Color(0xFF3C096C);

class AppShell extends StatefulWidget {
  final Widget child;
  final String currentLocation;

  const AppShell({
    super.key,
    required this.child,
    required this.currentLocation,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  void initState() {
    super.initState();
    BackButtonInterceptor.add(_onBackPressed, context: context);
  }

  @override
  void dispose() {
    BackButtonInterceptor.remove(_onBackPressed);
    super.dispose();
  }

  Future<bool> _onBackPressed(bool stopDefaultButtonEvent, RouteInfo info) async {
    if (!mounted || stopDefaultButtonEvent) return false;
    if (info.ifRouteChanged(context)) return false;
    if (!shellRootRoutes.contains(widget.currentLocation)) return false;

    if (context.canPop()) {
      context.pop();
      return true;
    }

    final shouldExit = await showConfirmDialog(
      context,
      title: 'Salir de InvesVault',
      message: '¿Quieres cerrar la aplicación?',
      confirmLabel: 'Salir',
      cancelLabel: 'Cancelar',
      isDangerous: true,
    );
    if (shouldExit == true) {
      await SystemNavigator.pop();
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final title = _titleFor(widget.currentLocation);

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          enterAuthFlow(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: _appBarBg,
          foregroundColor: Colors.white,
          title: Text(title,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            // Context-sensitive add button
            if (widget.currentLocation == '/warehouses')
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Nuevo almacén',
                onPressed: () => showWarehouseDialog(context),
              )
            else if (widget.currentLocation == '/products')
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Nuevo producto',
                onPressed: () async {
                  await context.openAuxiliaryRoute('/products/new');
                  if (context.mounted) {
                    context.read<ProductListCubit>().load();
                  }
                },
              )
            else if (widget.currentLocation == '/stores')
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Nueva tienda',
                onPressed: () => showStoreDialog(context),
              )
            else if (widget.currentLocation == '/brands')
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Nueva marca',
                onPressed: () => showBrandDialog(context),
              ),

            // Notifications
            BlocBuilder<NotificationCubit, NotificationState>(
              builder: (context, state) {
                final count =
                    state is NotificationLoaded ? state.unreadCount : 0;
                return Badge(
                  label: count > 0 ? Text('$count') : null,
                  isLabelVisible: count > 0,
                  child: IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () =>
                        context.openAuxiliaryRoute('/notifications'),
                    tooltip: 'Notificaciones',
                  ),
                );
              },
            ),
          ],
        ),
        drawer: const AppDrawer(),
        body: widget.child,
      ),
    );
  }

  String _titleFor(String path) {
    if (path.startsWith('/warehouses/') && path.contains('/detail')) {
      return 'Detalle de almacén';
    }
    const titles = {
      '/dashboard': 'Inicio',
      '/warehouses': 'Almacenes',
      '/stores': 'Tiendas',
      '/brands': 'Marcas',
      '/products': 'Inventario',
      '/shopping-list': 'Lista de compra',
      '/stock-history': 'Historial de cambios',
      '/settings': 'Ajustes',
    };
    for (final entry in titles.entries) {
      if (path.startsWith(entry.key)) return entry.value;
    }
    return 'InvesVault';
  }
}
