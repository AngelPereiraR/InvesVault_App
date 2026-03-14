import 'package:equatable/equatable.dart';
import '../../../core/utils/error_messages.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/warehouse_model.dart';
import '../../../data/models/warehouse_product_model.dart';
import '../../../data/repositories/dashboard_repository.dart';

part 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final DashboardRepository _repository;

  DashboardCubit(this._repository) : super(const DashboardInitial());

  Future<void> load() async {
    emit(const DashboardLoading());
    try {
      final stats = await _repository.getStats();
      emit(DashboardLoaded(
        warehouseCount: stats.warehouseCount,
        productCount: stats.productCount,
        lowStockCount: stats.lowStockCount,
        unreadNotifications: stats.unreadNotifications,
        recentWarehouses: stats.recentWarehouses,
        lowStockItems: stats.lowStockItems.take(5).toList(),
        allLowStockItems: stats.lowStockItems,
      ));
    } catch (e) {
      emit(DashboardError(friendlyError(e)));
    }
  }

  Future<void> refresh() => load();
}
