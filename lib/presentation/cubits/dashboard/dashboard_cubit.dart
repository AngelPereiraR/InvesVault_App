import 'package:equatable/equatable.dart';
import '../../../core/utils/error_messages.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/warehouse_model.dart';
import '../../../data/models/warehouse_product_model.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../data/repositories/warehouse_product_repository.dart';
import '../../../data/repositories/warehouse_repository.dart';

part 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final WarehouseRepository _warehouseRepository;
  final WarehouseProductRepository _warehouseProductRepository;
  final NotificationRepository _notificationRepository;

  DashboardCubit(
    this._warehouseRepository,
    this._warehouseProductRepository,
    this._notificationRepository,
  ) : super(const DashboardInitial());

  Future<void> load() async {
    emit(const DashboardLoading());
    try {
      final warehouses = await _warehouseRepository.getWarehouses();

      final allLowStock = <WarehouseProductModel>[];
      int totalProducts = 0;

      for (final w in warehouses) {
        final products = await _warehouseProductRepository.getProducts(w.id);
        totalProducts += products.length;
        final lowStock =
            products.where((p) => p.isLowStock).toList();
        allLowStock.addAll(lowStock);
      }

      final notifications =
          await _notificationRepository.getNotifications();
      final unreadCount =
          notifications.where((n) => !n.isRead).length;

      emit(DashboardLoaded(
        warehouseCount: warehouses.length,
        productCount: totalProducts,
        lowStockCount: allLowStock.length,
        unreadNotifications: unreadCount,
        recentWarehouses: warehouses.take(5).toList(),
        lowStockItems: allLowStock.take(5).toList(),
      ));
    } catch (e) {
      emit(DashboardError(friendlyError(e)));
    }
  }

  Future<void> refresh() => load();
}
