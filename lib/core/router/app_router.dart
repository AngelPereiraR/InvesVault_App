import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/cubits/auth/auth_cubit.dart';
import '../../presentation/widgets/confirm_dialog.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/auth/splash_screen.dart';
import '../../presentation/screens/auth/welcome_screen.dart';
import '../../presentation/screens/dashboard/dashboard_screen.dart';
import '../../presentation/screens/notifications/notification_list_screen.dart';
import '../../presentation/screens/products/barcode_scanner_screen.dart';
import '../../presentation/screens/products/product_detail_screen.dart';
import '../../presentation/screens/products/product_form_screen.dart';
import '../../presentation/screens/products/product_list_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/shell/app_shell.dart';
import '../../presentation/screens/shopping_list/shopping_list_screen.dart';
import '../../presentation/screens/stock_change/stock_change_history_screen.dart';
import '../../presentation/screens/warehouses/share_warehouse_screen.dart';
import '../../presentation/screens/warehouses/warehouse_detail_screen.dart';
import '../../presentation/screens/warehouses/warehouse_form_screen.dart';
import '../../presentation/screens/products/search_screen.dart';
import '../../presentation/screens/brands/brand_list_screen.dart';
import '../../presentation/screens/stores/store_list_screen.dart';
import '../../presentation/screens/warehouses/warehouse_list_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _dashboardNavigatorKey = GlobalKey<NavigatorState>();
final _warehousesNavigatorKey = GlobalKey<NavigatorState>();
final _productsNavigatorKey = GlobalKey<NavigatorState>();
final _brandsNavigatorKey = GlobalKey<NavigatorState>();
final _storesNavigatorKey = GlobalKey<NavigatorState>();
final _stockHistoryNavigatorKey = GlobalKey<NavigatorState>();
final _shoppingListNavigatorKey = GlobalKey<NavigatorState>();
final _settingsNavigatorKey = GlobalKey<NavigatorState>();

GlobalKey<NavigatorState> get rootNavigatorKey => _rootNavigatorKey;

const _shellBranchRoutes = [
  '/dashboard',
  '/warehouses',
  '/products',
  '/brands',
  '/stores',
  '/stock-history',
  '/shopping-list',
  '/settings',
];

class ShellSectionHistory {
  ShellSectionHistory._();

  static final ShellSectionHistory instance = ShellSectionHistory._();

  final List<String> _routes = [];

  void visit(String route) {
    _routes.remove(route);
    _routes.add(route);
  }

  String? previousOf(String currentRoute) {
    if (_routes.isEmpty) return null;
    if (_routes.last != currentRoute) {
      visit(currentRoute);
    }
    if (_routes.length < 2) return null;
    _routes.removeLast();
    return _routes.last;
  }

  void resetTo(String route) {
    _routes
      ..clear()
      ..add(route);
  }
}

int? _branchIndexForRoute(String route) {
  final index = _shellBranchRoutes.indexOf(route);
  return index == -1 ? null : index;
}

String _branchRouteAt(int index) => _shellBranchRoutes[index];

void navigateToShellRoot(BuildContext context, String route) {
  final branchIndex = _branchIndexForRoute(route);
  if (branchIndex == null) {
    context.go(route);
    return;
  }

  final shellState = StatefulNavigationShell.maybeOf(context);
  if (shellState == null) {
    context.go(route);
    return;
  }

  ShellSectionHistory.instance.visit(route);
  shellState.goBranch(branchIndex, initialLocation: true);
}

Future<void> _showBlockedExitDialog(
  BuildContext context, {
  required String message,
}) async {
  await showConfirmDialog(
    context,
    title: 'Salir de InvesVault',
    message: message,
    confirmLabel: 'Entendido',
    cancelLabel: 'Cancelar',
  );
}

Future<void> _handleRegisterBlockedPop(BuildContext context) async {
  final shouldGoBack = await showConfirmDialog(
    context,
    title: 'Volver al login',
    message: '¿Quieres volver a la pantalla de acceso?',
    confirmLabel: 'Volver',
  );

  if (shouldGoBack == true && context.mounted) {
    context.go('/login');
  }
}

Future<void> _handleShellRootBlockedPop(
  BuildContext context,
  int currentBranchIndex,
) async {
  final currentRoute = _branchRouteAt(currentBranchIndex);
  final previousRoute = ShellSectionHistory.instance.previousOf(currentRoute);
  if (previousRoute != null) {
    navigateToShellRoot(context, previousRoute);
    return;
  }

  await _showBlockedExitDialog(
    context,
    message:
        'Ya estás en la última pantalla. Usa el selector del sistema para salir si lo necesitas.',
  );
}

Page<void> _blockedPopPage({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
  required Future<void> Function(BuildContext context) onBlockedPop,
}) {
  return MaterialPage<void>(
    key: state.pageKey,
    name: state.uri.toString(),
    arguments: state.extra,
    canPop: false,
    onPopInvoked: (didPop, _) {
      if (didPop) return;
      unawaited(onBlockedPop(context));
    },
    child: child,
  );
}

Page<void> _blockedShellPage({
  required BuildContext context,
  required GoRouterState state,
  required StatefulNavigationShell navigationShell,
}) {
  return MaterialPage<void>(
    key: state.pageKey,
    name: state.uri.toString(),
    canPop: false,
    onPopInvoked: (didPop, _) {
      if (didPop) return;
      unawaited(
        _handleShellRootBlockedPop(context, navigationShell.currentIndex),
      );
    },
    child: AppShell(
      navigationShell: navigationShell,
      currentLocation: state.uri.path,
    ),
  );
}

GoRouter buildRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final authState = context.read<AuthCubit>().state;
      final isSplash = state.matchedLocation == '/splash';
      final isAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/welcome';

      if (isSplash) return null;
      if (authState is AuthUnauthenticated && !isAuth) return '/login';
      if (authState is AuthAuthenticated && isAuth) {
        ShellSectionHistory.instance.resetTo('/dashboard');
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        pageBuilder: (context, state) => _blockedPopPage(
          context: context,
          state: state,
          onBlockedPop: (context) => _showBlockedExitDialog(
            context,
            message: 'Ya estás en la pantalla de bienvenida.',
          ),
          child: const WelcomeScreen(),
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _blockedPopPage(
          context: context,
          state: state,
          onBlockedPop: (context) => _showBlockedExitDialog(
            context,
            message: 'Ya estás en la pantalla inicial de acceso.',
          ),
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => _blockedPopPage(
          context: context,
          state: state,
          onBlockedPop: _handleRegisterBlockedPop,
          child: const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationListScreen(),
      ),

      // ── Detail / form routes (rendered above the shell, own AppBar) ─
      GoRoute(
        path: '/warehouses/new',
        builder: (_, __) => const WarehouseFormScreen(),
      ),
      GoRoute(
        path: '/warehouses/:id/edit',
        builder: (_, state) => WarehouseFormScreen(
          warehouseId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/warehouses/:id/share',
        builder: (_, state) => ShareWarehouseScreen(
          warehouseId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/products/new',
        builder: (_, __) => const ProductFormScreen(),
      ),
      GoRoute(
        path: '/products/:id/edit',
        builder: (_, state) => ProductFormScreen(
          productId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/products/:warehouseProductId/detail',
        builder: (_, state) {
          final extra = state.extra as Map<String, int>?;
          return ProductDetailScreen(
            warehouseProductId:
                int.parse(state.pathParameters['warehouseProductId']!),
            warehouseId: extra?['warehouseId'] ?? 0,
          );
        },
      ),
      GoRoute(
        path: '/scanner',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return BarcodeScannerScreen(
            onScanned: extra?['onScanned'] as void Function(String)?,
          );
        },
      ),
      GoRoute(
        path: '/search',
        builder: (_, __) => const GlobalSearchScreen(),
      ),
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state, navigationShell) => _blockedShellPage(
          context: context,
          state: state,
          navigationShell: navigationShell,
        ),
        branches: [
          StatefulShellBranch(
            navigatorKey: _dashboardNavigatorKey,
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (_, __) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _warehousesNavigatorKey,
            routes: [
              GoRoute(
                path: '/warehouses',
                builder: (_, __) => const WarehouseListScreen(),
                routes: [
                  GoRoute(
                    path: ':id/detail',
                    builder: (_, state) => WarehouseDetailScreen(
                      warehouseId: int.parse(state.pathParameters['id']!),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _productsNavigatorKey,
            routes: [
              GoRoute(
                path: '/products',
                builder: (_, __) => const ProductListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _brandsNavigatorKey,
            routes: [
              GoRoute(
                path: '/brands',
                builder: (_, __) => const BrandListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _storesNavigatorKey,
            routes: [
              GoRoute(
                path: '/stores',
                builder: (_, __) => const StoreListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _stockHistoryNavigatorKey,
            routes: [
              GoRoute(
                path: '/stock-history',
                builder: (_, __) => const StockChangeHistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shoppingListNavigatorKey,
            routes: [
              GoRoute(
                path: '/shopping-list',
                builder: (_, __) => const ShoppingListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _settingsNavigatorKey,
            routes: [
              GoRoute(
                path: '/settings',
                builder: (_, __) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
