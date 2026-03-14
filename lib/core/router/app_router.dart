import 'package:flutter/material.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/auth/splash_screen.dart';
import '../../presentation/screens/auth/welcome_screen.dart';
import '../../presentation/screens/dashboard/critical_stock_screen.dart';
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

GlobalKey<NavigatorState> get rootNavigatorKey => _rootNavigatorKey;

const shellRootRoutes = {
  '/dashboard',
  '/warehouses',
  '/products',
  '/brands',
  '/stores',
  '/stock-history',
  '/shopping-list',
  '/settings',
};

enum ShellNavigationMode {
  preserveStack,
  resetFromDashboard,
  replaceAll,
}

String currentRouteName(BuildContext context) {
  return ModalRoute.of(context)?.settings.name ?? '';
}

void navigateToShellSection(
  BuildContext context,
  String route, {
  ShellNavigationMode mode = ShellNavigationMode.preserveStack,
}) {
  if (!shellRootRoutes.contains(route)) {
    if (mode == ShellNavigationMode.preserveStack) {
      context.push(route);
    } else {
      context.go(route);
    }
    return;
  }

  final current = currentRouteName(context);
  if (current == route) return;

  switch (mode) {
    case ShellNavigationMode.preserveStack:
      AppNavigator.instance.push(route);
      break;
    case ShellNavigationMode.resetFromDashboard:
      AppNavigator.instance.resetShellFlow(route);
      break;
    case ShellNavigationMode.replaceAll:
      AppNavigator.instance.replaceAll(route);
      break;
  }
}

void enterMainShell(BuildContext context, {String route = '/dashboard'}) {
  navigateToShellSection(
    context,
    route,
    mode: ShellNavigationMode.replaceAll,
  );
}

void enterAuthFlow(BuildContext context, {String route = '/login'}) {
  AppNavigator.instance.replaceAll(route);
}

void replaceWithAuthRoute(BuildContext context, String route) {
  AppNavigator.instance.replaceAll(route);
}

class AppNavigator {
  AppNavigator._();

  static final AppNavigator instance = AppNavigator._();

  NavigatorState? get _navigator => rootNavigatorKey.currentState;

  Future<T?> push<T extends Object?>(String route, {Object? extra}) {
    return _navigator!.pushNamed<T>(route, arguments: extra);
  }

  Future<T?> openAuxiliaryRoute<T extends Object?>(
    String route, {
    Object? extra,
  }) {
    return push<T>(route, extra: extra);
  }

  Future<T?> go<T extends Object?>(String route, {Object? extra}) {
    return replaceAll<T>(route, extra: extra);
  }

  Future<T?> replaceAll<T extends Object?>(String route, {Object? extra}) {
    return _navigator!.pushNamedAndRemoveUntil<T>(
      route,
      (currentRoute) => false,
      arguments: extra,
    );
  }

  void resetShellFlow(String route) {
    final navigator = _navigator!;
    navigator.pushNamedAndRemoveUntil('/dashboard', (route) => false);
    if (route != '/dashboard') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigator.pushNamed(route);
      });
    }
  }

  bool canPop() {
    return _navigator?.canPop() ?? false;
  }

  void pop<T extends Object?>([T? result]) {
    if (_navigator?.canPop() ?? false) {
      _navigator?.pop(result);
    }
  }
}

extension AppNavigationContext on BuildContext {
  Future<T?> push<T extends Object?>(String route, {Object? extra}) {
    return AppNavigator.instance.push<T>(route, extra: extra);
  }

  Future<T?> openAuxiliaryRoute<T extends Object?>(
    String route, {
    Object? extra,
  }) {
    return AppNavigator.instance.openAuxiliaryRoute<T>(route, extra: extra);
  }

  Future<T?> go<T extends Object?>(String route, {Object? extra}) {
    return AppNavigator.instance.go<T>(route, extra: extra);
  }

  void pop<T extends Object?>([T? result]) {
    AppNavigator.instance.pop<T>(result);
  }

  bool canPop() {
    return AppNavigator.instance.canPop();
  }
}

Route<dynamic> generateRoute(RouteSettings settings) {
  final route = settings.name ?? '/splash';
  final page = _buildPage(route, settings.arguments);

  return MaterialPageRoute<void>(
    settings: RouteSettings(name: route, arguments: settings.arguments),
    builder: (_) => page,
  );
}

Widget _buildPage(String route, Object? extra) {
  if (route == '/splash') return const SplashScreen();
  if (route == '/welcome') return const WelcomeScreen();
  if (route == '/login') return const LoginScreen();
  if (route == '/register') return const RegisterScreen();
  if (route == '/notifications') return const NotificationListScreen();
  if (route == '/warehouses/new') return const WarehouseFormScreen();
  if (route == '/products/new') return const ProductFormScreen();
  if (route == '/search') return const GlobalSearchScreen();
  if (route == '/critical-stock') return const CriticalStockScreen();
  if (route == '/dashboard') {
    return const AppShell(
      currentLocation: '/dashboard',
      child: DashboardScreen(),
    );
  }
  if (route == '/warehouses') {
    return const AppShell(
      currentLocation: '/warehouses',
      child: WarehouseListScreen(),
    );
  }
  if (route == '/products') {
    return const AppShell(
      currentLocation: '/products',
      child: ProductListScreen(),
    );
  }
  if (route == '/brands') {
    return const AppShell(
      currentLocation: '/brands',
      child: BrandListScreen(),
    );
  }
  if (route == '/stores') {
    return const AppShell(
      currentLocation: '/stores',
      child: StoreListScreen(),
    );
  }
  if (route == '/stock-history') {
    return const AppShell(
      currentLocation: '/stock-history',
      child: StockChangeHistoryScreen(),
    );
  }
  if (route == '/shopping-list') {
    return const AppShell(
      currentLocation: '/shopping-list',
      child: ShoppingListScreen(),
    );
  }
  if (route == '/settings') {
    return const AppShell(
      currentLocation: '/settings',
      child: SettingsScreen(),
    );
  }
  if (route == '/scanner') {
    final args = extra as Map<String, dynamic>?;
    return BarcodeScannerScreen(
      onScanned: args?['onScanned'] as void Function(String)?,
    );
  }

  final warehouseEditMatch =
      RegExp(r'^/warehouses/(\d+)/edit$').firstMatch(route);
  if (warehouseEditMatch != null) {
    return WarehouseFormScreen(
      warehouseId: int.parse(warehouseEditMatch.group(1)!),
    );
  }

  final warehouseShareMatch =
      RegExp(r'^/warehouses/(\d+)/share$').firstMatch(route);
  if (warehouseShareMatch != null) {
    return ShareWarehouseScreen(
      warehouseId: int.parse(warehouseShareMatch.group(1)!),
    );
  }

  final warehouseDetailMatch =
      RegExp(r'^/warehouses/(\d+)/detail$').firstMatch(route);
  if (warehouseDetailMatch != null) {
    return AppShell(
      currentLocation: route,
      child: WarehouseDetailScreen(
        warehouseId: int.parse(warehouseDetailMatch.group(1)!),
      ),
    );
  }

  final productEditMatch = RegExp(r'^/products/(\d+)/edit$').firstMatch(route);
  if (productEditMatch != null) {
    return ProductFormScreen(
      productId: int.parse(productEditMatch.group(1)!),
    );
  }

  final productDetailMatch =
      RegExp(r'^/products/(\d+)/detail$').firstMatch(route);
  if (productDetailMatch != null) {
    final args = extra as Map<String, int>?;
    return ProductDetailScreen(
      warehouseProductId: int.parse(productDetailMatch.group(1)!),
      warehouseId: args?['warehouseId'] ?? 0,
    );
  }

  return Scaffold(
    body: Center(
      child: Text('Ruta no encontrada: $route'),
    ),
  );
}
