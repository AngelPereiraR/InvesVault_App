import 'package:dio/dio.dart';
import '../models/warehouse_product_model.dart';
import '../../core/constants/api_constants.dart';
import '../../core/models/filter_params.dart';

class WarehouseProductRemoteDatasource {
  final Dio _dio;
  WarehouseProductRemoteDatasource(this._dio);

  Future<List<WarehouseProductModel>> getProducts(int warehouseId, [FilterParams params = FilterParams.empty]) async {
    try {
      final response = await _dio.get(
        ApiConstants.warehouseProductsList(warehouseId),
        queryParameters: params.toQueryParameters(),
      );
      return (response.data as List)
          .map((e) =>
              WarehouseProductModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      rethrow;
    }
  }

  Future<List<WarehouseProductModel>> getLowStock(int warehouseId) async {
    try {
      final response = await _dio
          .get(ApiConstants.warehouseProductsLowStock(warehouseId));
      return (response.data as List)
          .map((e) =>
              WarehouseProductModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      rethrow;
    }
  }

  Future<WarehouseProductModel> addProduct(
      Map<String, dynamic> data) async {
    final response =
        await _dio.post(ApiConstants.warehouseProducts, data: data);
    return WarehouseProductModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<WarehouseProductModel> updateProduct(
      int id, Map<String, dynamic> data) async {
    final response = await _dio
        .put(ApiConstants.warehouseProductById(id), data: data);
    return WarehouseProductModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<void> deleteProduct(int id) =>
      _dio.delete(ApiConstants.warehouseProductById(id));
}
