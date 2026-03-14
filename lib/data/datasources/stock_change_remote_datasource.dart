import 'package:dio/dio.dart';
import '../models/stock_change_model.dart';
import '../../core/constants/api_constants.dart';
import '../../core/models/filter_params.dart';

class StockChangeRemoteDatasource {
  final Dio _dio;
  StockChangeRemoteDatasource(this._dio);

  Future<StockChangeModel> create(Map<String, dynamic> data) async {
    final response =
        await _dio.post(ApiConstants.stockChanges, data: data);
    return StockChangeModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<StockChangeModel>> getByProduct(int productId, [FilterParams params = FilterParams.empty]) async {
    final response = await _dio.get(
      ApiConstants.stockChangesByProduct(productId),
      queryParameters: params.toQueryParameters(),
    );
    return (response.data as List)
        .map((e) =>
            StockChangeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<StockChangeModel>> getByWarehouse(int warehouseId, [FilterParams params = FilterParams.empty]) async {
    final response = await _dio.get(
      ApiConstants.stockChangesByWarehouse(warehouseId),
      queryParameters: params.toQueryParameters(),
    );
    return (response.data as List)
        .map((e) =>
            StockChangeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<StockChangeModel>> getByUser(int userId, [FilterParams params = FilterParams.empty]) async {
    final response = await _dio.get(
      ApiConstants.stockChangesByUser(userId),
      queryParameters: params.toQueryParameters(),
    );
    return (response.data as List)
        .map((e) =>
            StockChangeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
