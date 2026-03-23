abstract class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api',
  );

  // APP API key: set at compile time with --dart-define=APP_API_KEY=your_key
  static const String appApiKey = String.fromEnvironment(
    'APP_API_KEY',
    defaultValue: '',
  );

  static const String envName = String.fromEnvironment(
    'ENV_NAME',
    defaultValue: 'development',
  );

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static String userById(int id) => '/auth/users/$id';
  static String userByEmail(String email) =>
      '/auth/users/search?email=${Uri.encodeComponent(email)}';

  // Warehouses
  static const String warehouses = '/warehouses';
  static String warehouseById(int id) => '/warehouses/$id';

  // Warehouse Users
  static String warehouseUsers(int warehouseId) =>
      '/warehouse-users/warehouses/$warehouseId/users';
  static String warehouseUser(int warehouseId, int userId) =>
      '/warehouse-users/warehouses/$warehouseId/users/$userId';

  // Products
  static const String products = '/products';
  static String productById(int id) => '/products/$id';

  // Warehouse Products
  static const String warehouseProducts = '/warehouse-products';
  static String warehouseProductById(int id) => '/warehouse-products/$id';
  static String warehouseProductsList(int warehouseId) =>
      '/warehouses/$warehouseId/products';
  static String warehouseProductsLowStock(int warehouseId) =>
      '/warehouses/$warehouseId/products/low-stock';
  static String productWarehouses(int id) => '/products/$id/warehouses';

  // Brands
  static const String brands = '/brands';
  static String brandById(int id) => '/brands/$id';

  // Stores
  static const String stores = '/stores';
  static String storeById(int id) => '/stores/$id';

  // Shopping List
  static const String shoppingListGenerateAll = '/shopping-list/generate/all';
  static String shoppingListGenerate(int warehouseId) =>
      '/shopping-list/generate/$warehouseId';
  static String shoppingList(int warehouseId) =>
      '/shopping-list/$warehouseId';
  static String shoppingListAdd(int warehouseId) =>
      '/shopping-list/add/$warehouseId';
  static String shoppingListUpdate(int id) => '/shopping-list/update/$id';
  static String shoppingListRemove(int id) => '/shopping-list/remove/$id';
  static String shoppingListClear(int warehouseId) =>
      '/shopping-list/clear/$warehouseId';
  static const String shoppingListAll = '/shopping-list/all/items';

  // Notifications
  static const String notifications = '/notifications';
  static String notificationMarkRead(int id) =>
      '/notifications/$id/mark-read';
  static const String notificationsMarkAllRead =
      '/notifications/mark-all-read';
  static String notificationDelete(int id) => '/notifications/$id';
  static const String notificationsClearAll = '/notifications/clear-all';

  // Dashboard
  static const String dashboard = '/dashboard';

  // Stock Changes
  static const String stockChanges = '/stock-changes';
  static String stockChangesByProduct(int productId) =>
      '/stock-changes/product/$productId';
  static String stockChangesByWarehouse(int warehouseId) =>
      '/stock-changes/warehouse/$warehouseId';
  static String stockChangesByUser(int userId) =>
      '/stock-changes/user/$userId';
}
