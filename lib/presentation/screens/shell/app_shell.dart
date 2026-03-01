import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/notification/notification_cubit.dart';
import '../stores/store_list_screen.dart';
import '../warehouses/warehouse_list_screen.dart';
import 'app_drawer.dart';

const _appBarBg = Color(0xFF3C096C);

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final title = _titleFor(location);

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go('/login');
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
            if (location == '/warehouses')
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Nuevo almacén',
                onPressed: () => showWarehouseDialog(context),
              )
            else if (location == '/products')
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Nuevo producto',
                onPressed: () => context.push('/products/new'),
              )
            else if (location == '/stores')
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Nueva tienda',
                onPressed: () => showStoreDialog(context),
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
                    onPressed: () => context.push('/notifications'),
                    tooltip: 'Notificaciones',
                  ),
                );
              },
            ),
          ],
        ),
        drawer: const AppDrawer(),
        body: child,
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
