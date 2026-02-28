import 'package:dio/dio.dart';
import '../models/warehouse_user_model.dart';
import '../../core/constants/api_constants.dart';

class WarehouseUserRemoteDatasource {
  final Dio _dio;
  WarehouseUserRemoteDatasource(this._dio);

  Future<List<WarehouseUserModel>> getUsers(int warehouseId) async {
    final response =
        await _dio.get(ApiConstants.warehouseUsers(warehouseId));
    return (response.data as List)
        .map((e) => WarehouseUserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<WarehouseUserModel> addUser(
      int warehouseId, int userId, String role) async {
    final response = await _dio.post(
      ApiConstants.warehouseUsers(warehouseId),
      data: {'user_id': userId, 'role': role},
    );
    return WarehouseUserModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<WarehouseUserModel> updateRole(
      int warehouseId, int userId, String role) async {
    final response = await _dio.put(
      ApiConstants.warehouseUser(warehouseId, userId),
      data: {'role': role},
    );
    return WarehouseUserModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<void> removeUser(int warehouseId, int userId) =>
      _dio.delete(ApiConstants.warehouseUser(warehouseId, userId));
}
