import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:dio/dio.dart';

import 'core/network/dio_client.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/auth_remote_datasource.dart';
import 'data/datasources/dashboard_remote_datasource.dart';
import 'data/datasources/brand_remote_datasource.dart';
import 'data/datasources/notification_remote_datasource.dart';
import 'data/datasources/product_remote_datasource.dart';
import 'data/datasources/shopping_list_remote_datasource.dart';
import 'data/datasources/stock_change_remote_datasource.dart';
import 'data/datasources/store_remote_datasource.dart';
import 'data/datasources/warehouse_product_remote_datasource.dart';
import 'data/datasources/warehouse_remote_datasource.dart';
import 'data/datasources/warehouse_user_remote_datasource.dart';
import 'data/datasources/batch_remote_datasource.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/brand_repository.dart';
import 'data/repositories/notification_repository.dart';
import 'data/repositories/product_repository.dart';
import 'data/repositories/shopping_list_repository.dart';
import 'data/repositories/stock_change_repository.dart';
import 'data/repositories/store_repository.dart';
import 'data/repositories/warehouse_product_repository.dart';
import 'data/repositories/warehouse_repository.dart';
import 'data/repositories/warehouse_user_repository.dart';
import 'data/repositories/dashboard_repository.dart';
import 'data/repositories/batch_repository.dart';
import 'presentation/cubits/auth/auth_cubit.dart';
import 'presentation/cubits/brand/brand_cubit.dart';
import 'presentation/cubits/dashboard/dashboard_cubit.dart';
import 'presentation/cubits/notification/notification_cubit.dart';
import 'presentation/cubits/product_detail/product_detail_cubit.dart';
import 'presentation/cubits/product_form/product_form_cubit.dart';
import 'presentation/cubits/product_list/product_list_cubit.dart';
import 'presentation/cubits/shopping_list/shopping_list_cubit.dart';
import 'presentation/cubits/stock_change/stock_change_cubit.dart';
import 'presentation/cubits/store/store_cubit.dart';
import 'presentation/cubits/warehouse/warehouse_cubit.dart';
import 'presentation/cubits/warehouse_detail/warehouse_detail_cubit.dart';
import 'presentation/cubits/warehouse_user/warehouse_user_cubit.dart';
import 'presentation/cubits/product_warehouses/product_warehouses_cubit.dart';
import 'presentation/cubits/batch/batch_cubit.dart';
import 'presentation/cubits/theme/theme_cubit.dart';

class InvesVaultApp extends StatefulWidget {
  final StorageService storageService;
  final NotificationService notificationService;

  const InvesVaultApp({
    super.key,
    required this.storageService,
    required this.notificationService,
  });

  @override
  State<InvesVaultApp> createState() => _InvesVaultAppState();
}

class _InvesVaultAppState extends State<InvesVaultApp> {
  late final Dio _dio;

  // Datasources
  late final AuthRemoteDatasource _authDs;
  late final WarehouseRemoteDatasource _warehouseDs;
  late final WarehouseUserRemoteDatasource _warehouseUserDs;
  late final ProductRemoteDatasource _productDs;
  late final WarehouseProductRemoteDatasource _warehouseProductDs;
  late final BrandRemoteDatasource _brandDs;
  late final StoreRemoteDatasource _storeDs;
  late final ShoppingListRemoteDatasource _shoppingListDs;
  late final NotificationRemoteDatasource _notificationDs;
  late final StockChangeRemoteDatasource _stockChangeDs;
  late final DashboardRemoteDatasource _dashboardDs;
  late final BatchRemoteDatasource _batchDs;

  // Repositories
  late final AuthRepository _authRepo;
  late final WarehouseRepository _warehouseRepo;
  late final WarehouseUserRepository _warehouseUserRepo;
  late final ProductRepository _productRepo;
  late final WarehouseProductRepository _warehouseProductRepo;
  late final BrandRepository _brandRepo;
  late final StoreRepository _storeRepo;
  late final ShoppingListRepository _shoppingListRepo;
  late final NotificationRepository _notificationRepo;
  late final StockChangeRepository _stockChangeRepo;
  late final DashboardRepository _dashboardRepo;
  late final BatchRepository _batchRepo;

  @override
  void initState() {
    super.initState();
    _dio = DioClient.getInstance(widget.storageService);

    final dio = _dio;

    _authDs = AuthRemoteDatasource(dio);
    _warehouseDs = WarehouseRemoteDatasource(dio);
    _warehouseUserDs = WarehouseUserRemoteDatasource(dio);
    _productDs = ProductRemoteDatasource(dio);
    _warehouseProductDs = WarehouseProductRemoteDatasource(dio);
    _brandDs = BrandRemoteDatasource(dio);
    _storeDs = StoreRemoteDatasource(dio);
    _shoppingListDs = ShoppingListRemoteDatasource(dio);
    _notificationDs = NotificationRemoteDatasource(dio);
    _stockChangeDs = StockChangeRemoteDatasource(dio);

    _authRepo = AuthRepository(_authDs);
    _warehouseRepo = WarehouseRepository(_warehouseDs);
    _warehouseUserRepo = WarehouseUserRepository(_warehouseUserDs);
    _productRepo = ProductRepository(_productDs);
    _warehouseProductRepo = WarehouseProductRepository(_warehouseProductDs);
    _brandRepo = BrandRepository(_brandDs);
    _storeRepo = StoreRepository(_storeDs);
    _shoppingListRepo = ShoppingListRepository(_shoppingListDs);
    _notificationRepo = NotificationRepository(_notificationDs);
    _stockChangeRepo = StockChangeRepository(_stockChangeDs);
    _dashboardDs = DashboardRemoteDatasource(dio);
    _dashboardRepo = DashboardRepository(_dashboardDs);
    _batchDs = BatchRemoteDatasource(dio);
    _batchRepo = BatchRepository(_batchDs);
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<BatchRepository>.value(
      value: _batchRepo,
      child: RepositoryProvider<WarehouseProductRepository>.value(
        value: _warehouseProductRepo,
        child: RepositoryProvider<WarehouseRepository>.value(
          value: _warehouseRepo,
          child: RepositoryProvider<ProductRepository>.value(
            value: _productRepo,
            child: MultiBlocProvider(
        providers: [
          BlocProvider(
            lazy: false,
            create: (_) => ThemeCubit(widget.storageService),
          ),
          BlocProvider(
            lazy: false,
            create: (_) => AuthCubit(_authRepo, widget.storageService),
          ),
          BlocProvider(
            create: (_) => WarehouseCubit(_warehouseRepo),
          ),
          BlocProvider(
            create: (_) => DashboardCubit(_dashboardRepo),
          ),
          BlocProvider(
            create: (_) => WarehouseDetailCubit(
              _warehouseRepo,
              _warehouseProductRepo,
              _stockChangeRepo,
              widget.notificationService,
              _warehouseUserRepo,
            ),
          ),
          BlocProvider(
            create: (_) => WarehouseUserCubit(_warehouseUserRepo),
          ),
          BlocProvider(
            create: (_) => ProductListCubit(_productRepo),
          ),
          BlocProvider(
            create: (_) => ProductFormCubit(_productRepo, _brandRepo, _storeRepo),
          ),
          BlocProvider(
            create: (_) => ProductDetailCubit(
              _warehouseProductRepo,
              _stockChangeRepo,
              widget.notificationService,
            ),
          ),
          BlocProvider(
            create: (_) => ProductWarehousesCubit(_warehouseProductRepo),
          ),
          BlocProvider(
            create: (_) => BrandCubit(_brandRepo),
          ),
          BlocProvider(
            create: (_) => StoreCubit(_storeRepo),
          ),
          BlocProvider(
            create: (_) => ShoppingListCubit(_shoppingListRepo),
          ),
          BlocProvider(
            create: (_) => NotificationCubit(_notificationRepo),
          ),
          BlocProvider(
            create: (_) => StockChangeCubit(_stockChangeRepo),
          ),
          BlocProvider(
            create: (_) => BatchCubit(_batchRepo),
          ),
        ],
          child: BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, themeState) {
              final themeMode = themeState is ThemeLoaded
                  ? themeState.themeMode
                  : ThemeMode.system;
              return MaterialApp(
                title: 'InvesVault',
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: themeMode,
                navigatorKey: rootNavigatorKey,
                initialRoute: '/splash',
                onGenerateRoute: generateRoute,
                debugShowCheckedModeBanner: false,
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [Locale('es')],
              );
            },
          ),
        ),
      ),
      ),
      ),
    );
  }
}
