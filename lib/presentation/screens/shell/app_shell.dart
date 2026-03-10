import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/router/app_router.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/notification/notification_cubit.dart';
import '../../cubits/product_list/product_list_cubit.dart';
import '../../cubits/shopping_list/shopping_list_cubit.dart';
import '../../cubits/warehouse/warehouse_cubit.dart';
import '../../cubits/warehouse_detail/warehouse_detail_cubit.dart';
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

  Future<void> _showGenerateShoppingListDialog(BuildContext ctx) async {
    final warehouseState = ctx.read<WarehouseCubit>().state;
    if (warehouseState is! WarehouseLoaded ||
        warehouseState.warehouses.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
          content: Text('No hay almacenes disponibles'),
          duration: Duration(seconds: 2)));
      return;
    }

    int? selectedId;
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dCtx) => StatefulBuilder(
        builder: (dCtx, setInner) => AlertDialog(
          title: const Text('Generar lista de compra',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Selecciona el almacén o genera para todos:',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: selectedId,
                decoration: const InputDecoration(
                  labelText: 'Almacén',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<int>(
                      value: -1, child: Text('Todos los almacenes')),
                  ...warehouseState.warehouses.map((w) =>
                      DropdownMenuItem<int>(value: w.id, child: Text(w.name))),
                ],
                onChanged: (v) => setInner(() => selectedId = v),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(dCtx).pop(false),
                child: const Text('Cancelar')),
            FilledButton(
              onPressed: selectedId == null
                  ? null
                  : () => Navigator.of(dCtx).pop(true),
              child: const Text('Generar'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || selectedId == null || !ctx.mounted) return;

    if (selectedId == -1) {
      await ctx.read<ShoppingListCubit>().generateAll();
    } else {
      await ctx.read<ShoppingListCubit>().generate(selectedId!);
    }

    if (ctx.mounted) navigateToShellSection(ctx, '/shopping-list');
  }

  @override
  Widget build(BuildContext context) {
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
          title: _buildAppBarTitle(context),
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
            else if (widget.currentLocation == '/stores') ...[              
              IconButton(
                icon: const Icon(Icons.auto_awesome),
                tooltip: 'Generar lista de compra',
                onPressed: () => _showGenerateShoppingListDialog(context),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Nueva tienda',
                onPressed: () => showStoreDialog(context),
              ),
            ]
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
        body: SafeArea(top: false, child: widget.child),
      ),
    );
  }

  Widget _buildAppBarTitle(BuildContext context) {
    const style = TextStyle(color: Colors.white, fontWeight: FontWeight.w600);
    if (widget.currentLocation.contains('/detail') &&
        widget.currentLocation.startsWith('/warehouses/')) {
      return BlocBuilder<WarehouseDetailCubit, WarehouseDetailState>(
        builder: (_, state) {
          final name = state is WarehouseDetailLoaded
              ? state.warehouse.name
              : 'Almacén';
          return Text(name, style: style);
        },
      );
    }
    return Text(_titleFor(widget.currentLocation), style: style);
  }

  String _titleFor(String path) {
    const titles = {
      '/dashboard': 'Inicio',
      '/warehouses': 'Inventario',
      '/stores': 'Tiendas',
      '/brands': 'Marcas',
      '/products': 'Catálogo',
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
