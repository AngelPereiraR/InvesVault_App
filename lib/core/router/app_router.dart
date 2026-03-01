import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/cubits/auth/auth_cubit.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/auth/splash_screen.dart';
import '../../presentation/screens/auth/welcome_screen.dart';
import '../../presentation/screens/dashboard/dashboard_screen.dart';
import '../../presentation/screens/notifications/notification_list_screen.dart';
import '../../presentation/screens/products/barcode_scanner_screen.dart';
import '../../presentation/screens/products/product_detail_screen.dart';
import '../../presentation/screens/products/product_form_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/shell/app_shell.dart';
import '../../presentation/screens/shopping_list/shopping_list_screen.dart';
import '../../presentation/screens/stock_change/stock_change_history_screen.dart';
import '../../presentation/screens/warehouses/share_warehouse_screen.dart';
import '../../presentation/screens/warehouses/warehouse_detail_screen.dart';
import '../../presentation/screens/warehouses/warehouse_form_screen.dart';
import '../../presentation/screens/products/search_screen.dart';
import '../../presentation/screens/stores/store_list_screen.dart';
import '../../presentation/screens/warehouses/warehouse_list_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

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
      if (authState is AuthAuthenticated && isAuth) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (_, __) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
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
      // ── Shell routes (have AppBar + Drawer) ─────────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) =>
            AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const DashboardScreen(),
          ),

          // Warehouses
          GoRoute(
            path: '/warehouses',
            builder: (_, __) => const WarehouseListScreen(),
          ),
          GoRoute(
            path: '/warehouses/:id/detail',
            builder: (_, state) => WarehouseDetailScreen(
              warehouseId: int.parse(state.pathParameters['id']!),
            ),
          ),

          // Products
          GoRoute(
            path: '/products',
            builder: (_, __) => const WarehouseListScreen(),
          ),

          // Stores
          GoRoute(
            path: '/stores',
            builder: (_, __) => const StoreListScreen(),
          ),

          // Stock history
          GoRoute(
            path: '/stock-history',
            builder: (_, __) => const StockChangeHistoryScreen(),
          ),

          // Shopping list
          GoRoute(
            path: '/shopping-list',
            builder: (_, __) => const ShoppingListScreen(),
          ),

          // Settings
          GoRoute(
            path: '/settings',
            builder: (_, __) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
}
