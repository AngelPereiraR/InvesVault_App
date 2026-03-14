import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../models/warehouse_model.dart';
import '../models/warehouse_product_model.dart';

class DashboardStats {
  final int warehouseCount;
  final int productCount;
  final int lowStockCount;
  final int unreadNotifications;
  final List<WarehouseModel> recentWarehouses;
  final List<WarehouseProductModel> lowStockItems;

  const DashboardStats({
    required this.warehouseCount,
    required this.productCount,
    required this.lowStockCount,
    required this.unreadNotifications,
    required this.recentWarehouses,
    required this.lowStockItems,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
        warehouseCount: json['warehouseCount'] as int,
        productCount: json['productCount'] as int,
        lowStockCount: json['lowStockCount'] as int,
        unreadNotifications: json['unreadNotifications'] as int,
        recentWarehouses: (json['recentWarehouses'] as List)
            .map((e) => WarehouseModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        lowStockItems: (json['lowStockItems'] as List)
            .map((e) => WarehouseProductModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class DashboardRemoteDatasource {
  final Dio _dio;
  DashboardRemoteDatasource(this._dio);

  Future<DashboardStats> getStats() async {
    final response = await _dio.get(ApiConstants.dashboard);
    return DashboardStats.fromJson(response.data as Map<String, dynamic>);
  }
}
