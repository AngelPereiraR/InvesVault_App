import 'package:dio/dio.dart';
import '../models/warehouse_model.dart';
import '../../core/constants/api_constants.dart';

class WarehouseRemoteDatasource {
  final Dio _dio;
  WarehouseRemoteDatasource(this._dio);

  Future<List<WarehouseModel>> getWarehouses() async {
    final response = await _dio.get(ApiConstants.warehouses);
    return (response.data as List)
        .map((e) => WarehouseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<WarehouseModel> getWarehouseById(int id) async {
    final response = await _dio.get(ApiConstants.warehouseById(id));
    return WarehouseModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<WarehouseModel> createWarehouse(
      {required String name, required int ownerId, bool isShared = false}) async {
    final response = await _dio.post(ApiConstants.warehouses, data: {
      'name': name,
      'owner_id': ownerId,
      'is_shared': isShared,
    });
    return WarehouseModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<WarehouseModel> updateWarehouse(
      int id, Map<String, dynamic> data) async {
    final response =
        await _dio.put(ApiConstants.warehouseById(id), data: data);
    return WarehouseModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteWarehouse(int id) =>
      _dio.delete(ApiConstants.warehouseById(id));
}
