part of 'dashboard_cubit.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final int warehouseCount;
  final int productCount;
  final int lowStockCount;
  final int unreadNotifications;
  final List<WarehouseSummary> recentWarehouses;        // ordenados por productCount DESC
  final List<WarehouseProductModel> lowStockItems;      // Preview (max 5)
  final List<WarehouseProductModel> allLowStockItems;   // Full list

  const DashboardLoaded({
    required this.warehouseCount,
    required this.productCount,
    required this.lowStockCount,
    required this.unreadNotifications,
    required this.recentWarehouses,
    required this.lowStockItems,
    required this.allLowStockItems,
  });

  @override
  List<Object?> get props => [
        warehouseCount,
        productCount,
        lowStockCount,
        unreadNotifications,
        recentWarehouses,
        lowStockItems,
        allLowStockItems,
      ];
}

class DashboardError extends DashboardState {
  final String message;
  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
